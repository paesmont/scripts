package runner

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"

	"bashln-scripts/internal/scripts"
)

type EventType string

const (
	EventOutput EventType = "output"
	EventDone   EventType = "done"
)

type Event struct {
	Type   EventType
	Script scripts.Script
	Line   string
	Err    error
	Time   time.Time
}

const cancelGracePeriod = 1500 * time.Millisecond

// buildArgs returns the executable name, arguments, and optional environment
// for a script invocation. Shared by BuildCommand and BuildCommandWithContext.
func buildArgs(script scripts.Script, logPath string) (name string, args []string, env []string) {
	extraEnv := []string{"LOG_FILE=" + logPath}
	if len(script.SkipPackages) > 0 {
		extraEnv = append(extraEnv, "BASHLN_SKIP_PACKAGES="+strings.Join(script.SkipPackages, ","))
	}

	if script.RequiresRoot {
		preserve := "--preserve-env=LOG_FILE,BASHLN_SKIP_PACKAGES"
		args := []string{preserve}
		args = append(args, extraEnv...)
		args = append(args, "bash", script.Path)
		return "sudo", args, nil
	}
	return "bash", []string{script.Path}, append(os.Environ(), extraEnv...)
}

func BuildCommand(script scripts.Script, logPath string) (*exec.Cmd, error) {
	if err := validateScriptPath(script.Path); err != nil {
		return nil, err
	}

	name, args, env := buildArgs(script, logPath)
	cmd := exec.Command(name, args...)
	if env != nil {
		cmd.Env = env
	}
	ensureProcessGroup(cmd)
	return cmd, nil
}

func BuildCommandWithContext(ctx context.Context, script scripts.Script, logPath string) (*exec.Cmd, error) {
	if err := validateScriptPath(script.Path); err != nil {
		return nil, err
	}

	name, args, env := buildArgs(script, logPath)
	cmd := exec.CommandContext(ctx, name, args...)
	if env != nil {
		cmd.Env = env
	}
	ensureProcessGroup(cmd)
	cmd.WaitDelay = cancelGracePeriod
	cmd.Cancel = func() error {
		return terminateProcessGroup(cmd)
	}

	return cmd, nil
}

func StartStream(ctx context.Context, script scripts.Script, logPath string) <-chan Event {
	ch := make(chan Event, 64)

	go func() {
		defer close(ch)

		cmd, err := BuildCommandWithContext(ctx, script, logPath)
		if err != nil {
			ch <- Event{Type: EventDone, Script: script, Err: err, Time: time.Now()}
			return
		}

		stdout, err := cmd.StdoutPipe()
		if err != nil {
			ch <- Event{Type: EventDone, Script: script, Err: err, Time: time.Now()}
			return
		}

		stderr, err := cmd.StderrPipe()
		if err != nil {
			ch <- Event{Type: EventDone, Script: script, Err: err, Time: time.Now()}
			return
		}

		if err := cmd.Start(); err != nil {
			ch <- Event{Type: EventDone, Script: script, Err: err, Time: time.Now()}
			return
		}

		logFile, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
		if err != nil {
			ch <- Event{Type: EventOutput, Script: script, Line: fmt.Sprintf("[warn] falha ao abrir log: %v", err), Time: time.Now()}
		}
		if logFile != nil {
			defer func() {
				_ = logFile.Close()
			}()
		}

		var wg sync.WaitGroup
		scanErrs := make(chan error, 2)

		type outputLine struct {
			prefix string
			line   string
		}
		lines := make(chan outputLine, 128)

		scan := func(prefix string, stream io.Reader) {
			defer wg.Done()

			scanner := bufio.NewScanner(stream)
			scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)

			for scanner.Scan() {
				line := scanner.Text()
				lines <- outputLine{prefix: prefix, line: line}
			}

			if scanErr := scanner.Err(); scanErr != nil {
				scanErrs <- fmt.Errorf("scanner %s: %w", prefix, scanErr)
			}
		}

		wg.Add(2)
		go scan("stdout", stdout)
		go scan("stderr", stderr)

		go func() {
			wg.Wait()
			close(lines)
			close(scanErrs)
		}()

		for out := range lines {
			timeNow := time.Now()
			formatted := fmt.Sprintf("[%s] %s", out.prefix, out.line)
			ch <- Event{Type: EventOutput, Script: script, Line: formatted, Time: timeNow}

			if logFile != nil {
				_, _ = fmt.Fprintf(logFile, "%s [%s] [%s] %s\n", timeNow.Format("2006-01-02 15:04:05"), script.ID, out.prefix, out.line)
			}
		}

		var aggregateScanErr error
		for scanErr := range scanErrs {
			aggregateScanErr = errors.Join(aggregateScanErr, scanErr)
		}

		waitErr := cmd.Wait()

		if ctx.Err() != nil {
			waitErr = ctx.Err()
		} else if aggregateScanErr != nil {
			waitErr = errors.Join(waitErr, aggregateScanErr)
		}

		ch <- Event{Type: EventDone, Script: script, Err: waitErr, Time: time.Now()}
	}()

	return ch
}

func validateScriptPath(path string) error {
	if path == "" {
		return fmt.Errorf("path de script vazio")
	}

	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("erro resolvendo path do script: %w", err)
	}

	stat, err := os.Stat(absPath)
	if err != nil {
		return fmt.Errorf("script inacessivel: %w", err)
	}

	if stat.IsDir() {
		return fmt.Errorf("path do script aponta para diretorio: %s", absPath)
	}

	return nil
}

func ensureProcessGroup(cmd *exec.Cmd) {
	if cmd.SysProcAttr == nil {
		cmd.SysProcAttr = &syscall.SysProcAttr{}
	}
	cmd.SysProcAttr.Setpgid = true
}

func terminateProcessGroup(cmd *exec.Cmd) error {
	if cmd == nil || cmd.Process == nil {
		return nil
	}

	pid := cmd.Process.Pid
	if pid <= 0 {
		return nil
	}

	pgid := -pid
	termErr := syscall.Kill(pgid, syscall.SIGTERM)
	if termErr != nil && !errors.Is(termErr, syscall.ESRCH) {
		return termErr
	}

	time.Sleep(cancelGracePeriod)

	killErr := syscall.Kill(pgid, syscall.SIGKILL)
	if killErr != nil && !errors.Is(killErr, syscall.ESRCH) {
		if termErr == nil || errors.Is(termErr, syscall.ESRCH) {
			return killErr
		}
		return errors.Join(termErr, killErr)
	}

	if errors.Is(termErr, syscall.ESRCH) {
		return nil
	}

	return termErr
}

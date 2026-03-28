git clone --depth=1 https://github.com/rafaelmardojai/firefox-gnome-theme && cd firefox-gnome-theme
git checkout beta # Set beta branch 
git checkout v78.1 # Set v78.1 tag 
./scripts/auto-install.sh
./scripts/install.sh # Standard
./scripts/install.sh -f ~/.var/app/org.mozilla.firefox/.mozilla/firefox # Flatpak
./scripts/install.sh -t yaru


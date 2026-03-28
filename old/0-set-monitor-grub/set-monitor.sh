#!/bin/bash

# Variáveis fixas
GRUB_FILE="/etc/default/grub"
MONITOR_NAME="DP-1"
RESOLUTION="1440x900"
REFRESH_RATE="75"

# Backup do arquivo GRUB
sudo cp "$GRUB_FILE" "${GRUB_FILE}.bak"

# Adiciona ou substitui a opção video= (trata aspas simples e duplas)
if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=.*video=" "$GRUB_FILE"; then
	sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/s/video=[^ '\"\`]*/video=$MONITOR_NAME:$RESOLUTION@$REFRESH_RATE/" "$GRUB_FILE"
else
	sudo sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=['\"])(.*)(['\"])/\1\2 video=$MONITOR_NAME:$RESOLUTION@$REFRESH_RATE\3/" "$GRUB_FILE"
fi
echo -e "video=$MONITOR_NAME:$RESOLUTION@$REFRESH_RATE"
grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "$GRUB_FILE"
echo -e "\nArquivo GRUB atualizado com sucesso."

# Regerar a configuração do GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Reiniciar?
read -p "Deseja reiniciar agora? (s/n): " RESTART
if [[ "$RESTART" == "s" ]]; then
	sudo reboot
else
	echo "Reinicie manualmente para aplicar as alterações."
fi

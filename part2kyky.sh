arch-chroot /mnt << EOF
groupadd share
encrypted_esgi=$(openssl passwd -1 "esgi")
encrypted_father=$(openssl passwd -1 "azerty123")
encrypted_son=$(openssl passwd -1 "azerty1Z3")
useradd esgi -p "$encrypted_esgi" -s /bin/bash -m
useradd -d /home/father -m father -p "$encrypted_father" -G share -s /bin/bash
useradd -d /home/son -m son -p "$encrypted_son" -G share -s /bin/bash
EOF

mkdir -p /mnt/home/father/{Documents,Images,Musique,Vidéos}
mkdir -p /mnt/home/son/{Documents,Images,Musique,Vidéos}

arch-chroot /mnt << EOF
pacman -S i3-wm i3status dmenu --noconfirm
pacman -S --noconfirm lightdm lightdm-gtk-greeter
pacman -S --noconfirm alacritty thunar firefox
systemctl enable lightdm
EOF



chmod 755 /mnt/home/father
chmod 755 /mnt/home/son
chmod 770 /mnt/share
chmod 770 /mnt/home/father/share
chmod 770 /mnt/home/son/share

echo "Configuration terminée. Redémarrez pour démarrer i3."
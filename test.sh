



#Installation des logiciels de base (firefox, calculatrice, libreoffice, brave, vlc, discord, steam..)
arch-chroot /mnt << EOF
pacman -S --noconfirm firefox gnome-calculator libreoffice-still brave vlc discord steam
EOF

#Installation de hyprland pour le père
arch-chroot /mnt << EOF
pacman -S --noconfirm hyprland
EOF
#Création du dossier partagé
mkdir /mnt/share
chgrp share /mnt/share
chmod 770 /mnt/share

#Création des dossiers pour les users
mkdir /mnt/home/father/share
chown father:share /mnt/home/father/share
chmod 770 /mnt/home/father/share

mkdir /mnt/home/son/share
chown son:share /mnt/home/son/share
chmod 770 /mnt/home/son/share


#Installation de vi pour le fils 
arch-chroot /mnt << EOF
pacman -S --noconfirm vi
EOF

#Installation des logiciels de base (firefox, calculatrice, libreoffice, brave, vlc, discord, steam..)
arch-chroot /mnt << EOF
pacman -S --noconfirm firefox gnome-calculator libreoffice-still brave vlc discord steam
EOF

#Installation de hyprland pour le père
arch-chroot /mnt << EOF
pacman -S --noconfirm hyprland
EOF
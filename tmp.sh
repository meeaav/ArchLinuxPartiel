#!/bin/bash

#Installation des logiciels de base (firefox,libreoffice, brave, vlc, discord, steam..)
arch-chroot /mnt << EOF
pacman -S --noconfirm firefox libreoffice-still vlc discord
EOF

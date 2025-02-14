#!/bin/bash

#Installation des logiciels de base 
arch-chroot /mnt << EOF
pacman -S --noconfirm firefox vlc discord libreoffice libreoffice-l10n-fr openclipart*-libreoffice hyphen-fr libreoffice-help-fr mythes-fr fonts-crosextra-caladea
EOF

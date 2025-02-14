#!/bin/bash

#Installation de vi pour le fils 
arch-chroot /mnt << EOF
pacman -S --noconfirm vi
EOF
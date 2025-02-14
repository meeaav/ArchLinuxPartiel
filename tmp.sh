#!/bin/bash
arch-chroot /mnt << EOF
pacman -S --noconfirm virtualbox-guest-utils xf86-video-vmware open-vm-tools xf86-input-vmmouse xf86-input-vboxmouse xf86-input-vboxvideo xf86-video-vmware xf86-video-vboxvideo xf86-video-vesa 
EOF
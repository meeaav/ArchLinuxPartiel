#!/bin/bash
arch-chroot /mnt << EOF
pacman -S --noconfirm virtualbox-guest-utils xf86-video-vmware open-vm-tools
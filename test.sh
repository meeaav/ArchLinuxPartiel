#!/bin/bash

# Partitionnement
parted /dev/sda --script mklabel gpt
parted /dev/sda --script mkpart primary 1MiB 513MiB
parted /dev/sda --script set 1 esp on
parted /dev/sda --script mkpart primary 513MiB 100%

# Chiffrement avec LUKS
cryptsetup luksFormat /dev/sda2
cryptsetup open /dev/sda2 cryptlvm

# Configuration LVM
pvcreate /dev/mapper/cryptlvm
vgcreate vg0 /dev/mapper/cryptlvm
lvcreate -L 10G -n lv_encrypted vg0
lvcreate -L 20G -n lv_virtualbox vg0
lvcreate -L 5G -n lv_shared vg0
lvcreate -l 100%FREE -n lv_root vg0

# Formatage des partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/mapper/vg0-lv_root
mkfs.ext4 /dev/mapper/vg0-lv_encrypted
mkfs.ext4 /dev/mapper/vg0-lv_virtualbox
mkfs.ext4 /dev/mapper/vg0-lv_shared

# Montage des partitions
mount /dev/mapper/vg0-lv_root /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/mapper/vg0-lv_shared /mnt/home

# Installation de base
pacstrap /mnt base linux linux-firmware vim networkmanager

# Générer le fichier fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot dans le système installé
arch-chroot /mnt

# Configurer le système
echo "archlinux" > /etc/hostname
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf
systemctl enable NetworkManager

# Configurer le mot de passe root
echo "root:azerty123" | chpasswd

# Installer GRUB (bootloader)
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Quitter chroot et redémarrer
exit
umount -R /mnt
reboot

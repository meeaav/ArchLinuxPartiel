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

# Formatage des partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/mapper/vg0-lv_encrypted
mkfs.ext4 /dev/mapper/vg0-lv_virtualbox
mkfs.ext4 /dev/mapper/vg0-lv_shared

# Montage des partitions
mount /dev/mapper/vg0-lv_root /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Installation de base
pacstrap /mnt base linux linux-firmware

# Configuration système
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot /mnt hwclock --systohc
echo "fr_FR.UTF-8 UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=fr_FR.UTF-8" > /mnt/etc/locale.conf
echo "HOSTNAME" > /mnt/etc/hostname
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1 localhost" >> /mnt/etc/hosts
echo "127.0.1.1 HOSTNAME.localdomain HOSTNAME" >> /mnt/etc/hosts

# Configuration des utilisateurs
arch-chroot /mnt useradd -m -G wheel -s /bin/bash utilisateur
echo "utilisateur:azerty123" | arch-chroot /mnt chpasswd

# Installation des outils supplémentaires
arch-chroot /mnt pacman -S --noconfirm virtualbox hypriot

# Finalisation
umount -R /mnt
cryptsetup close cryptlvm

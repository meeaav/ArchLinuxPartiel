#!/bin/bash

# Fix de l'horloge système
timedatectl set-timezone Europe/Paris
loadkeys fr
pacman -Syu << EOF
y
EOF

# Créer une table de partition avec sfdisk, et ses partitions
sfdisk /dev/sda << EOF
, 500M, EF00
, 500M, 8300
, , 8300
EOF

# Formater les partitions
mkfs.vfat /dev/sda1  # /boot/efi (UEFI)
mkfs.ext4 /dev/sda2  # /boot (non chiffré)
mkfs.ext4 /dev/sda3  # Partition pour LUKS (chiffrée)

# Chiffrement LUKS sur /dev/sda3
password="esgi"
echo -e "$password\n$password" | cryptsetup luksFormat /dev/sda3
echo -e "$password" | cryptsetup open /dev/sda3 crypt

# Création des volumes logiques avec LVM
pvcreate /dev/mapper/crypt
vgcreate vg0 /dev/mapper/crypt

lvcreate -L 2G -n lv_swap vg0
lvcreate -L 15G -n lv_VM vg0
lvcreate -L 5G -n lv_tmp vg0
lvcreate -L 10G -n lv_home_father vg0
lvcreate -L 10G -n lv_home_son vg0
lvcreate -L 10G -n lv_fathersecret vg0
lvcreate -L 5G -n lv_share vg0
lvcreate -l 100%FREE -n lv_root vg0

# Formatage des partitions
mkfs.ext4 /dev/mapper/vg0-lv_root
mkfs.ext4 /dev/mapper/vg0-lv_home_father
mkfs.ext4 /dev/mapper/vg0-lv_home_son
mkfs.ext4 /dev/mapper/vg0-lv_fathersecret
mkfs.ext4 /dev/mapper/vg0-lv_tmp
mkfs.ext4 /dev/mapper/vg0-lv_VM
mkfs.ext4 /dev/mapper/vg0-lv_share
mkswap /dev/mapper/vg0-lv_swap

# Montage des partitions
mount /dev/mapper/vg0-lv_root /mnt
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot  # /boot non chiffré
mkdir /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi  # /boot/efi (UEFI)
mkdir /mnt/home
mkdir /mnt/home/father
mount /dev/mapper/vg0-lv_home_father /mnt/home/father
mkdir /mnt/home/son
mount /dev/mapper/vg0-lv_home_son /mnt/home/son
mkdir /mnt/tmp
mount /dev/mapper/vg0-lv_tmp /mnt/tmp
mkdir -p /mnt/var/VM
mount /dev/mapper/vg0-lv_VM /mnt/var/VM
mkdir /mnt/share
mount /dev/mapper/vg0-lv_share /mnt/share
swapon /dev/mapper/vg0-lv_swap

# Sync des miroirs
reflector --country France --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Installation de la base
pacstrap -K /mnt base linux linux-firmware lvm2 efibootmgr grub cryptsetup

# Génération de fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configuration de GRUB et initramfs
crypt2=$(blkid -s UUID -o value /dev/sda3)
arch-chroot /mnt << EOF
echo "dm_crypt" >> /etc/modules-load.d/dm_crypt.conf
echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$crypt2:crypt root=/dev/mapper/vg0-lv_root\"" >> /etc/default/grub
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /etc/default/grub
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF
#!/bin/bash

# Fix de l'horloge système
timedatectl set-timezone Europe/Paris
loadkeys fr
pacman -Syu << EOF
y
EOF

# Créer une table de partition avec sfdisk
sfdisk /dev/sda << EOF
1, 500M
;
EOF

# Chiffrement LUKS et LVM sur /dev/sda2
password="esgi"
echo -e "$password\n$password" | cryptsetup luksFormat /dev/sda2
echo -e "$password" | cryptsetup open /dev/sda2 crypt

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
mkfs.vfat /dev/sda1
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
mkdir -p /mnt/home/father
mount /dev/mapper/vg0-lv_home_father /mnt/home/father
mkdir -p /mnt/home/son
mount /dev/mapper/vg0-lv_home_son /mnt/home/son
mkdir -p /mnt/tmp
mount /dev/mapper/vg0-lv_tmp /mnt/tmp
mkdir -p /mnt/var/VM
mount /dev/mapper/vg0-lv_VM /mnt/var/VM
mkdir -p /mnt/share
mount /dev/mapper/vg0-lv_share /mnt/share
swapon /dev/mapper/vg0-lv_swap

# Monter /dev/sda1 sur /boot (en dehors de /mnt)
mkdir -p /boot
mount /dev/sda1 /boot

# Lier /boot à /mnt/boot avec un bind mount
mkdir -p /mnt/boot
mount --bind /boot /mnt/boot

# Synchronisation des miroirs
reflector --country France --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Installation de la base
pacstrap -K /mnt base linux linux-firmware lvm2

# Génération du fichier fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configuration de GRUB
crypt2=$(blkid -s UUID -o value /dev/sda2)
echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$crypt2:crypt root=/dev/mapper/vg0-lv_root\"" >> /mnt/etc/default/grub
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /mnt/etc/default/grub

# Ajouter les hooks encrypt et lvm2 dans /etc/mkinitcpio.conf
arch-chroot /mnt sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf

# Régénérer l'initramfs
arch-chroot /mnt mkinitcpio -P

# Installation de GRUB et configuration
arch-chroot /mnt << EOF
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF
arch-chroot /mnt << EOF
useradd -d /home/father -m father -p azerty1Z3 -G share -s /bin/bash
useradd -d /home/son -m son -p azerty1Z3 -G share -s /bin/bash
EOF

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

#Création des arboréscences pour les users
mkdir -p /mnt/home/father/{Documents,Images,Musique,Vidéos}
mkdir -p /mnt/home/son/{Documents,Images,Musique,Vidéos}

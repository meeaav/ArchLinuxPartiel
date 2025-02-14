#!/bin/bash

# Fix de l'horloge système
timedatectl set-timezone Europe/Paris
loadkeys fr

# Mise à jour du système
pacman -Syu --noconfirm

# Création de la table de partition avec sfdisk
# Partition 1 : EFI (500M)
# Partition 2 : /boot (500M)
# Partition 3 : LUKS (reste du disque)
sfdisk /dev/sda << EOF
, 500M, EF00
, 500M, 8300
;
EOF

# Formater les partitions
mkfs.vfat -F32 /dev/sda1  # Formater la partition EFI en vfat
mkfs.ext4 /dev/sda2       # Formater la partition /boot en ext4

# Chiffrement de la partition LVM avec LUKS
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
mount /dev/mapper/vg0-lv_root /mnt          # Monter / (racine)
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot                   # Monter /boot
mkdir /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi               # Monter /boot/efi (UEFI)

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

# Synchronisation des miroirs
reflector --country France --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Installation de la base
pacstrap /mnt base linux linux-firmware lvm2 efibootmgr grub cryptsetup

# Génération du fichier fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configuration du chroot
arch-chroot /mnt << EOF
echo "dm_crypt" >> /etc/modules-load.d/dm_crypt.conf

# Récupération de l'UUID de la partition chiffrée
crypt2=$(blkid -s UUID -o value /dev/sda3)
echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$crypt2:crypt root=/dev/mapper/vg0-lv_root\"" >> /etc/default/grub

# Configuration de mkinitcpio
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf

# Configuration de GRUB pour le boot chiffré
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /etc/default/grub

# Régénération de l'initramfs
mkinitcpio -P

# Installation de GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Définir un mot de passe root à "esgi"
echo -e "esgi\nesgi" | passwd
EOF

# Fin du script
echo "Installation terminée. Redémarrez le système avec 'reboot'."
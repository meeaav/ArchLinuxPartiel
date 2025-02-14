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
cryptsetup luksFormat /dev/sda2
cryptsetup open /dev/sda2 crypt
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

# Monter /dev/sda1 sur /mnt/boot/efi
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

# Synchronisation des miroirs
reflector --country France --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Installation de la base
pacstrap -K /mnt base linux linux-firmware

# Génération du fichier fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configuration du chiffrement dans mkinitcpio
arch-chroot /mnt << EOF
echo "dm_crypt" >> /etc/modules-load.d/dm_crypt.conf
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
EOF

# Configuration de GRUB
crypt2=$(blkid -s UUID -o value /dev/sda2)
echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$crypt2:crypt root=/dev/mapper/vg0-lv_root\"" >> /mnt/etc/default/grub
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /mnt/etc/default/grub

# Installation de GRUB et configuration
arch-chroot /mnt << EOF
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Installation de GNOME
#arch-chroot /mnt << EOF
#pacman -S --noconfirm gnome gnome-extra
#systemctl enable gdm
#EOF

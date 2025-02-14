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


#Création des users, avec leur home, et azerty1Z3 pour mdp, et le groupe pour dossier partagé
arch-chroot /mnt << EOF
groupadd share

# Générer des mots de passe chiffrés
encrypted_esgi=$(openssl passwd -1 "esgi")
encrypted_father=$(openssl passwd -1 "azerty123")
encrypted_son=$(openssl passwd -1 "azerty1Z3")

# Créer les utilisateurs avec des mots de passe chiffrés
useradd esgi -p "$encrypted_esgi" -s /bin/bash -m
useradd -d /home/father -m father -p "$encrypted_father" -G share -s /bin/bash
useradd -d /home/son -m son -p "$encrypted_son" -G share -s /bin/bash
EOF

#Création des arboréscences pour les users
mkdir -p /mnt/home/father/{Documents,Images,Musique,Vidéos}
mkdir -p /mnt/home/son/{Documents,Images,Musique,Vidéos}

#Création du dossier partagé
mkdir -p /mnt/share

# Définir le groupe propriétaire et les permissions
chgrp share /mnt/share
chmod 2770 /mnt/share  # 2 pour le sticky bit, 770 pour les permissions

# Création des liens symboliques dans les répertoires home des utilisateurs
mkdir -p /home/father /home/son
ln -sf /mnt/share /home/father/share
ln -sf /mnt/share /home/son/share

# Définir les propriétaires et les permissions pour les liens symboliques
chown father:share /home/father/share
chown son:share /home/son/share

#Installation de vi pour le fils 
arch-chroot /mnt << EOF
pacman -S --noconfirm vi
EOF

#Installation des logiciels de base 
arch-chroot /mnt << EOF

pacman -S --noconfirm firefox vlc discord libreoffice-still thunar
pacman -S --noconfirm virtualbox-guest-utils xf86-video-vmware open-vm-tools
pacman -S i3-wm i3status dmenu --noconfirm
EOF

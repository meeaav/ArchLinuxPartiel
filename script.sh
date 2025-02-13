#!/bin/bash

#Fix de l'horloge système
timedatectl set-timezone Europe/Paris

#Crééer une table de partition avec sfdisk, et ses partitions
sfdisk /dev/sda << EOF
1, 500M
;
EOF

#Coombo chiffrement LUKS et LVM sur /dev/sda2
read -s -p "Entrez le mot de passe LUKS : " password
echo -n "$password" | cryptsetup luksFormat /dev/sda2
echo -n "$password" | cryptsetup luksOpen /dev/sda2 crypt

#Création des volumes logiques avec LVM
pvcreate /dev/mapper/crypt
vgcreate vg0 /dev/mapper/crypt

lvcreate -L 2G -n lv_swap vg0
lvcreate -L 15G -n lv_VM vg0
lvcreate -L 5G -n lv_tmp vg0
lvcreate -L 10G -n lv_home_father vg0
lvcreate -L 10G -n lv_home_son vg0
lvcreate -L 5G -n lv_bin vg0
lvcreate -L 10G -n lv_fathersecret vg0
lvcreate -L 5G -n lv_share vg0
lvcreate -l 100%FREE -n lv_root vg0

#Formatage des partitions
mkfs.ext4 /dev/mapper/vg0-lv_root
mkfs.ext4 /dev/mapper/vg0-lv_home_father
mkfs.ext4 /dev/mapper/vg0-lv_home_son
mkfs.ext4 /dev/mapper/vg0-lv_bin
mkfs.ext4 /dev/mapper/vg0-lv_fathersecret
mkfs.ext4 /dev/mapper/vg0-lv_tmp
mkfs.ext4 /dev/mapper/vg0-lv_VM
mkfs.ext4 /dev/mapper/vg0-lv_share
mkswap /dev/mapper/vg0-lv_swap

#Montage des partitions
mount /dev/mapper/vg0-lv_root /mnt
mkdir /mnt/home
mkdir /mnt/home/father
mount /dev/mapper/vg0-lv_home_father /mnt/home/father
mkdir /mnt/home/son
mount /dev/mapper/vg0-lv_home_son /mnt/home/son
mkdir /mnt/bin
mount /dev/mapper/vg0-lv_bin /mnt/bin
#mkdir /mnt/fathersecret
#mount /dev/mapper/vg0-lv_fathersecret /mnt/fathersecret
mkdir /mnt/tmp
mount /dev/mapper/vg0-lv_tmp /mnt/tmp
mkdir -p /mnt/var/VM
mount /dev/mapper/vg0-lv_VM /mnt/var/VM
mkdir /mnt/share
mount /dev/mapper/vg0-lv_share /mnt/share
swapon /dev/mapper/vg0-lv_swap

#Création des répertoires
mkfs.ext4 /dev/sda1
# Monter /dev/sda1 sur /mnt/boot
if [ -d /mnt/boot ]; then
    echo "Le répertoire /mnt/boot existe déjà."
else
    mkdir /mnt/boot
fi
mount /dev/sda1 /mnt/boot
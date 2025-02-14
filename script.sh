#!/bin/bash

password="esgi"

# Démonter les partitions
umount /mnt/share
umount /mnt/var/VM
umount /mnt/tmp
umount /mnt/home/son
umount /mnt/home/father
umount /mnt/home
umount /mnt/boot/efi
umount /mnt

# Désactiver le swap
swapoff /dev/mapper/vg0-lv_swap

# Désactiver les volumes logiques LVM
lvchange -an /dev/vg0/lv_root
lvchange -an /dev/vg0/lv_home_father
lvchange -an /dev/vg0/lv_home_son
lvchange -an /dev/vg0/lv_fathersecret
lvchange -an /dev/vg0/lv_tmp
lvchange -an /dev/vg0/lv_VM
lvchange -an /dev/vg0/lv_share
lvchange -an /dev/vg0/lv_swap

# Désactiver le groupe de volumes LVM
vgchange -an vg0

# Fermer le conteneur LUKS
cryptsetup luksClose crypt

# Vérifier le mot de passe LUKS
echo -e "$password" | cryptsetup luksOpen /dev/sda2 crypt

if [ $? -eq 0 ]; then
    echo "Le mot de passe LUKS fonctionne correctement."
    cryptsetup status crypt
else
    echo "Le mot de passe LUKS est incorrect."
fi
#!/bin/bash

# Créer un fichier results.txt pour stocker les résultats
echo "###### Results lsblk -f ########" >> results.txt
lsblk -f >> results.txt

echo "###### Results cat /etc/passwd /etc/group /etc/fstab /etc/mtab ########" >> results.txt
cat /etc/passwd >> results.txt
cat /etc/group >> results.txt
cat /etc/fstab >> results.txt
cat /etc/mtab >> results.txt

echo "###### Results echo \$HOSTNAME ########" >> results.txt
echo $HOSTNAME >> results.txt

echo "###### Results grep -i installed /var/log/pacman.log ########" >> results.txt
grep -i installed /var/log/pacman.log >> results.txt

echo "######## Modified files ########" >> results.txt
echo "######## /etc/pacman.d/mirrorlist ########" >> results.txt
cat /etc/pacman.d/mirrorlist >> results.txt

echo "######## /etc/modules-load.d/dm_crypt.conf ########" >> results.txt
cat /etc/modules-load.d/dm_crypt.conf >> results.txt

echo "######## /mnt/etc/default/grub ########" >> results.txt
cat /mnt/etc/default/grub >> results.txt

echo "######## /etc/mkinitcpio.conf ########" >> results.txt
cat /etc/mkinitcpio.conf >> results.txt

echo "######## /boot/grub/grub.cfg ########" >> results.txt
cat /boot/grub/grub.cfg >> results.txt
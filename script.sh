#!/bin/bash

#Fix de l'horloge système
timedatectl set-timezone Europe/Paris

#Crééer une table de partition avec sfdisk, et ses partitions
sfdisk /dev/sda << EOF
1, 500M
;
EOF

#Chiffrer avec LVM le disque
pvcreate /dev/sda2
vgcreate vg0 /dev/sda2

lvcreate -L 2G -n lv_swap vg0
lvcreate -L 20G -n lv_VM vg0
lvcreate -L 5G -n lv_tmp vg0
lvcreate -L 10G -n lv_home_father vg0
lvcreate -L 10G -n lv_home_son vg0
lvcreate -L 5G -n lv_bin vg0
lvcreate -L 10G -n lv_fathersecret vg0
lvcreate -l 100%FREE -n lv_root vg0

#!/bin/bash

#Fix de l'horloge système
timedatectl set-timezone Europe/Paris

#Crééer une table de partition avec sfdisk, et ses partitions
sfdisk /dev/sda << EOF
1, 512M, 
2, 10G,
;
EOF

#Chiffrer avec LVM la partition
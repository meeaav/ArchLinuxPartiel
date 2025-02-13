#!/bin/bash

#Fix de l'horloge système
timedatectl set-timezone Europe/Paris

#Crééer une table de partition avec sfdisk
sfdisk /dev/sda << EOF
1, 512M, 
;
EOF
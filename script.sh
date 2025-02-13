#!/bin/bash

#Fix de l'horloge système
timedatectl set-timezone Europe/Paris

#Crééer une table de partition avec sfdisk
sfdisk /dev/sda << EOF
0, 512M, 
, 512M
;
;
EOF
#!/bin/bash

# Création du dossier partagé
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
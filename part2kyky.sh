#Création des users, avec leur home, et azerty1Z3 pour mdp, et le groupe pour dossier partagé
arch-chroot /mnt << EOF
groupadd share
useradd -d /home/father -m father -p azerty1Z3 -G share -s /bin/bash
useradd -d /home/son -m son -p azerty1Z3 -G share -s /bin/bash
EOF

#Création du dossier partagé
mkdir /mnt/share
chgrp share /mnt/share
chmod 770 /mnt/share

#Création des dossiers pour les users
mkdir /mnt/home/father/share
chown father:share /mnt/home/father/share
chmod 770 /mnt/home/father/share

mkdir /mnt/home/son/share
chown son:share /mnt/home/son/share
chmod 770 /mnt/home/son/share

#Création des arboréscences pour les users
mkdir -p /mnt/home/father/{Documents,Images,Musique,Vidéos}
mkdir -p /mnt/home/son/{Documents,Images,Musique,Vidéos}

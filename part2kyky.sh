#Création des users, avec leur home, et azerty1Z3 pour mdp, et le groupe pour dossier partagé
arch-chroot /mnt << EOF
passwd << EOF
azerty1Z3
azerty1Z3
EOF
pacman -S hyprland --noconfirm
pacman -S gnome --noconfirm
systemctl start gdm.service
systemctl enable gdm.service
EOF
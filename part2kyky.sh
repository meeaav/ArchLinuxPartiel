#Création des users, avec leur home, et azerty1Z3 pour mdp, et le groupe pour dossier partagé
arch-chroot /mnt << EOF
passwd << EOF
esgi
esgi
EOF

#Création des users, avec leur home, et azerty1Z3 pour mdp, et le groupe pour dossier partagé
arch-chroot /mnt << EOF
groupadd share

# Générer des mots de passe chiffrés
encrypted_esgi=$(openssl passwd -1 "esgi")
encrypted_father=$(openssl passwd -1 "azerty123")
encrypted_son=$(openssl passwd -1 "azerty1Z3")

# Créer les utilisateurs avec des mots de passe chiffrés
useradd esgi -p "$encrypted_esgi" -s /bin/bash -m
useradd -d /home/father -m father -p "$encrypted_father" -G share -s /bin/bash
useradd -d /home/son -m son -p "$encrypted_son" -G share -s /bin/bash
EOF

#Création des arboréscences pour les users
mkdir -p /mnt/home/father/{Documents,Images,Musique,Vidéos}
mkdir -p /mnt/home/son/{Documents,Images,Musique,Vidéos}

arch-chroot /mnt << EOF
pacman -S hyprland --noconfirm
pacman -S --noconfirm sddm alacritty thunar firefox
systemctl enable sddm
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/hyprland.conf << EOF
[Autologin]
Session=hyprland.desktop
User=father
mkdir -p /etc/hypr
cat > /etc/hypr/hyprland.conf << EOF
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = waybar
exec-once = nm-applet --indicator
exec-once = swaybg -i /usr/share/backgrounds/archlinux/arch-wallpaper.jpg

monitor=,preferred,auto,1

input {
    kb_layout = fr
    follow_mouse = 1
    sensitivity = 0
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
}

decoration {
    rounding = 10
    blur = yes
    blur_size = 3
    blur_passes = 1
}

animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

gestures {
    workspace_swipe = off
}

misc {
    disable_hyprland_logo = true
}
EOF
EOF
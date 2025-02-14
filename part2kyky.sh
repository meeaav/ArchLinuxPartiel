arch-chroot /mnt << EOF
groupadd share
encrypted_esgi=$(openssl passwd -1 "esgi")
encrypted_father=$(openssl passwd -1 "azerty123")
encrypted_son=$(openssl passwd -1 "azerty1Z3")
useradd esgi -p "$encrypted_esgi" -s /bin/bash -m
useradd -d /home/father -m father -p "$encrypted_father" -G share -s /bin/bash
useradd -d /home/son -m son -p "$encrypted_son" -G share -s /bin/bash
EOF

mkdir -p /mnt/home/father/{Documents,Images,Musique,Vidéos}
mkdir -p /mnt/home/son/{Documents,Images,Musique,Vidéos}

arch-chroot /mnt << EOF
pacman -S i3-wm i3status dmenu --noconfirm
pacman -S --noconfirm lightdm lightdm-gtk-greeter
pacman -S --noconfirm alacritty thunar firefox
systemctl enable lightdm
EOF

arch-chroot /mnt << EOF
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/i3.conf << EOL
[Seat:*]
session-wrapper=/etc/lightdm/Xsession
greeter-session=lightdm-gtk-greeter
user-session=i3
EOL
EOF

arch-chroot /mnt << EOF
mkdir -p /etc/i3
cat > /etc/i3/config << EOL
font pango:monospace 10
set \$mod Mod4
exec --no-startup-id nm-applet
exec --no-startup-id pasystray
exec --no-startup-id feh --bg-scale /usr/share/backgrounds/archlinux/arch-wallpaper.jpg
bar {
    status_command i3status
    font pango:monospace 10
}
bindsym \$mod+Return exec alacritty
bindsym \$mod+d exec dmenu_run
bindsym \$mod+Shift+q kill
bindsym \$mod+h split h
bindsym \$mod+v split v
bindsym \$mod+f fullscreen toggle
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+r restart
bindsym \$mod+Shift+e exec "i3-nagbar -t warning -m 'Voulez-vous vraiment quitter i3 ?' -b 'Oui' 'i3-msg exit'"
EOL
EOF

chmod 755 /mnt/home/father
chmod 755 /mnt/home/son
chmod 770 /mnt/share
chmod 770 /mnt/home/father/share
chmod 770 /mnt/home/son/share

echo "Configuration terminée. Redémarrez pour démarrer i3."
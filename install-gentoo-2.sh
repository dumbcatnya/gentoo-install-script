#!bin/sh
echo "Type new username:"
read username
useradd -m -G users,wheel,audio -s /bin/bash $username
passwd $username

emerge app-portage/gentoolkit
rc-update add elogind boot
rc-update add udev sysinit
rc-update add dbus default
emerge udisks
usermod -a -G plugdev root
usermod -a -G plugdev $username
rc-update add lvm boot

#kde install
echo "VIDEO_CARDS=amdgpu" >> /etc/portage/make.conf
emerge x11-base/xorg-drivers

gpasswd -a root video
gpasswd -a $username video
emerge kde-plasma/plasma-meta
echo "Press u"
dispatch-conf
emerge kde-plasma/plasma-meta
emerge kde-plasma/powerdevil
emerge kde-plasma/systemsettings
emerge kde-plasma/kdeplasma-addons

emerge app-admin/sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers.tmp
usermod -a -G video sddm

echo "[X11]" > /etc/sddm.conf
echo "DisplayCommand=/etc/sddm/scripts/Xsetup" >> /etc/sddm.conf
mkdir -p /etc/sddm/scripts
touch /etc/sddm/scripts/Xsetup
echo "setxkbmap us" > /etc/sddm/scripts/Xsetup
chmod a+x /etc/sddm/scripts/Xsetup
echo "CHECKVT=7" > /etc/conf.d/display-manager
echo 'DISPLAYMANAGER="sddm"' >> /etc/conf.d/display-manager
rc-update add display-manager default
rc-service display-manager start

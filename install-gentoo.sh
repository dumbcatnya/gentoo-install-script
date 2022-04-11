#!bin/sh
echo "Type hostname:"
read hostname
#creating partitions
lsblk
echo "Pick disk for gentoo install"
read diskname
echo "Format your disk"
cfdisk /dev/$diskname

echo "Select root partition"
read rootpartition
mkfs.ext4 /dev/$rootpartition

echo "Select boot partition"
read bootpartition
mkfs.fat -F 32 /dev/$bootpartition

echo "Select swap partition"
read swappartition
mkswap /dev/$swappartition

mkdir /mnt/gentoo
mount /dev/$rootpartition /mnt/gentoo
mkdir -p /mnt/gentoo/boot/efi
mount /dev/$bootpartition /mnt/gentoo/boot/efi
swapon /dev/$swappartition

ntpd -q -g

cd /mnt/gentoo
wget https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20220410T170533Z/stage3-amd64-openrc-20220410T170533Z.tar.xz
tar xpvf stage3-amd64-openrc-20220410T170533Z.tar.xz --xattrs-include='*.*' --numeric-owner

rm stage3-amd64-openrc-20220410T170533Z.tar.xz
echo "Select amount of cores for compilation"
read corenum
echo MAKEOPTS='-j'$corenum >> /mnt/gentoo/etc/portage/make.conf
mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/


#mounting filesystems
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm
chmod 1777 /dev/shm /run/shm

#entering chroot
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

mount /dev/sda1 /boot

eselect profile set 8

echo 'ACCEPT_LICENSE="*"' >> /etc/portage/make.conf
echo 'USE="X -pam -systemd -qtwebengine -webengine gtk -gnome qt5 kde ' >> /etc/portage/make.conf

emerge-webrsync
emerge --quiet --update --deep --newuse @world

echo "Europe/Brussels" > /etc/timezone
emerge --config sys-libs/timezone-data

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "C.UTF8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale list
echo "Set locale"
var locale
eselect locale set $locale

#reload environment
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

#install and configure kernel
emerge sys-kernel/gentoo-sources
emerge sys-apps/pciutils
emerge sys-kernel/genkernel

echo /dev/$bootpartition	/boot	vfat	defaults	0 2 >> /etc/fstab
genkernel all

echo /dev/$swappartition	none	swap	sw	0 0 >> /etc/fstab
echo /dev/$rootpartition	/	ext4	noatime	0 1 >> /etc/fstab

#set hostname
echo hostname='"'$hostname'"' >> /etc/conf.d/hostname

#wifi config
emerge --noreplace net-misc/netifrc

ifconfig
echo "Type network name:"
read network
echo config_$network='"'dhcp'"' >> /etc/conf.d/net


cd /etc/init.d
ln -s net.lo net.$network
rc-update add net.$network default

echo 127.0.0.1	$hostname localhost > /etc/hosts
echo ::1	localhost >> /etc/hosts

echo "Set password"
passwd

#tools
emerge app-admin/sysklogd
rc-update add sysklogd default
emerge sys-fs/e2fsprogs
emerge sys-fs/dosfstools
emerge net-misc/dhcpcd
emerge net-wireless/iw net-wireless/wpa_supplicant

#install grub bootloader
echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
emerge --verbose sys-boot/grub:2
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
emerge sys-boot/os-prober
grub-mkconfig -o /boot/grub/grub.cfg

emerge net-misc/wget
cd ~
wget https://raw.githubusercontent.com/rushia272/gentoo-install-script/main/install-gentoo-2.sh

echo  Now reboot into gentoo
echo After reboot open "install-gentoo-2.sh"
read -n 1 -r -s -p $'Press enter to continue...\n'
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot


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
export bootpartition

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
wget https://raw.githubusercontent.com/rushia272/gentoo-install-script/main/run-in-chroot.sh
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
chroot /mnt/gentoo /bin/bash run-in-chroot.sh
#end of script






























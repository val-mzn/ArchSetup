reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

parted --script /dev/sda -- mklabel gpt \
  mkpart ESP fat32 0Mib 512Mib \
  set 1 boot on \
  mkpart primary linux-swap 512Mib 4608Mib \
  mkpart primary ext4 4608Mib 100%

mkfs.vfat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3

mount /dev/sda3 /mnt
pacstrap /mnt base base-devel openssh linux linux-firmware neovim
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

sed -e '/en_US.UTF-8/s/^#*//g' -i /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf
echo KEYMAP=us > /etc/vconsole.conf
echo kappa > /mnt/etc/hostname
echo 127.0.0.1    localhost.localdomain   localhost >> /mnt/etc/hosts
echo ::1          localhost.localdomain   localhost >> /mnt/etc/hosts
echo 127.0.0.1    thinkpad.localdomain    kappa >> /mnt/etc/hosts

ln -sf /mnt/usr/share/zoneinfo/Europe/Paris /mnt/etc/localtime
hwclock --systohc

passwd
useradd -m -g users -G wheel,storage,power,audio val_mzn
passwd val_mzn
sed -i '/NOPASSWD/!s/# %wheel/%wheel/g' /etc/sudoers

pacman -S dhcpcd networkmanager network-manager-applet
systemctl enable sshd dhcpcd NetworkManager

mount /dev/sda1 /boot
pacman -S grub-efi-x86_64 efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch
grub-mkconfig -o /boot/grub/grub.cfg

exit
umount -R /mnt
swapoff /dev/sda2
reboot

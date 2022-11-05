reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

parted --script /dev/sda -- mklabel gpt \
  mkpart ESP fat32 1Mib 513Mib \
  set 1 boot on \
  mkpart primary linux-swap 513Mib 4609Mib \
  mkpart primary ext4 4609Mib 100%

mkfs.vfat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3

mount /dev/sda3 /mnt
pacstrap /mnt base base-devel openssh linux linux-firmware neovim
genfstab -U /mnt >> /mnt/etc/fstab


arch-chroot /mnt /bin/bash -e <<EOF

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
systemctl enable sshd dhcpcd NetworkManager fstrim.timer

# BOOT GRUB STUFF
mount /dev/sda1 /boot
pacman -S grub-efi-x86_64 efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S iw wpa_supplicant dialog intel-ucode git reflector lshw unzip htop
pacman -S wget pulseaudio alsa-utils alsa-plugins pavucontrol xdg-user-dirs

su - val_mzn
xdg-user-dirs-update
mkdir Sources
cd Sources
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

yay -S pa-applet-git

sudo pacman -S xorg-server xorg-apps xorg-xinit
sudo pacman -S i3-gaps i3blocks i3lock numlockx
sudo pacman -S lightdm lightdm-gtk-greeter --needed
sudo systemctl enable lightdm

sudo pacman -S noto-fonts ttf-ubuntu-font-family ttf-dejavu ttf-freefont
sudo pacman -S ttf-liberation ttf-droid ttf-roboto terminus-font
sudo pacman -S rxvt-unicode ranger rofi dmenu --needed

sudo pacman -S firefox --needed
sudo pacman -S zsh
sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
sudo pacman -S lxappearance, arc-gtk-theme, papirus-icon-theme

echo [greeter] >> /etc/lightdm/lightdm-gtk-greeter.conf
echo theme-name = Arc-Dark >> /etc/lightdm/lightdm-gtk-greeter.conf
echo icon-theme-name = Papirus-Dark >> /etc/lightdm/lightdm-gtk-greeter.conf
echo 'background = #2f343f' >> /etc/lightdm/lightdm-gtk-greeter.conf

EOF
umount -R /mnt
swapoff /dev/sda2
reboot

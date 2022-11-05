pacman -Syyu
pacman -S reflector
preflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

parted --script /dev/sda -- mklabel gpt \
  mkpart ESP fat32 0Mib 512Mib \
  set 1 boot on \
  mkpart primary linux-swap 512Mib 4608Mib \
  mkpart primary ext4 4608Mib 100%

mkfs.vfat -F32 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3
swapon /dev/sda2

mount /dev/sda3 /mnt
mkdir /mnt/{boot,home}
mount /dev/sda1 /mnt/boot

timedatectl set-ntp true
pacstrap /mnt base base-devel openssh linux linux-firmware neovim
genfstab -U /mnt >> /mnt/etc/fstab

sed -e '/en_US.UTF-8/s/^#*//g' -i /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo LANG=en_US.UTF-8 >> /mnt/etc/locale.conf
echo kappa > /mnt/etc/hostname
echo 127.0.0.1    localhost.localdomain   localhost > /mnt/etc/hosts
echo ::1          localhost.localdomain   localhost > /mnt/etc/hosts
echo 127.0.0.1    thinkpad.localdomain    kappa > /mnt/etc/hosts

ln -sf /mnt/usr/share/zoneinfo/Europe/Paris /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc

arch-chroot /mnt pacman -S dhcpcd networkmanager network-manager-applet
arch-chroot /mnt systemctl enable sshd
arch-chroot /mnt systemctl enable dhcpcd
arch-chroot /mnt ystemctl enable NetworkManager
arch-chroot /mnt pacman -S grub-efi-x86_64 efibootmgr
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt pacman -S iw wpa_supplicant dialog intel-ucode git reflector lshw unzip htop
arch-chroot /mnt pacman -S wget pulseaudio alsa-utils alsa-plugins pavucontrol xdg-user-dirs

arch-chroot /mnt passwd
arch-chroot /mnt useradd -m -g users -G wheel,storage,power,audio val_mzn
arch-chroot /mnt passwd val_mzn

arch-chroot /mnt echo 'val_mzn ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo


umount -R /mnt
swapoff /dev/sda2
reboot





su - val_mzn
xdg-user-dirs-update

mkdir Sources
cd Sources
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

yay -S pa-applet-git
sudo pacman -S bluez bluez-utils blueman
sudo systemctl enable bluetooth
sudo pacman -S tlp tlp-rdw powertop acpi
sudo systemctl enable tlp
sudo systemctl enable tlp-sleep
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket
sudo systemctl enable fstrim.timer

sudo pacman -S xorg-server xorg-apps xorg-xinit
sudo pacman -S i3-gaps i3blocks i3lock numlockx

sudo pacman -S lightdm lightdm-gtk-greeter --needed
sudo systemctl enable lightdm

sudo pacman -S noto-fonts ttf-ubuntu-font-family ttf-dejavu ttf-freefont
sudo pacman -S ttf-liberation ttf-droid ttf-roboto terminus-font

sudo pacman -S rxvt-unicode ranger rofi dmenu --needed
sudo pacman -S firefox --needed
sudo reboot
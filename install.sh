hostname=$(dialog --stdout --inputbox "Enter hostname" 0 0) || exit 1
clear
: ${hostname:?"hostname cannot be empty"}

user=$(dialog --stdout --inputbox "Enter admin username" 0 0) || exit 1
clear
: ${user:?"user cannot be empty"}

password=$(dialog --stdout --passwordbox "Enter admin password" 0 0) || exit 1
clear
: ${password:?"password cannot be empty"}
password2=$(dialog --stdout --passwordbox "Enter admin password again" 0 0) || exit 1
clear
[[ "$password" == "$password2" ]] || ( echo "Passwords did not match"; exit 1; )

devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1
clear

swap_size=$(free --mebi | awk '/Mem:/ {print $2}')
swap_end=$(( $swap_size + 513 ))MiB

parted --script "${device}" -- mklabel gpt \
  mkpart ESP fat32 1Mib 513MiB \
  set 1 boot on \
  mkpart primary linux-swap 513MiB ${swap_end} \
  mkpart primary ext4 ${swap_end} 100%

part_boot="$(ls ${device}* | grep -E "^${device}p?1$")"
part_swap="$(ls ${device}* | grep -E "^${device}p?2$")"
part_root="$(ls ${device}* | grep -E "^${device}p?3$")"

wipefs "${part_boot}"
wipefs "${part_swap}"
wipefs "${part_root}"

mkfs.vfat -F32 "${part_boot}"
mkswap "${part_swap}"
mkfs.ext4 -f "${part_root}"
read -p "WAIT"

swapon "${part_swap}"
mount "${part_root}" /mnt
mkdir /mnt/boot
mount "${part_boot}" /mnt/boot

pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
read -p "WAIT"
clear

{
	ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
	hwclock --systohc
	
	sed -e '/en_US.UTF-8/s/^#*//g' -i /etc/locale.gen
	locale-gen

	echo LANG=en_US.UTF-8 > /etc/locale.conf
	echo KEYMAP=us > /etc/vconsole.conf
	echo ${hostname} > /etc/hostname
	echo 127.0.0.1    localhost.localdomain   localhost >> /etc/hosts
	echo ::1          localhost.localdomain   localhost >> /etc/hosts
	echo 127.0.0.1    thinkpad.localdomain    ${hostname} >> /etc/hosts

	echo ${password} | passwd
	useradd -m -g users -G wheel,storage,power,audio val_mzn
	echo ${password} | passwd val_mzn
	xdg-user-dirs-update
	sed -i '/NOPASSWD/!s/# %wheel/%wheel/g' /etc/sudoers

	pacman -S dhcpcd networkmanager network-manager-applet
	systemctl enable sshd dhcpcd NetworkManager fstrim.timer

	pacman -S grub-efi-x86_64 efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch
	grub-mkconfig -o /boot/grub/grub.cfg

} | arch-chroot /mnt 
umount -R /mnt
swapoff /dev/sda2
reboot

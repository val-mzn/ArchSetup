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
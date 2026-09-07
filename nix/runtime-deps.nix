{pkgs}:
with pkgs; [
  bash
  coreutils # used in most -c pipelines
  findutils # find, for filesystem walks
  gnugrep # grep
  gnused # sed
  gawk # awk, JSON assembly
  which # tool-availability checks
  procps # process checks
  util-linux # system utilities (mount inspection, lsblk-family)
  systemd # systemctl/loginctl/busctl

  matugen # colors
  awww # wallpaper backend

  samba # smbclient, share listing
  cifs-utils.bin # mount.cifs / umount.cifs
  avahi # avahi-browse
  hostname # widgets/about, systeminfo
  curl # HTTP fetches

  bluez # bluetoothctl
  libnotify # notify-send

  wf-recorder # screen recorder
  slurp # region picker

  brightnessctl # widgets/brightness
  cava # widgets/cava
  xdg-utils # xdg-open, file manager
  imagemagick # thumbnail/image conversion
  git # widgets/gitupdate, remote/branch inspection
  python3 # widgets/audiodevices/* backends, calendar/starfield use cfg.python (needs extra pkgs)
]

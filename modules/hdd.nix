{
  lib,
  bash,
  hdparm,
  util-linux,
  gnugrep,
  coreutils,
  ...
}: {
  hardware.sensor.hddtemp = {
    enable = true;
    drives = ["/dev/disk/by-path/*"];
  };

  powerManagement.powerUpCommands = ''
    ${lib.getExe bash} -c '${lib.getExe hdparm} -S 90 -B 1 $(${util-linux}/bin/lsblk -dnp -o name,rota | ${lib.getExe gnugrep} ".*\s1" | ${coreutils}/bin/cut -d " " -f 1)'
  ''; # Spin HDDs down when inactive. Taken from: https://www.reddit.com/r/NixOS/comments/751i5t/comment
}

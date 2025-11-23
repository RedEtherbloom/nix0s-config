{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    bash
    hdparm
    utillinux
    gnugrep
    coreutils
  ];

  hardware.sensor.hddtemp = {
    enable = true;
    drives = ["/dev/disk/by-path/*"];
  };

  # Spin HDDs down when inactive
  # Taken from: https://www.reddit.com/r/NixOS/comments/751i5t/comment
  # WE really need more quiet drives
  powerManagement.powerUpCommands = with pkgs; ''
    ${bash}/bin/bash -c '${hdparm}/bin/hdparm -S 9 -B 20 $(${utillinux}/bin/lsblk -dnp -o name,rota |${gnugrep}/bin/grep ".*\s1" |${coreutils}/bin/cut -d " " -f 1)'
  '';
}

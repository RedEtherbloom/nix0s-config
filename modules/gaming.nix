{ pkgs, home-manager }: {
  home-manager.sharedModules = [
    {
      home.pkgs = with pkgs; [
        mindustry-wayland
        gcs
      ];
    }
  ];

  programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        protontricks.enable = true;
        # X11 -> Wayland Input translation
        extest.enable = true;

        extraCompatPackages = with pkgs; [
          steamtinkerlaunch
        ];
      };
}
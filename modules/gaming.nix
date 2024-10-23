{ pkgs, ... }:
let
  byar-launcher =
    pkgs.fetchFromGitHub {
      owner = "sergv";
      repo = "nixos-config";
      rev = "9c6306c86af6130f76d277e382c346360ec124dd";
      sha256 = "sha256-FazhyLRMmg7A62SYgF/+h3AXnl0CNxElVfCp21cfsYY=";
    }
    + "/beyond-all-reason-launcher.nix";
in
{
  # TODO: Separate options and pkg definition

  home-manager.sharedModules = [
    {
      home.packages = with pkgs; [
        mindustry-wayland
        gcs
        (callPackage byar-launcher { })

        dxvk_2
      ];
    }
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    protontricks.enable = true;
    # X11 -> Wayland Input translation
    extest.enable = true;

    extraCompatPackages = with pkgs; [
      steamtinkerlaunch
    ];
    package = pkgs.steam.override {
      extraPkgs =
        pkgs: with pkgs; [
          libgdiplus
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXrandr
          xorg.libXxf86vm
        ];
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.roles.vtubing;
in {
  options.myOptions.roles.vtubing.enable = lib.mkEnableOption "Vtubing and streaming.";

  config = lib.mkIf cfg.enable {
    programs = {
      steam.enable = true;
      # Reference from: https://codeberg.org/KyloNeko/Linux-Guide-to-Vtubing/src/commit/4c8f0287dab6a7ab59a9d72eee8a32a4c20a6a73/configuration.nix#L122
      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-backgroundremoval
          obs-pipewire-audio-capture
          obs-composite-blur
          obs-shaderfilter
          obs-scale-to-sound
          obs-move-transition
          obs-gradient-source
          obs-replay-source
          obs-source-clone
          obs-3d-effect
          obs-livesplit-one
          waveform
          obs-gstreamer
          obs-vaapi
          obs-vkcapture
        ];
      };
      noisetorch.enable = true;
    };
    services.flatpak.enable = true;
  };
}

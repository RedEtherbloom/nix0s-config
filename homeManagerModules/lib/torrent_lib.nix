{
  pkgs,
  osConfig,
  ...
}: let
  mullvad-torrent = pkgs.writeShellApplication {
    name = "mullvad-torrent";
    runtimeInputs = with pkgs; [
      curl
      jq
      qbittorrent
      flaresolverr
      jackett
      prowlarr
    ];
    text = ''
       PGID="$(ps -o pgid= $$)"
       trap 'pkill -15 -$PGID' SIGTERM

       MULLVAD_CONNECTED="$(curl -s https://am.i.mullvad.net/json | jq -e '.mullvad_exit_ip==true' > /dev/null; echo -n "$?")"
       if [[ "$MULLVAD_CONNECTED" -eq 0 ]]; then
         echo "Successfully connected to Mullvad"
       else
         echo "Could not connect to Mullvad"
         exit "$MULLVAD_CONNECTED"
       fi

      HOST="127.0.0.1" TZ="${osConfig.time.timeZone}" LANG="en_US" flaresolverr &
      jackett &
      Prowlarr -nobrowser &
      qbittorrent
    '';
  };
  vopono-torrent = pkgs.writeShellApplication {
    name = "vopono-torrent";
    runtimeInputs = with pkgs; [
      vopono
      mullvad-torrent
    ];
    text = ''
      # qbittorrent is 8180
      # flaresolverr is 8191
      # jacket is 9117
      # prowlarr is 9696
      vopono exec \
        --provider mullvad \
        --server germany \
        --protocol wireguard \
        -f 8180 \
        -f 8191 \
        -f 9117 \
        -f 9696 \
        mullvad-torrent
    '';
  };
in {
  inherit mullvad-torrent vopono-torrent;
}

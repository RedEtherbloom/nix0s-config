{pkgs, ...}: let
  mullvad-torrent = pkgs.writeShellApplication {
    name = "mullvad-torrent";
    runtimeInputs = with pkgs; [
      curl
      jq
      qbittorrent
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
      # prowlarr is 9696
      vopono exec \
        --provider mullvad \
        --server germany \
        --protocol wireguard \
        --allow-host-access \
        --verbose \
        -f 8180 \
        -f 9696 \
        mullvad-torrent
    '';
  };
in {
  inherit mullvad-torrent vopono-torrent;
}

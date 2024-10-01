{
  # Templates
  wg0= {
    ips = [];
    listenPort = 51820;
    privateKeyFile = "";
    peers = [
      {
        publicKey = "d6yoEQMbMy4M4h45sj28RrgKxYZXRxDHAJ5ASRKZMmQ=";
        allowedIPs = [ "10.69.0.0/24" ];
        endpoint = "51.15.91.213:51820";
        persistentKeepalive = 25;
      }
    ];
  };
  wg1 = {
    ips = [];
    listenPort = 51821;
    privateKeyFile = "";
    peers = [
      {
        publicKey = "81mzxX6r5pTzNqeofAA3L/xYmzrjOiBKQ8tuvBAWOR8=";
        allowedIPs = [ "10.68.0.0/24" ];
        endpoint = "51.15.91.213:51821";
        persistentKeepalive = 25;
      }
    ];
  };
}

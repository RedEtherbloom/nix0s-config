{...}: {
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
    };
  };
  programs.mosh = {
    enable = true;
    openFirewall = true;
  };
}

{
  time.timeZone = "Europe/Berlin";
  i18n = {
    defaultLocale = "en_IE.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      # Abbreviated weekdays at 3 letters
      LC_TIME = "en_IE.UTF-8";
    };
  };

  services.xserver.xkb = {
    model = "pc104";
    layout = "us,us,de";
    variant = "colemak_dh_iso,,nodeadkeys"; # Standard qwerty only needed for Chrysalis custom-keyboard
    options = "terminate:ctrl_alt_bksp,caps:escape";
  };
  console.keyMap = "colemak/mod-dh-iso-us";
}

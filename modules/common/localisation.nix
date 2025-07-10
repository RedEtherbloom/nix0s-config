{
  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_IE.UTF-8";
  i18n.extraLocaleSettings = {
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

  services.xserver.xkb = {
    layout = "de";
  };
  # Affects LUKS unlock
  console.keyMap = "de";
}

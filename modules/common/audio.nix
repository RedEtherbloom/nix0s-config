{...}: {
  services.pulseaudio = {
    enable = false;
    # Just for the Port. Need to check if I have to do this
    zeroconf.discovery.enable = true;
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
}

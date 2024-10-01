{ config, inputs, lib, ... }: {
  sops.secrets."sudoers/optional" = {
    format = "binary";
    sopsFile = "${inputs.our-secrets}/secrets/common/sudoers";
  };  
  security.sudo = {
    enable = true;
    extraConfig = ''
      @includedir ${builtins.dirOf config.sops.secrets."sudoers/optional".path} 
    '';
  };
  
  # in µs
  security.pam.services.sudo.failDelay.delay = 200000;

  # Allow hibernation for regular users
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        subject.isInGroup("users")
          && (
            action.id == "org.freedesktop.login1.hibernate" ||
            action.id == "org.freedesktop.login1.hibernate-multiple-sessions"
          )
        )
      {
        return polkit.Result.YES;
      }
    });
  '';
}

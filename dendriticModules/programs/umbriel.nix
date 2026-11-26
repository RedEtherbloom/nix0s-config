{
  inputs,
  self,
  ...
}: {
  flake = {
    nixosModules.umbriel = {
      imports = [
        self.nixosModules.cachix-noctalia
        inputs.umbriel.nixosModules.default
      ];
      home-manager.sharedModules = [
        self.homeModules.umbriel
      ];

      programs.umbriel.enable = true;
    };
    homeModules.umbriel = {
      imports = [
        inputs.umbriel.homeModules.default
      ];

      programs.umbriel.enable = true;
    };
  };
}

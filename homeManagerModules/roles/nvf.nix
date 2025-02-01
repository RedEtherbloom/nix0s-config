{
  config,
  inputs,
  lib,
  ...
}:
with lib; let
  cfg = config.myOptions.roles.nvf;
in {
  options.myOptions.roles.nvf.enable = mkOption {
    description = "Enable the nvf NeoVim configuration suite for home-manager";
    type = with types; bool;
    # TODO: Copy config state from NixOS option once we create it
    default = false;
  };

  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  config = mkIf cfg.enable {
    programs.nvf = {
      enable = true;
      settings.vim = {
        viAlias = true;
        vimAlias = true;
        # Redundant?
        lsp.enable = true;

        # Copied from Vimjoyer
        statusline.lualine.enable = true;
        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;

        languages = {
          enableFormat = true;
          enableLSP = true;
          enableTreesitter = true;
          # May end up quite large
          enableDAP = true;

          nix = {
            enable = true;
            # TODO: Add nixd language server support
            # TODO: Decide between statix and deadnix
          };
          ts.enable = true;
          nu.enable = true;
          # TODO: Needs nightly check and formatting set up etc. Also check out the options
          rust.enable = true;
          go.enable = true;
          python.enable = true;
          bash.enable = true;
          lua.enable = true;
        };

        lsp.null-ls.sources.ts-format = lib.mkForce ''
          table.insert(
            ls_sources,
            null_ls.builtins.formatting.prettier.with({
              command = "${config.programs.nvf.settings.vim.languages.ts.format.package}/bin/prettier",
              filetypes = { "typescript" , "javascript" },
            })
          )
        '';
      };
    };
  };
}

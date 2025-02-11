{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.roles.nvf;
  inherit (inputs.nvf.lib.nvim.binds) mkKeymap;
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
        options = {
          shiftwidth = 2;
          tabstop = 2;
          expandtab = true;
        };
        viAlias = true;
        vimAlias = true;
        # Redundant?
        lsp.enable = true;
        binds.cheatsheet.enable = true;

        # Copied from Vimjoyer
        statusline.lualine.enable = true;
        telescope = {
          enable = true;
          setupOpts.defaults = {
            path_display = ["smart"];
            # Copied and modified from https://www.reddit.com/r/neovim/comments/0f7nkbe/comment/lle1nbc/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=sha
            # TODO: I want something less buggy than telescope that has built in multi-open
            # TODO: Extract function and set for both normal and insert mode
            mappings = lib.generators.mkLuaInline ''
              {
                 ["i"] = {
                   ["<CR>"] = function(bufnr)
                     local actions = require("telescope.actions")
                     local actions_state = require("telescope.actions.state")
                     local single_selection = actions_state.get_selected_entry()
                     local multi_selection = actions_state.get_current_picker(bufnr):get_multi_selection()
                     if not vim.tbl_isempty(multi_selection) then
                       actions.close(bufnr)
                       for _, file in pairs(multi_selection) do
                         if file.path ~= nil then
                           vim.cmd(string.format("tabedit %s", file.path))
                         end
                       end
                       vim.cmd(string.format("edit %s", single_selection.path))
                     else
                       actions.select_default(bufnr)
                     end
                   end
                 }
              }'';
          };
        };
        autocomplete.nvim-cmp.enable = true;

        keymaps = [(mkKeymap "n" "<leader>fk" "<cmd>Telescope keymaps<CR>" {desc = "Open Telescopes built in keymap";})];
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
          tex = {
            enable = true;
            # TODO: Unsure how to set this up
            build.enable = true;
            lsp.texlab = {
              forwardSearch.enable = true;
              enable = true;
              chktex = {
                enable = true;
                onEdit = true;
                onOpenAndSave = true;
              };
            };
            # Package gets automatically setup from enabled viewer
            pdfViewer = {
              okular = {
                enable = true;
                package = pkgs.kdePackages.okular;
              };
            };
          };
        };
      };
    };
  };
}

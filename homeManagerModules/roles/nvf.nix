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
  inherit (inputs.nvf.lib.nvim.dag) entryBetween;
in {
  options.myOptions.roles.nvf.enable = mkOption {
    description = "Enable the nvf NeoVim configuration suite for home-manager";
    type = with types; bool;
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
        # TODO: Move this to options, if possible
        luaConfigRC.options = entryBetween ["optionscript"] ["basic"] ''
          vim.o.showmode = false
        '';
        # I want swap files
        preventJunkFiles = false;
        viAlias = true;
        vimAlias = true;

        # TODO: Look over other mini utilities(https://notashelf.github.io/nvf/options.html#opt-vim.mini.align.enable)
        mini.surround.enable = true;

        terminal.toggleterm = {
          enable = true;
          lazygit.enable = true;
        };

        statusline.lualine.enable = true;
        # Why was this disabled?
        tabline.nvimBufferline.enable = true;
        telescope = {
          enable = true;
          setupOpts.defaults = {
            # TODO: Choose different strategy
            path_display = ["truncate"];
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

        lsp.enable = true;
        syntaxHighlighting = true;
        languages = {
          enableFormat = true;
          enableLSP = true;
          enableTreesitter = true;
          enableDAP = true;

          nix = {
            enable = true;
            extraDiagnostics = {
              enable = true;
              types = ["statix" "deadnix"];
            };
            lsp = {
              # TODO: Copy a nixd config
              server = "nil";
              # Broken at the moment
              # server = "nixd";
              options = {
                #nixos = {
                #  expr = ''(builtins.getFlake "${self}").nixosConfigurations.${osConfig.networking.hostName}.options'';
                #};
                # home_manager = {
                #   expr = ''(builtins.getFlake "${self}").nixosConfigurations.${osConfig.networking.hostName}.options.home-manager.users.type.getSubOptions []'';
                # };
              };
            };
          };
          ts.enable = true;
          nu.enable = true;
          # TODO: Needs nightly check and formatting set up etc
          rust = {
            enable = true;
            dap.enable = true;
            crates.enable = true;
            lsp.opts = ''
              ['rust-analyzer'] = {
                  checkOnSave = true,
                  procMacro = {
                    enable = true,
                  },
                },
            '';
          };
          go.enable = true;
          python.enable = true;
          bash.enable = true;
          tex = {
            enable = true;
            # TODO: Unsure how to trigger this
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
            pdfViewer.okular = {
              enable = true;
              package = pkgs.kdePackages.okular;
            };
          };
          lua = {
            enable = true;
            lsp.lazydev.enable = true;
          };
          markdown.enable = true;
        };
        utility = {
          # Color picker
          ccc.enable = true;
          motion = {
            leap.enable = true;
            precognition.enable = true;
          };
        };
        lazy.plugins = {
          vim-be-good = {
            package = pkgs.vimPlugins.vim-be-good;
            cmd = ["VimBeGood"];
          };
        };
        extraPlugins = {
          telescope-frecency-nvim = {
            package = pkgs.vimPlugins.telescope-frecency-nvim;
            after = "telescope";
            setup = ''require('telescope').load_extension "frecency"'';
          };
          harpoon = {
            package = pkgs.vimPlugins.harpoon2;
            setup = "require('harpoon').setup {}";
          };
          pomo-nvim = {
            package = pkgs.vimPlugins.pomo-nvim;
            setup = "require('pomo').setup {}";
          };
        };
        autopairs.nvim-autopairs.enable = true;
        notes.obsidian = {
          enable = true;
          setupOpts = {
            workspaces = [
              {
                name = "default";
                path = "~/Documents/Obsidian/default/";
              }
            ];
            daily_notes = {
              date_format = "YYYY/MM/DD-ddd[+W]W";
              folder = "~/Documents/Obsidian/default/01-Tracking/Daily/";
              # Note: May need template specified
            };
          };
        };
        keymaps = [(mkKeymap "n" "<leader>fk" "<cmd>Telescope keymaps<CR>" {desc = "Open Telescopes built in keymap";})];
        binds = {
          cheatsheet.enable = true;
          whichKey.enable = true;
        };
      };
    };
  };
}

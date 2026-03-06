{
  config,
  inputs,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (inputs.nvf.lib.nvim.binds) mkKeymap;

  cfg = config.myOptions.roles.nvf;
in {
  imports = [inputs.nvf.homeManagerModules.default];

  options.myOptions.roles.nvf = {
    enable = lib.mkOption {
      description = "Enable the nvf NeoVim configuration suite for home-manager";
      type = lib.types.bool;
      default = false;
    };
    maximalPackage = lib.mkOption {
      description = "The maximal package of upstream as a comparison";
      type = lib.types.package;
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      neovide = {
        enable = true;
        settings = {
          font = {
            normal = ["CommitMono Nerd Font Mono"];
            size = 10.0;
          };
          srgb = true;
          vsync = true;
        };
      };
      nvf = {
        enable = true;
        defaultEditor = true;
        settings.vim = {
          # Basic section
          bell = "visual";
          debugMode = {
            enable = false;
            logFile = "${config.xdg.stateHome}/nvim/nvim_log_from_nvf.log";
          };
          options = {
            expandtab = true;
            shiftwidth = 2;
            tabstop = 2;
            scrolloff = 8; # Keep cursor centered
          };
          searchCase = "smart";
          viAlias = false;
          vimAlias = true;

          # LSP section
          lsp = {
            enable = true;
            formatOnSave = true;
            inlayHints.enable = true;

            harper-ls = {
              enable = true; # TODO: Version user dictionary via VCS
              settings.linters = {
                SentenceCapitalization = false;
                SpellCheck = false;
                ToDoHyphen = false;
                ExpandControl = false;
                UnclosedQuotes = false;
              };
            };
            lightbulb.enable = true;
            lspkind.enable = true;
            nvim-docs-view.enable = true;
            otter-nvim.enable = true;
            servers.nixd.settings.nixd = {
              nixpkgs.expr = "import <nixpkgs> { allowUnfree = true; }";
              formatting.command = ["alejandra"];
              options = {
                nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${osConfig.networking.hostName}.options";
                home-manager.expr = ''(builtins.getFlake (builtins.toString ./.)).homeConfigurations."${config.home.username}@${osConfig.networking.hostName}".options'';
              };
            };
            trouble.enable = true;
          };
          autocomplete = {
            blink-cmp = {
              enable = true;
              setupOpts.signature.enabled = true;
            };
            nvim-cmp.enable = false;
          };
          autopairs.nvim-autopairs.enable = true;
          spellcheck = {
            enable = true;
            programmingWordlist.enable = true; # Impure: Requires :DirtytalkUpdate after initial run
          };
          languages = {
            enableFormat = true;
            enableTreesitter = true;
            enableDAP = true;
            enableExtraDiagnostics = true;

            bash.enable = true;
            css.enable = true;
            go.enable = true;
            html.enable = true;
            java.enable = true;
            json.enable = true;
            just.enable = true;
            lua = {
              enable = true;
              lsp.lazydev.enable = true;
            };
            markdown.enable = true;
            nix = {
              enable = true;
              lsp.servers = ["nixd"];
              format.type = ["alejandra"];
              extraDiagnostics.types = [
                "statix"
                "deadnix"
              ];
            };
            nu.enable = true;
            python.enable = true;
            rust = {
              enable = true;
              dap.enable = true;
              extensions.crates-nvim.enable = true;
              lsp = {
                package = pkgs.rust-analyzer-nightly;
                opts = ''
                  ['rust-analyzer'] = {
                      cargo = {
                        allFeature = true
                      },
                      checkOnSave = true,
                      procMacro = {
                        enable = true,
                      },
                    },
                '';
              };
            };
            sql.enable = true;
            ts.enable = true;
            typst.enable = true;
          };
          debugger.nvim-dap = {
            enable = true;
            ui.enable = true;
          };
          treesitter = {
            grammars = lib.optionals config.myOptions.roles.gamedev.enable [pkgs.vimPlugins.nvim-treesitter-parsers.godot_resource];
            highlight.enable = true;
          };

          # Visual section
          theme = {
            enable = true;
            name = "oxocarbon";
            style = "dark";
            transparent = true;
          };
          statusline.lualine.enable = true;
          tabline.nvimBufferline.enable = true;
          ui = {
            borders.enable = true;
            breadcrumbs = {
              enable = true;
              navbuddy.enable = true;
            };
            colorizer.enable = true;
            fastaction.enable = true;
            illuminate.enable = true;
            noice.enable = true;
            smartcolumn.enable = false;
          };
          visuals = {
            cellular-automaton.enable = true; # Fun
            cinnamon-nvim.enable = true;
            highlight-undo.enable = true;
            indent-blankline = {
              enable = true;
              setupOpts = {
                indent.repeat_linebreak = false;
                # TODO: Limit number displayed indents
                scope = {
                  show_start = true;
                  show_end = true;
                };
              };
            };
            nvim-cursorline.enable = true;
            nvim-scrollbar.enable = false;
            nvim-web-devicons.enable = true;
            rainbow-delimiters.enable = true; # TODO: Important: Wire up with indent-blankline for better readability
          };
          minimap = {
            codewindow.enable = false; # See: https://github.com/NotAShelf/nvf/issues/1426#issuecomment-3980998398
            minimap-vim.enable = true;
          };

          # Utility section
          binds = {
            cheatsheet.enable = true;
            whichKey.enable = true;
          };
          utility = {
            ccc.enable = true; # Color picker
            diffview-nvim.enable = true;
            icon-picker.enable = true;
            images = {
              image-nvim.enable = false;
              img-clip.enable = true;
            };
            motion = {
              hop.enable = false;
              leap.enable = true;
              precognition.enable = true;
            };
            multicursors.enable = true;
            nvim-biscuits.enable = false; # See: https://github.com/NotAShelf/nvf/issues/1426#issuecomment-3980998398
            outline.aerial-nvim.enable = true; # TODO: Wire up via keybinds
            smart-splits.enable = true;
            surround.enable = true;
            undotree.enable = true;
            yanky-nvim = {
              enable = true;
              setupOpts.ring.storage = "sqlite";
            };
            # TODO: CamelCase motion
          };
          runner.run-nvim.enable = true; # TODO: How do set command to run?
          terminal.toggleterm = {
            enable = true;
            lazygit.enable = true;
            setupOpts.direction = "float"; # TODO: Set up tmux integration or tabbing
            mappings.open = "<leader>tt";
          };
          telescope = {
            enable = true; # TODO: Evaluate snacks picker as modern replacement
            setupOpts = {
              defaults = {
                path_display = ["truncate"];
                # TODO: Maybe try closest instead
                selection_strategy = "follow";
                selection_caret = ">";
                layout_strategy = "flex";
                color_devicons = true;
                # Try quickfix list instead
                # mappings = let
                #   multi_select = lib.generators.mkLuaInline ''
                #     function(prompt_bufnr)
                #       local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
                #       local multi = picker:get_multi_selection()
                #       if not vim.tbl_isempty(multi) then
                #         require('telescope.actions').close(prompt_bufnr)
                #         for _, j in pairs(multi) do
                #           if j.path ~= nil then
                #             vim.cmd(string.format('%s %s', 'edit', j.path))
                #           end
                #         end
                #       else
                #         require('telescope.actions').select_default(prompt_bufnr)
                #       end
                #     end
                #   '';
                # in
                #   lib.attrsets.recursiveUpdate
                #   {
                #     i."<CR>" = multi_select;
                #     n."<CR>" = multi_select;
                #   }
                #   {
                #     i = {
                #       "jj" = lib.generators.mkLuaInline ''
                #         function(prompt_bufnr)
                #           require('telescope.actions').set_command_line(prompt_bufnr)
                #         end
                #       '';
                #     };
                vimgrep_arguments = [
                  "${pkgs.ripgrep}/bin/rg"
                  "--color=never"
                  "--no-heading"
                  "--with-filename"
                  "--line-number"
                  "--column"
                  "--smart-case"
                ]; # Default, except ignore gets respected and hidden files searched
              };
            };
          };
          dashboard = {
            alpha.enable = true;
            dashboard-nvim.enable = false;
          };
          notify.nvim-notify = {
            enable = true;
            setupOpts.background_colour = "#000000";
          };
          session.nvim-session-manager = {
            enable = true;
            setupOpts = {
              autoload_mode = "Disabled";
              autosave_ignore_dirs = [
                "/tmp"
              ];
            };
          };
          snippets.luasnip.enable = true;
          filetree.nvimTree.enable = true;
          comments.comment-nvim.enable = true;
          git = {
            enable = true;
            gitsigns = {
              enable = true;
              codeActions.enable = false; # annoyingly verbose
            };
            neogit.enable = true;
          };
          gestures.gesture-nvim.enable = true;

          # Notes and project management section
          projects.project-nvim.enable = true; # TODO: Lookup how to use project-nvim
          notes = {
            todo-comments.enable = true;
            obsidian = {
              enable = true; # TODO: Find something orgmode escque that handles better than Obsidian
              setupOpts = {
                legacy_commands = false;
                workspaces = [
                  {
                    name = "default";
                    path = "${config.home.homeDirectory}/Documents/Obsidian/default";
                    overrides.notes_dir = "00-Notes";
                  }
                ];
                daily_notes = {
                  date_format = "%Y/%m/%d-%a+W%V";
                  folder = "01-Tracking/Daily";
                  template = "Day.md";
                };
                templates.folder = "02-Templates";
                attachments.folder = "XX-Files";
                new_notes_location = "note_subdir";
                search = {
                  sort_by = "modified";
                  sort_reversed = true;
                };
                checkbox = {
                  enabled = true;
                  create_new = true;
                  order = [
                    " "
                    "x"
                    "!"
                    "~"
                    ">"
                  ];
                };
              };
            };
          };

          # Remaining keybinds section
          keymaps = [
            {
              mode = ["i"];
              key = "jj";
              action = "<Esc>";
              desc = "Exit insert mode";
              silent = true;
            }
            {
              mode = ["t"];
              key = config.programs.nvf.settings.vim.terminal.toggleterm.mappings.open;
              action = "<Cmd>execute v:count . \"ToggleTerm\"<CR>"; # Default toggleterm action set by nvf
              noremap = true; # Prevent toggleterm bind from being swallowed by zsh-vi-mode
            }
            (mkKeymap "n" "<leader>mm" ":w<CR>make!<CR>" {desc = "Trigger a make command";})
          ];

          # Extra plugins and extra Lua snippets
          lazy.plugins = {
            "jj.nvim" = {
              package = pkgs.vimPlugins.jj-nvim;
              setupModule = "jj";
              setupOpts = {};
            };
            "lazyjj.nvim" = {
              package = pkgs.vimPlugins.lazyjj-nvim;
              setupModule = "lazyjj";
              setupOpts = {};
            };
            "lean.nvim" = {
              package = pkgs.vimPlugins.lean-nvim;
              setupModule = "lean";
              setupOpts = {};
              event = [
                "BufReadPre *.lean"
                "BufNewFile *.lean"
              ];
            };
          };
          luaConfigRC = {
            neovideOpacity = ''
                          if vim.g.neovide then
              vim.g.neovide_opacity = ${toString config.stylix.opacity.terminal}
              vim.g.neovide_normal_opacity = ${toString config.stylix.opacity.terminal}
                   end
            '';
            neovideClipboard = ''
              if vim.g.neovide then
                vim.keymap.set('n', '<D-s>', ':w<CR>') -- Save
                vim.keymap.set('v', '<D-c>', '"+y') -- Copy
                vim.keymap.set('n', '<D-v>', '"+P') -- Paste normal mode
                vim.keymap.set('v', '<D-v>', '"+P') -- Paste visual mode
                vim.keymap.set('c', '<D-v>', '<C-R>+') -- Paste command mode
                vim.keymap.set('i', '<D-v>', '<ESC>l"+Pli') -- Paste insert mode
              end

              -- Allow clipboard copy paste in neovim
              vim.api.nvim_set_keymap(''', '<D-v>', '+p<CR>', { noremap = true, silent = true})
              vim.api.nvim_set_keymap('!', '<D-v>', '<C-R>+', { noremap = true, silent = true})
              vim.api.nvim_set_keymap('t', '<D-v>', '<C-R>+', { noremap = true, silent = true})
              vim.api.nvim_set_keymap('v', '<D-v>', '<C-R>+', { noremap = true, silent = true})
            '';
          };
        };
      };
    };
    home.packages = with pkgs; [
      # Utility
      inotify-tools # More performant dir watching

      # Languages
      lean4
    ];
    myOptions.roles.nvf = let
      nvfMaximalFixes = {
        config.vim = {
          utility.motion.hop.enable = lib.mkForce false;
          languages.sql.enable = lib.mkForce false;
          treesitter.textobjects.enable = lib.mkForce false;
        };
      };
    in {
      maximalPackage =
        (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [
            nvfMaximalFixes
            (import "${inputs.nvf}/configuration.nix" true)
          ];
        }).neovim;
    };
    stylix.targets = {
      neovide.enable = false;
      neovim.enable = false;
      nvf.enable = false;
    };
  };
}

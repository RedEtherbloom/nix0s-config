# TODO: Move to programs
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.roles.nvf;
  inherit (inputs.nvf.lib.nvim.binds) mkKeymap;
in {
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  options.myOptions.roles.nvf.enable = lib.mkOption {
    description = "Enable the nvf NeoVim configuration suite for home-manager";
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf cfg.enable {
    stylix.targets = {
      neovim.enable = false;
      nvf.enable = false;
      neovide.enable = false;
    };
    sops.secrets."ai_keys/anthropic" = {
      # TODO: Replace inputs.our-secrets with just our-secrets via import in flake.nix
      sopsFile = "${inputs.our-secrets}/secrets/services/ai_keys.yaml";
      key = "anthropic";
    };
    programs = {
      neovide.enable = true;
      nvf = {
        enable = true;
        defaultEditor = true;
        enableManpages = true;
        settings.vim = rec {
          debugMode = {
            enable = true;
            # Afaik by default under "$HOME/.cache/nvim"
            logFile = "${config.xdg.stateHome}/nvim/nvim_log_from_nvf.log";
          };
          options = {
            shiftwidth = 2;
            tabstop = 2;
            expandtab = true;
            # Replace with one character
            conceallevel = 1;
            # Potential good compromise
            foldlevelstart = 4;
            showmode = false;
            swapfile = true;
          };
          viAlias = true;
          vimAlias = true;
          searchCase = "smart";

          theme = {
            enable = true;
            name = "catppuccin";
            style = "macchiato";
            transparent = true;
          };

          ui = {
            borders.enable = true;
            breadcrumbs.enable = true;
            colorizer.enable = true;
            # Error: Breaks visual mode display in odd ways
            # modes-nvim.enable = true;
            # TODO: Lookup keybindings
            fastaction.enable = true;
            # Highlighting other uses
            # TODO: How to jump to them?
            # This perhaps breaks visual mode from time to time(the purple cursor that doesn't mark an area)
            illuminate.enable = true;
            # Is this the superfluos windows?
            noice.enable = false;
          };

          # TODO: Lookup gestures

          # TODO: Look over other mini utilities(https://notashelf.github.io/nvf/options.html#opt-vim.mini.align.enable)
          mini.surround.enable = true;

          terminal.toggleterm = {
            enable = true;
            lazygit.enable = true;
            setupOpts = {
              direction = "float";
            };
            mappings = {
              open = "<c-ö>";
            };
          };
          session.nvim-session-manager.enable = true;
          snippets.luasnip.enable = true;
          # TODO: Look what noice does

          dashboard = {
            # Override default dashboard
            dashboard-nvim.enable = false;
            alpha.enable = true;
          };

          # TODO: What exactly are projects?
          projects.project-nvim.enable = true;

          statusline.lualine.enable = true;
          # TODO: This is buggy as hell
          tabline.nvimBufferline.enable = false;
          # Should be better than nvim-cmp, e.g. better search via frecency and lower latency
          autocomplete.blink-cmp.enable = true;
          lsp = {
            enable = true;
            # The trouble windows can bring vim into a weird broken state.
            # TODO: Lookup good vim default in nvf repo
            trouble.enable = true;
            # VSCode like pictograms for completion
            lspkind.enable = true;
            # TODO: Does this clash with precognition?
            lightbulb.enable = true;
            # TODO: Think about replacing trouble with e.g. lspsaga. IMPORTANT!
            # TODO: Lookup otter-nvim. May help e.g. obsidian
            nvim-docs-view.enable = true;
          };
          syntaxHighlighting = true;
          visuals = {
            # Smooth scrolling!!
            cinnamon-nvim.enable = true;
            # TODO: Check if illuminate is enough, or if we want to add cursorline
            fidget-nvim.enable = true;
            # TODO: Disable on reformat
            highlight-undo.enable = true;
            # TODO: Maybe add color for different indentiation levels
            indent-blankline.enable = true;
          };
          filetree.neo-tree = {
            enable = true;
            setupOpts = {
              enable_cursor_hijack = true;
              git_status_async = true;
              buffers = {
                follow_current_file = {
                  enabled = true;
                  # Auto-close expanded dirs when no longer needed
                  leave_dirs_open = false;
                };
              };
              close_if_last_window = true;
            };
          };
          # TODO: Does this enable e.g. jumping up and down in code blocks(like up from if to function)
          treesitter.context = {
            enable = true;
            setupOpts = {
              separator = "󱙧";
              max_lines = 1;
              # TODO: Compare to cursor
              mode = "topline";
            };
          };
          # LSP
          debugger.nvim-dap = {
            enable = true;
            ui.enable = true;
          };
          git = {
            enable = true;
            gitsigns = {
              enable = true;
              # This is annoyingly verbose
              codeActions.enable = false;
            };
          };
          languages = {
            enableFormat = true;
            enableTreesitter = true;
            enableDAP = true;

            nix = {
              enable = true;
              extraDiagnostics = {
                enable = true;
                types = ["statix" "deadnix"];
              };
              # TODO: Checkout nixd from git
              lsp.server = "nixd";
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
            java.enable = true;
            typst.enable = true;
          };
          utility = {
            icon-picker.enable = true;
            # TODO: Make sure to use macros instead whenever we can
            multicursors.enable = true;
            # TODO: Look into a plugin like yanky-nvim for better yanking
            # Color picker
            ccc.enable = true;
            # Leetcode / programming problems for training
            leetcode-nvim.enable = true;
            motion = {
              leap.enable = true;
              # TODO: lookup additional options
              precognition.enable = true;
            };
            images = {
              # TODO: Write rule for neovide with require('image-nvim').disable()
              # TODO: Currently throws a weird error with line('w0') being nil or something on startup
              image-nvim = {
                enable = false;
                setupOpts = {
                  backend = "kitty";
                };
              };
              # Pasting image support
              img-clip.enable = true;
            };
            # What does this do again?
            surround.enable = true;
          };
          lazy.plugins = {
            vim-be-good = {
              package = pkgs.vimPlugins.vim-be-good;
              cmd = ["VimBeGood"];
            };
            "music-controls.nvim" = {
              package = pkgs.vimPlugins.music-controls-nvim;
              lazy = false;
              setupOpts = {
                default_player = "spotify_client";
              };
            };
            # TODO: Command doesn't load for some reason
            "treesj" = {
              package = pkgs.vimPlugins.treesj;
              cmd = [
                "TSJToggle"
                "TSJSplit"
                "TSJJoin"
              ];
              setupOpts = {
                use_default_keymaps = false;
              };
            };
            ale = {
              package = pkgs.vimPlugins.ale;
              # TODO: Does this autoload without a configured cmd etc.?
            };
          };
          extraPlugins = {
            telescope-frecency-nvim = {
              package = pkgs.vimPlugins.telescope-frecency-nvim;
              after = ["telescope"];
              setup = ''require('telescope').load_extension "frecency"'';
            };
            # Debugging if harpoon maybe messes up buffers
            # harpoon = {
            #   package = pkgs.vimPlugins.harpoon2;
            #   setup = "require('harpoon').setup {}";
            # };
            pomo-nvim = {
              package = pkgs.vimPlugins.pomo-nvim;
              setup = "require('pomo').setup {}";
            };
            # Learn nvim-surround shortcuts
            "surround-ui.nvim" = {
              package = pkgs.vimPlugins.surround-ui-nvim;
              setup = ''
                require("surround-ui").setup({
                  -- Default
                  root_key = "S",
                })
              '';
            };
            vim-startuptime = {
              package = pkgs.vimPlugins.vim-startuptime;
            };
            # TODO: Think of adding CamelCaseMotion plugin
          };
          # TODO: Create rule for e.g. nix pairs or moving the cursor after the brackets after insert
          autopairs.nvim-autopairs.enable = true;
          notes = {
            todo-comments = {
              enable = true;
              setupOpts = {
                # Disable displaying the marks in the signs column for visual clarity
                keywords = {
                  TODO = {
                    icon = " ";
                    color = "info";
                    signs = false;
                    # TODO: Does this properly include the # symbol? Doesn't seem like it
                    alt = ["# TODO:"];
                  };
                };
              };
            };
            # TODO: Give this a try
            # Broken on 02-07-2025 due to treesitter problems
            orgmode.enable = false;
            obsidian = {
              enable = true;
              setupOpts = {
                workspaces = [
                  {
                    name = "default";
                    path = "${config.home.homeDirectory}/Documents/Obsidian/default";
                    overrides = {
                      notes_dir = "00-Notes";
                    };
                  }
                ];
                daily_notes = {
                  date_format = "%Y/%m/%d-%a+W%V";
                  folder = "01-Tracking/Daily";
                  template = "Day.md";
                };
                templates.folder = "02-Templates";
                new_notes_location = "note_subdir";
                # TODO: Add follow_link_function. Otherwise images etc. get ignored. Maybe they can be rendered inline some way?
                # Force Obsidian to focus on :ObsidianOpen
                open_app_foreground = true;
                # TODO: May need to specify telescope etc. in picker
                sort_by = "modified";
                sort_reversed = true;
                # TODO: may want to up search_max_lines from 1000 default iirc
                attachments.img_folder = "XX-Files";
                ui = {
                  checkboxes = lib.generators.mkLuaInline ''
                    {
                      [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
                      ["x"] = { char = "", hl_group = "ObsidianDone" },
                      ["!"] = { char = "", hl_group = "ObsidianImportant" },
                      ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
                      [">"] = { char = "", hl_group = "ObsidianRightArrow" },
                    }
                  '';
                };
              };
            };
          };

          binds = {
            cheatsheet.enable = true;
            whichKey.enable = true;
            # Break bad habits
            hardtime-nvim = {
              enable = true;
              setupOpts = {
                max_count = 2;
                disable_mouse = false;
                timeout = 2000;
                restriction_mode = "block";
                max_insert_idle_ms = 8000;
              };
            };
          };
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
              key = terminal.toggleterm.mappings.open;
              # Default toggleterm action set by nvf
              action = "<Cmd>execute v:count . \"ToggleTerm\"<CR>";
              # This prevents my terminal keybinding from getting eaten by zsh-vi-mode
              noremap = true;
            }
            (mkKeymap "n" "<leader>fk" "<cmd>Telescope keymaps<CR>" {desc = "Open Telescopes built in keymap";})
            (mkKeymap "n" "<leader>fp" "<cmd>Telescope oldfiles<CR>" {desc = "Open list of previous files.";})
            (mkKeymap "n" "<leader>fo" "<cmd>ObsidianQuickSwitch<CR>" {desc = "Open quick switcher for obsidian files.";})
            (mkKeymap "n" "<leader>oty" "<cmd>ObsidianYesterday<CR>" {desc = "Open yesterday's Obsidian note";})
            (mkKeymap "n" "<leader>otn" "<cmd>ObsidianToday<CR>" {desc = "Open today's Obsidian note";})
            (mkKeymap "n" "<leader>ott" "<cmd>ObsidianTomorrow<CR>" {desc = "Open tomorrow's Obsidian note";})
            (mkKeymap "n" "<leader>otp" "<cmd>ObsidianDailies<CR>" {desc = "Open a picker with the dailies of this week.";})
            (mkKeymap "n" "<leader>oto" "<cmd>ObsidianOpen<CR>" {desc = "Open current note in Obsidian window.";})
            (mkKeymap "n" "<leader>oc" "<cmd>ObsidianToggleCheckbox<CR>" {desc = "Toggle the current textbox.";})
            (mkKeymap "n" "<leader>of" "<cmd>ObsidianFollowLink<CR>" {desc = "Follow the link under the Obsidian cursor.";})
            (mkKeymap "n" "<leader>onn" "<cmd>ObsidianNew<CR>" {desc = "Create new Obsidian note.";})
            (mkKeymap "n" "<leader>ont" "<cmd>ObsidianNewFromTemplate<CR>" {desc = "Create new Obsidian note from template.";})
            (mkKeymap "n" "<leader>one" "<cmd>ObsidianExtractNote<CR>" {desc = "Extract marked text into new note.";})
            (mkKeymap "n" "<leader>onr" "<cmd>ObsidianRename<CR>" {desc = "Rename current note.";})
            (mkKeymap "n" "<leader>oll" "<cmd>ObsidianLink<CR>" {desc = "Insert link to existing Obsidian note.";})
            (mkKeymap "n" "<leader>oln" "<cmd>ObsidianLinkNew<CR>" {desc = "Insert link to new Obsidian note.";})
            (mkKeymap "n" "<leader>oss" "<cmd>ObsidianSearch<CR>" {desc = "Search through Obsidian vault.";})
            (mkKeymap "n" "<leader>ost" "<cmd>ObsidianTags<CR>" {desc = "Search through Obsidian tags.";})
            (mkKeymap "n" "<leader>osc" "<cmd>ObsidianTOC<CR>" {desc = "Jump to Obsidian table of contents.";})
            (mkKeymap "n" "<leader>osl" "<cmd>ObsidianLinks<CR>" {desc = "Open all links in current note in picker.";})
            (mkKeymap "n" "<leader>osb" "<cmd>ObsidianBacklinks<CR>" {desc = "Open all backlinks in current note in picker.";})
            (mkKeymap "n" "<leader>osr" "<cmd>ObsidianCheck<CR>" {desc = "Check integrity of Vault.";})
            (mkKeymap "n" "<leader>osv" "<cmd>ObsidianDebug<CR>" {desc = "Turn on additional Obsidian logging.";})
            (mkKeymap "n" "<leader>oww" "<cmd>ObsidianWorkspace<CR>" {desc = "Switch Obsidian workspace.";})
            (mkKeymap "n" "<leader>opi" "<cmd>ObsidianPasteImg<CR>" {desc = "Paste image from clipboard into note.";})
            (mkKeymap "n" "<leader>se" "<cmd>SessionManager<CR>" {desc = "Open Session manager dialog.";})
            (mkKeymap "n" "<leader>tj" "<cmd>TSJJoin<CR>" {desc = "Join the current block.";})
            (mkKeymap "n" "<leader>ts" "<cmd>TSJSplit<CR>" {desc = "Split the current block.";})
            (mkKeymap "n" "<leader>tt" "<cmd>TSJToggle<CR>" {desc = "Toggle splitting or joining the current block.";})
          ];
          telescope = {
            enable = true;
            setupOpts.defaults = {
              path_display = ["truncate"];
              # TODO: Maybe try closest instead
              selection_strategy = "follow";
              selection_caret = "󱙧";
              layout_strategy = "flex";
              color_devicons = true;
              mappings = let
                multi_select = lib.generators.mkLuaInline ''
                  function(prompt_bufnr)
                    local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
                    local multi = picker:get_multi_selection()
                    if not vim.tbl_isempty(multi) then
                      require('telescope.actions').close(prompt_bufnr)
                      for _, j in pairs(multi) do
                        if j.path ~= nil then
                          vim.cmd(string.format('%s %s', 'edit', j.path))
                        end
                      end
                    else
                      require('telescope.actions').select_default(prompt_bufnr)
                    end
                  end
                '';
              in
                lib.attrsets.recursiveUpdate {
                  i."<CR>" = multi_select;
                  n."<CR>" = multi_select;
                } {
                  i = {
                    "jj" = lib.generators.mkLuaInline ''
                      function(prompt_bufnr)
                        require('telescope').actions.set_command_line(prompt_bufnr)
                      end
                    '';
                  };
                  n = {
                    "jj" = lib.generators.mkLuaInline ''
                      function(prompt_bufnr)
                        require('telescope').actions.close(prompt_bufnr)
                      end
                    '';
                  };
                };
            };
          };

          # TODO: Claude can't read my code
          assistant.codecompanion-nvim = {
            enable = true;
            setupOpts = {
              display.chat.show_settings = true;
              strategies = {
                chat.adapter = "anthropic";
                inline.adapter = "anthropic";
                cmd.adapter = "anthropic";
              };
              adapters = lib.generators.mkLuaInline ''{
                anthropic = function()
                  return require("codecompanion.adapters").extend("anthropic", {
                    env = {
                      api_key = "cmd:cat ${config.sops.secrets."ai_keys/anthropic".path}",
                    },
                  })
                end,
              }'';
            };
          };
        };
      };
    };
  };
}

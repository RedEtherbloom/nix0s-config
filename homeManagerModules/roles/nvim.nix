# TODO: Too many alignment lines. How to reduce?
# TODO: Install maximal configuration as an interesting alternative
# TODO: Editlist gets filled with trash by some plugin
{
  config,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  cfg = config.myOptions.roles.nvf;
  inherit (inputs.nvf.lib.nvim.binds) mkKeymap;
  inherit (inputs.nvf.lib.nvim) dag;
  inherit (inputs.nvf.lib) neovimConfiguration;
in
{
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  options.myOptions.roles.nvf = {
    enable = lib.mkOption {
      description = "Enable the nvf NeoVim configuration suite for home-manager";
      type = lib.types.bool;
      default = false;
    };
    frankenPackage = lib.mkOption {
      description = "Badly merged upstream and local config used for refactoring";
      type = lib.types.package;
    };
    newPackage = lib.mkOption {
      description = "Redone nvf config";
      type = lib.types.package;
    };
    maximalPackage = lib.mkOption {
      description = "The maximal package of upstream as a comparison";
      type = lib.types.package;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      rec {
        sops.secrets."ai_keys/anthropic" = {
          sopsFile = "${secrets}/secrets/services/ai_keys.yaml";
          key = "anthropic";
        };
        programs = {
          # TODO: System clipboard
          neovide = {
            enable = true;
            settings = {
              font = {
                # TODO: I think it fell back to it's default. How can I query neovide for it's runtime value?
                normal = [ "OpenDyslexicM Nerd Font Mono" ];
                size = 12.0;
              };
              srgb = true;
              vsync = true;
            };
          };
          nvf = {
            enable = true;
            defaultEditor = true;
            enableManpages = true;
            settings.vim = rec {
              debugMode = {
                enable = false;
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
                # Keep cursor centerred
                scrolloff = 8;
              };
              # Setup transparency
              # entryBetween is mostly used to keep the entry close to the globals section for visual clarity
              luaConfigRC = {
                neovide = dag.entryBetween [ "basic" ] [ "globalsScript" ] ''
                  vim.g.neovide_opacity = 0.9;
                  vim.g.neovide_normal_opacity = 0.9;
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

              # Does not work
              # TODO: Look over other mini utilities(https://notashelf.github.io/nvf/options.html#opt-vim.mini.align.enable)
              # mini.surround.enable = true;

              terminal.toggleterm = {
                enable = true;
                lazygit.enable = true;
                setupOpts = {
                  direction = "float";
                };
                mappings = {
                  open = "<c-k>";
                };
              };
              session.nvim-session-manager.enable = true;
              snippets.luasnip.enable = true;
              # TODO: Look what noice does

              dashboard = {
                # Disable default dashboard
                dashboard-nvim.enable = false;
                alpha.enable = true;
              };

              # TODO: What exactly are projects?
              projects.project-nvim.enable = true;

              statusline.lualine = {
                enable = true;
                theme = "horizon";
              };
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
                # TODO: Disable with neovide
                cinnamon-nvim.enable = true;
                # TODO: Check if illuminate is enough, or if we want to add cursorline
                fidget-nvim.enable = true;
                # TODO: Disable on reformat
                highlight-undo.enable = true;
                rainbow-delimiters.enable = true;
                # TODO: Integrate with rainbow-delimeters
                indent-blankline = {
                  enable = true;
                  setupOpts = {
                    scope = {
                      show_start = true;
                      show_end = true;
                    };
                  };
                };
              };
              filetree.nvimTree = {
                enable = false;
              };
              treesitter = {
                incrementalSelection = {
                  enable = true;
                };
                fold = true;
                # TODO: Think we don't needs this
                context = {
                  enable = true;
                  setupOpts = {
                    separator = "󱙧";
                    max_lines = 1;
                    # TODO: Compare to cursor
                    mode = "cursor";
                  };
                };
                textobjects.enable = true;
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
                # TODO: This really needs more plugins for e.g. snippes, automatic semicolon
                # TODO: Format no longer triggers, need to fix
                nix = {
                  enable = true;
                  extraDiagnostics = {
                    enable = true;
                    types = [
                      "statix"
                      "deadnix"
                    ];
                  };
                  format = {
                    enable = true;
                    type = [ "alejandra" ];
                  };
                  # TODO: Checkout nixd from git
                  # TODO: Nixd formatting is currently broken?
                  lsp.servers = [
                    "nil"
                    # "nixd"
                  ];
                };
                ts.enable = true;
                nu.enable = true;
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
                go.enable = true;
                python.enable = true;
                bash.enable = true;
                # tex = {
                #   enable = true;
                #   # TODO: Unsure how to trigger this
                #   build.enable = true;
                #   lsp.texlab = {
                #     forwardSearch.enable = true;
                #     enable = true;
                #     chktex = {
                #       enable = true;
                #       onEdit = true;
                #       onOpenAndSave = true;
                #     };
                #   };
                #   # Package gets automatically setup from enabled viewer
                #   pdfViewer.okular = {
                #     enable = true;
                #     package = pkgs.kdePackages.okular;
                #   };
                # };
                lua = {
                  enable = true;
                  lsp.lazydev.enable = true;
                };
                markdown.enable = true;
                java.enable = true;
                # TODO: Lookup good supporting plugins
                typst.enable = true;
              };
              utility = {
                outline.aerial-nvim.enable = true;
                icon-picker.enable = true;
                # TODO: Make sure to use macros instead whenever we can
                multicursors.enable = true;
                # TODO: Look into a plugin like yanky-nvim for better yanking
                # Color picker
                ccc.enable = true;
                # Leetcode / programming problems for training
                leetcode-nvim.enable = true;
                # Lookup other motion plugins
                motion = {
                  leap.enable = true;
                  precognition = {
                    enable = true;
                    setupOpts = {
                      highlighColor = {
                        foreground = "#dcf41f";
                        background = "#dcf41f";
                        # background = "#000000";
                      };
                      hints = {
                        Caret = {
                          text = "_";
                          prio = 2;
                        };
                        Dollar = {
                          text = "$";
                          prio = 1;
                        };
                        MatchingPair = {
                          text = "%";
                          prio = 5;
                        };
                        Zero = {
                          text = "0";
                          # Disabled
                          prio = 0;
                        };
                        w = {
                          text = "w";
                          prio = 10;
                        };
                        b = {
                          text = "b";
                          prio = 9;
                        };
                        e = {
                          text = "e";
                          prio = 8;
                        };
                        W = {
                          text = "W";
                          prio = 7;
                        };
                        B = {
                          text = "B";
                          prio = 6;
                        };
                        E = {
                          text = "E";
                          prio = 5;
                        };
                      };
                    };
                  };
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
                # Broken at the moment
                surround.enable = true;
                # Needed for nvim-coach
                snacks-nvim.enable = true;
              };
              lazy.plugins = {
                vim-be-good = {
                  package = pkgs.vimPlugins.vim-be-good;
                  cmd = [ "VimBeGood" ];
                };
                "music-controls.nvim" = {
                  package = pkgs.vimPlugins.music-controls-nvim;
                  lazy = false;
                  setupOpts = {
                    default_player = "spotify_client";
                  };
                };
                # TODO: Command doesn't load for some reason
                treesj = {
                  package = pkgs.vimPlugins.treesj;
                  setupModule = "treesj";
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
                # TODO: Doesn't start yet
                "vimplugin-vim-coach.nvim" = {
                  package = pkgs.vimPlugins.vim-coach-nvim;
                  setupModule = "vim-coach";
                  cmd = [ "VimCoach" ];
                };
              };
              extraPlugins = {
                telescope-frecency-nvim = {
                  package = pkgs.vimPlugins.telescope-frecency-nvim;
                  after = [ "telescope" ];
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
                # TODO: Learn nvim-surround shortcuts
                # "surround-ui.nvim" = {
                #   package = pkgs.vimPlugins.surround-ui-nvim;
                #   setup = ''
                #     require("surround-ui").setup({
                #       -- Default
                #       root_key = "S",
                #     })
                #   '';
                # };
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
                        alt = [ "# TODO:" ];
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
                    max_count = 3;
                    disable_mouse = false;
                    timeout = 2000;
                    restriction_mode = "hint";
                    max_insert_idle_ms = 8000;
                  };
                };
              };
              keymaps = [
                {
                  mode = [ "i" ];
                  key = "jj";
                  action = "<Esc>";
                  desc = "Exit insert mode";
                  silent = true;
                }
                {
                  mode = [ "t" ];
                  key = terminal.toggleterm.mappings.open;
                  # Default toggleterm action set by nvf
                  action = "<Cmd>execute v:count . \"ToggleTerm\"<CR>";
                  # This prevents my terminal keybinding from getting eaten by zsh-vi-mode
                  noremap = true;
                }
                (mkKeymap "n" "<leader>fk" "<cmd>Telescope keymaps<CR>" {
                  desc = "Open Telescopes built in keymap";
                })
                (mkKeymap "n" "<leader>fp" "<cmd>Telescope oldfiles<CR>" { desc = "Open list of previous files."; })
                (mkKeymap "n" "<leader>fo" "<cmd>ObsidianQuickSwitch<CR>" {
                  desc = "Open quick switcher for obsidian files.";
                })
                (mkKeymap "n" "<leader>oty" "<cmd>ObsidianYesterday<CR>" {
                  desc = "Open yesterday's Obsidian note";
                })
                (mkKeymap "n" "<leader>otn" "<cmd>ObsidianToday<CR>" { desc = "Open today's Obsidian note"; })
                (mkKeymap "n" "<leader>ott" "<cmd>ObsidianTomorrow<CR>" { desc = "Open tomorrow's Obsidian note"; })
                (mkKeymap "n" "<leader>otp" "<cmd>ObsidianDailies<CR>" {
                  desc = "Open a picker with the dailies of this week.";
                })
                (mkKeymap "n" "<leader>oto" "<cmd>ObsidianOpen<CR>" {
                  desc = "Open current note in Obsidian window.";
                })
                (mkKeymap "n" "<leader>oc" "<cmd>ObsidianToggleCheckbox<CR>" {
                  desc = "Toggle the current textbox.";
                })
                (mkKeymap "n" "<leader>of" "<cmd>ObsidianFollowLink<CR>" {
                  desc = "Follow the link under the Obsidian cursor.";
                })
                (mkKeymap "n" "<leader>onn" "<cmd>ObsidianNew<CR>" { desc = "Create new Obsidian note."; })
                (mkKeymap "n" "<leader>ont" "<cmd>ObsidianNewFromTemplate<CR>" {
                  desc = "Create new Obsidian note from template.";
                })
                (mkKeymap "n" "<leader>one" "<cmd>ObsidianExtractNote<CR>" {
                  desc = "Extract marked text into new note.";
                })
                (mkKeymap "n" "<leader>onr" "<cmd>ObsidianRename<CR>" { desc = "Rename current note."; })
                (mkKeymap "n" "<leader>oll" "<cmd>ObsidianLink<CR>" {
                  desc = "Insert link to existing Obsidian note.";
                })
                (mkKeymap "n" "<leader>oln" "<cmd>ObsidianLinkNew<CR>" {
                  desc = "Insert link to new Obsidian note.";
                })
                (mkKeymap "n" "<leader>oss" "<cmd>ObsidianSearch<CR>" { desc = "Search through Obsidian vault."; })
                (mkKeymap "n" "<leader>ost" "<cmd>ObsidianTags<CR>" { desc = "Search through Obsidian tags."; })
                (mkKeymap "n" "<leader>osc" "<cmd>ObsidianTOC<CR>" {
                  desc = "Jump to Obsidian table of contents.";
                })
                (mkKeymap "n" "<leader>osl" "<cmd>ObsidianLinks<CR>" {
                  desc = "Open all links in current note in picker.";
                })
                (mkKeymap "n" "<leader>osb" "<cmd>ObsidianBacklinks<CR>" {
                  desc = "Open all backlinks in current note in picker.";
                })
                (mkKeymap "n" "<leader>osr" "<cmd>ObsidianCheck<CR>" { desc = "Check integrity of Vault."; })
                (mkKeymap "n" "<leader>osv" "<cmd>ObsidianDebug<CR>" {
                  desc = "Turn on additional Obsidian logging.";
                })
                (mkKeymap "n" "<leader>oww" "<cmd>ObsidianWorkspace<CR>" { desc = "Switch Obsidian workspace."; })
                (mkKeymap "n" "<leader>opi" "<cmd>ObsidianPasteImg<CR>" {
                  desc = "Paste image from clipboard into note.";
                })
                (mkKeymap "n" "<leader>se" "<cmd>SessionManager<CR>" { desc = "Open Session manager dialog."; })
                (mkKeymap "n" "<leader>tj" "<cmd>TSJJoin<CR>" { desc = "Join the current block."; })
                (mkKeymap "n" "<leader>ts" "<cmd>TSJSplit<CR>" { desc = "Split the current block."; })
                (mkKeymap "n" "<leader>tt" "<cmd>TSJToggle<CR>" {
                  desc = "Toggle splitting or joining the current block.";
                })
                (mkKeymap "n" "<leader>mm" ":w<CR>make!<CR>" {
                  desc = "Trigger a make command";
                })
              ];
              # TODO: Evaluate snacks picker as modern replacement
              telescope = {
                enable = true;
                setupOpts = {
                  defaults = {
                    path_display = [ "truncate" ];
                    # TODO: Maybe try closest instead
                    selection_strategy = "follow";
                    selection_caret = "󱙧";
                    layout_strategy = "flex";
                    color_devicons = true;
                    winblend = 10;
                    mappings =
                      let
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
                      lib.attrsets.recursiveUpdate
                        {
                          i."<CR>" = multi_select;
                          n."<CR>" = multi_select;
                        }
                        {
                          i = {
                            "jj" = lib.generators.mkLuaInline ''
                              function(prompt_bufnr)
                                require('telescope.actions').set_command_line(prompt_bufnr)
                              end
                            '';
                          };
                          # n = {
                          #   "jj" = lib.generators.mkLuaInline ''
                          #     function(prompt_bufnr)
                          #       require('telescope.actions').close(prompt_bufnr)
                          #     end
                          #   '';
                          # };
                        };
                    # Default, except ignore gets respected and hidden filessearched
                    vimgrep_arguments = [
                      "${pkgs.ripgrep}/bin/rg"
                      "--color=never"
                      "--no-heading"
                      "--with-filename"
                      "--line-number"
                      "--column"
                      "--smart-case"
                    ];
                  };
                  # TODO: Gives empty results. Debug.
                  # pickers.find_files.find_command = [
                  #   "${pkgs.fd}/bin/fd"
                  #   "--hidden"
                  #   "--type file"
                  #   "--type symlink"
                  # ];
                };
              };
              # TODO: Claude can't read our code
              assistant.codecompanion-nvim = {
                enable = true;
                setupOpts = {
                  display.chat.show_settings = true;
                  strategies = {
                    chat.adapter = "anthropic";
                    inline.adapter = "anthropic";
                    cmd.adapter = "anthropic";
                  };
                  adapters = lib.generators.mkLuaInline ''
                    {
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
        stylix.targets = {
          neovim.enable = false;
          nvf.enable = false;
          neovide.enable = false;
        };
        myOptions.roles.nvf =
          let
            nvfMaximalFixes = {
              config.vim.utility.motion.hop.enable = lib.mkForce false;
            };
          in
          {
            frankenPackage =
              (neovimConfiguration {
                inherit pkgs;
                modules = [
                  nvfMaximalFixes
                  (lib.attrsets.recursiveUpdate
                    # Maximal configuration
                    (import "${inputs.nvf}/configuration.nix" true)
                    { config = { inherit (programs.nvf.settings) vim; }; }
                  )
                ];
              }).neovim;
            newPackage =
              (neovimConfiguration {
                inherit pkgs;
                modules = [
                  {
                    # Derived from nvf maximal configuration
                    config.vim = {
                      viAlias = true;
                      vimAlias = true;
                      debugMode = {
                        enable = false;
                        level = 16;
                        logFile = "/tmp/nvim.log";
                      };

                      spellcheck = {
                        enable = true;
                        programmingWordlist.enable = true;
                      };

                      lsp = {
                        enable = true;

                        formatOnSave = true;
                        lightbulb.enable = true;
                        lspkind.enable = false;
                        lspsaga.enable = false;
                        trouble.enable = true;
                        lspSignature.enable = false; # conflicts with blink in maximal
                        otter-nvim.enable = true;
                        nvim-docs-view.enable = true;
                        harper-ls.enable = true;
                      };

                      debugger = {
                        nvim-dap = {
                          enable = true;
                          ui.enable = true;
                        };
                      };

                      # This section does not include a comprehensive list of available language modules.
                      # To list all available language module options, please visit the nvf manual.
                      languages = {
                        enableFormat = true;
                        enableTreesitter = true;
                        enableExtraDiagnostics = true;

                        nix.enable = true;
                        markdown.enable = true;
                        bash.enable = true;
                        clang.enable = true;
                        css.enable = true;
                        html.enable = true;
                        json.enable = true;
                        sql.enable = true;
                        java.enable = true;
                        kotlin.enable = true;
                        ts.enable = true;
                        go.enable = true;
                        lua.enable = true;
                        python.enable = true;
                        typst.enable = true;
                        rust = {
                          enable = true;
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
                        nu.enable = true;
                        just.enable = false;
                      };

                      visuals = {
                        nvim-scrollbar.enable = false;
                        nvim-web-devicons.enable = true;
                        nvim-cursorline.enable = true;
                        cinnamon-nvim.enable = true;
                        fidget-nvim.enable = true;

                        highlight-undo.enable = true;
                        indent-blankline.enable = true;

                        # Fun
                        cellular-automaton.enable = true;
                      };

                      statusline = {
                        lualine = {
                          enable = true;
                          theme = "catppuccin";
                        };
                      };

                      theme = {
                        enable = true;
                        name = "catppuccin";
                        style = "mocha";
                        transparent = false;
                      };

                      autopairs.nvim-autopairs.enable = true;

                      autocomplete = {
                        nvim-cmp.enable = false;
                        blink-cmp.enable = true;
                      };

                      snippets.luasnip.enable = true;

                      filetree = {
                        neo-tree = {
                          enable = true;
                        };
                      };

                      tabline = {
                        nvimBufferline.enable = true;
                      };

                      treesitter.context.enable = true;

                      binds = {
                        whichKey.enable = true;
                        cheatsheet.enable = true;
                      };

                      telescope.enable = true;

                      git = {
                        enable = true;
                        gitsigns.enable = true;
                        gitsigns.codeActions.enable = false; # throws an annoying debug message
                        neogit.enable = true;
                      };

                      minimap = {
                        minimap-vim.enable = false;
                        codewindow.enable = true; # lighter, faster, and uses lua for configuration
                      };

                      dashboard = {
                        dashboard-nvim.enable = false;
                        alpha.enable = true;
                      };

                      notify = {
                        nvim-notify.enable = true;
                      };

                      projects = {
                        project-nvim.enable = true;
                      };

                      utility = {
                        ccc.enable = false;
                        vim-wakatime.enable = false;
                        diffview-nvim.enable = true;
                        yanky-nvim.enable = false;
                        qmk-nvim.enable = false; # requires hardware specific options
                        icon-picker.enable = true;
                        surround.enable = true;
                        leetcode-nvim.enable = true;
                        multicursors.enable = true;
                        smart-splits.enable = true;
                        undotree.enable = true;
                        nvim-biscuits.enable = true;

                        motion = {
                          hop.enable = false;
                          leap.enable = true;
                          precognition.enable = true;
                        };
                        images = {
                          image-nvim.enable = false;
                          img-clip.enable = true;
                        };
                      };

                      notes = {
                        obsidian.enable = true;
                        neorg.enable = false;
                        # True: Try out
                        orgmode.enable = false;
                        mind-nvim.enable = true;
                        todo-comments.enable = true;
                      };

                      terminal = {
                        toggleterm = {
                          enable = true;
                          lazygit.enable = true;
                        };
                      };

                      ui = {
                        borders.enable = true;
                        noice.enable = true;
                        colorizer.enable = true;
                        modes-nvim.enable = false; # the theme looks terrible with catppuccin
                        illuminate.enable = true;
                        breadcrumbs = {
                          enable = true;
                          navbuddy.enable = true;
                        };
                        smartcolumn = {
                          enable = true;
                          setupOpts.custom_colorcolumn = {
                            # this is a freeform module, it's `buftype = int;` for configuring column position
                            nix = "110";
                            ruby = "120";
                            java = "130";
                            go = [
                              "90"
                              "130"
                            ];
                          };
                        };
                        fastaction.enable = true;
                      };

                      assistant = {
                        chatgpt.enable = false;
                        copilot = {
                          enable = false;
                          cmp.enable = true;
                        };
                        codecompanion-nvim.enable = false;
                        avante-nvim.enable = true;
                      };
                      comments = {
                        comment-nvim.enable = true;
                      };

                      # TODO: Evaluate if we want these
                      session = {
                        nvim-session-manager.enable = false;
                      };
                      gestures = {
                        gesture-nvim.enable = false;
                      };
                      presence = {
                        neocord.enable = false;
                      };
                    };
                  }
                ];
              }).neovim;
            maximalPackage =
              (neovimConfiguration {
                inherit pkgs;
                modules = [
                  nvfMaximalFixes
                  (import "${inputs.nvf}/configuration.nix" true)
                ];
              }).neovim;
          };
      }
      (lib.mkIf config.myOptions.roles.gamedev.enable {
        programs.nvf.settings.vim = {
          treesitter.grammars = [
            pkgs.vimPlugins.nvim-treesitter-parsers.godot_resource
          ];
          # TODO: If we use godot setup the LSP
          # lazy.plugins.vim-godot = ;
        };
      })
    ]
  );
}

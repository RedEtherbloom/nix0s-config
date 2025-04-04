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
          # Replace with one character
          conceallevel = 1;
          # Potential good compromise
          foldlevelstart = 4;
          showmode = false;
          swapfile = true;
        };
        keymaps = [
          {
            mode = ["i"];
            key = "jj";
            action = "<Esc>";
            desc = "Exit insert mode";
            silent = true;
          }
          (mkKeymap "n" "<leader>fk" "<cmd>Telescope keymaps<CR>" {desc = "Open Telescopes built in keymap";})
          (mkKeymap "n" "<leader>oty" "<cmd>ObsidianYesterday<CR>" {desc = "Open yesterday's Obsidian note";})
          (mkKeymap "n" "<leader>otn" "<cmd>ObsidianToday<CR>" {desc = "Open today's Obsidian note";})
          (mkKeymap "n" "<leader>ott" "<cmd>ObsidianTomorrow<CR>" {desc = "Open tomorrow's Obsidian note";})
          (mkKeymap "n" "<leader>otp" "<cmd>ObsidianDailies<CR>" {desc = "Open a picker with the dailies of this week.";})
          (mkKeymap "n" "<leader>oto" "<cmd>ObsidianOpen<CR>" {desc = "Open current note in Obsidian window.";})
          (mkKeymap "n" "<leader>oq" "<cmd>ObsidianQuickSwitch<CR>" {desc = "Open Obsidian's Quick Switcher";})
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
        ];
        viAlias = true;
        vimAlias = true;
        searchCase = "smart";
        binds = {
          cheatsheet.enable = true;
          whichKey.enable = true;
        };

        # TODO: Look over other mini utilities(https://notashelf.github.io/nvf/options.html#opt-vim.mini.align.enable)
        mini = {
          surround.enable = true;
          # Disable too many lsp diagnostics
          notify.enable = true;
        };

        terminal.toggleterm = {
          enable = true;
          lazygit.enable = true;
        };
        session.nvim-session-manager.enable = true;
        snippets.luasnip.enable = true;
        # TODO: Look what noice does

        statusline.lualine.enable = true;
        # TODO: Are the buf outlines supposed to look so weird?
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
        lsp = {
          enable = true;
          trouble.enable = true;
        };
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
            lsp.server = "nil";
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
                path = "${config.home.homeDirectory}/Documents/Obsidian/default";
                overrides = {
                  notes_dir = "00-Notes";
                };
              }
            ];
            daily_notes = {
              date_format = "%Y/%m/%d-%a+W%V";
              folder = "01-Tracking/Daily";
              template = "02-Templates/Day.md";
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
          };
        };
        # TODO: Setup local or with Mistral
        # TODO: Enable after texlab has been merged
        # assistant.codecompanion-nvim.enable = true;
      };
    };
  };
}

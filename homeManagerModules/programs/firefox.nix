{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.myOptions.firefox;
  # Map each alias to a version with @ prepended and : appended
  defineAliasVariants = baseAlias: (lib.lists.concatMap (x: [
      ("@" + x)
      (x + ":")
    ])
    baseAlias);
  iconRefreshInterval = 7 * 24 * 60 * 60 * 1000;
in {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  options.myOptions.firefox = {
    enable = lib.mkOption {
      description = "Enable firefox";
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;
      languagePacks = [
        "en-US"
        "de"
      ];
      profiles = {
        default = {
          search = {
            enable = true;
            force = true;

            engines = {
              # TODO: Export to vimium shortcuts
              "NixPkgs(Unstable)" = {
                definedAliases = defineAliasVariants [
                  "nix"
                  "nixpkgs"
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        # Optional
                        name = "type";
                        value = "packages";
                      }
                    ];
                  }
                ];
              };
              "Nixpkgs source search" = {
                definedAliases = defineAliasVariants ["nis"];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                urls = [
                  {
                    template = "https://github.com/search";
                    params = [
                      {
                        name = "type";
                        value = "code";
                      }
                      {
                        name = "q";
                        value = "repo:NixOS/nixpkgs {searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "NixOS Options(Unstable)" = {
                definedAliases = defineAliasVariants [
                  "no"
                  "nopt"
                  "nixopt"
                  "nix-options"
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "NixOS Wiki" = {
                definedAliases = defineAliasVariants [
                  "nw"
                  "nixwiki"
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                urls = [
                  {
                    template = "https://wiki.nixos.org/w/index.php";
                    params = [
                      {
                        name = "search";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "NixOS Issues" = {
                definedAliases = defineAliasVariants [
                  "nixi"
                  "nix-issues"
                ];
                # icon = "";
                urls = [
                  {
                    template = "https://github.com/NixOS/nixpkgs/issues?q=is:issue {searchTerms}";
                  }
                ];
              };
              "NixOS PRs" = {
                definedAliases = defineAliasVariants [
                  "nixp"
                  "nix-pr"
                ];
                # icon = "";
                urls = [
                  {
                    template = "https://github.com/NixOS/nixpkgs/issues?q=is:pr {searchTerms}";
                  }
                ];
              };
              # TODO: Replace with ocofox
              "NixOS PR build status" = {
                definedAliases = defineAliasVariants [
                  "npr"
                  "nix-pr-status"
                ];
                # icon = "";
                urls = [
                  {
                    template = "https://nixpk.gs/pr-tracker.html";
                    params = [
                      {
                        name = "pr";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "NixOS Discourse search" = {
                definedAliases = defineAliasVariants [
                  "disc"
                  "discourse"
                ];
                # icon = "";
                urls = [
                  {
                    template = "https://discourse.nixos.org/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "Home-Manager Option(Unstable)" = {
                definedAliases = defineAliasVariants [
                  "hmo"
                  "hmoptions"
                ];
                icon = "https://home-manager-options.extranix.com/images/favicon.png";
                urls = [
                  {
                    template = "https://home-manager-options.extranix.com/";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                      {
                        name = "release";
                        value = "master";
                      }
                    ];
                  }
                ];
              };
              "Home-Manager Issues" = {
                definedAliases = defineAliasVariants [
                  "hmi"
                  "home-i"
                  "home-manager-issues"
                ];
                # icon = "";
                urls = [
                  {
                    template = "https://github.com/nix-community/home-manager/issues?q=is:issue {searchTerms}";
                  }
                ];
              };
              "Home-Manager PRs" = {
                definedAliases = defineAliasVariants [
                  "hmp"
                  "home-pr"
                  "home-manager-pr"
                ];
                # icon = "";
                urls = [
                  {
                    template = "https://github.com/nix-community/home-manager/issues?q=is:pr {searchTerms}";
                  }
                ];
              };
              "Go Pkgs" = {
                definedAliases = defineAliasVariants ["go"];
                icon = "https://pkg.go.dev/static/shared/icon/favicon.ico";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://pkg.go.dev/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "Noogle.dev" = {
                definedAliases = defineAliasVariants [
                  "noog"
                  "noogle"
                ];
                icon = "https://noogle.dev/favicon.png";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://noogle.dev/q";
                    params = [
                      {
                        name = "term";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              # Gemini does not have a simple search URL
              "dict.cc english" = {
                definedAliases = defineAliasVariants [
                  "dc"
                  "dict"
                ];
                icon = "https://www4.dict.cc/img/favicons/favicon4.png";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://www.dict.cc/";
                    params = [
                      {
                        name = "s";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "youtube" = {
                definedAliases = defineAliasVariants [
                  "youtube"
                  "yt"
                ];
                icon = "https://www.youtube.com/s/desktop/c01ea7e3/img/logos/favicon.ico";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://www.youtube.com/results";
                    params = [
                      {
                        name = "search_query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "duckduckgo" = {
                definedAliases = defineAliasVariants [
                  "dg"
                  "duckduckgo"
                ];
                icon = "https://duckduckgo.com/favicon.ico";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://duckduckgo.com/";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "reddit" = {
                definedAliases = defineAliasVariants [
                  "red"
                  "reddit"
                ];
                icon = "https://www.redditstatic.com/shreddit/assets/favicon/64x64.png";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://www.reddit.com/search/";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              "github" = {
                definedAliases = defineAliasVariants [
                  "gh"
                  "git"
                  "github"
                ];
                icon = "https://github.githubassets.com/favicons/favicon-dark.png";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://github.com/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              "amazon" = {
                definedAliases = defineAliasVariants [
                  "ama"
                  "amazon"
                ];
                icon = "https://www.amazon.de/favicon.ico";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://www.amazon.de/s";
                    params = [
                      {
                        name = "k";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              # General aggregated option search
              "mynixos" = {
                definedAliases = defineAliasVariants [
                  "mn"
                  "mynix"
                  "mynixos"
                ];
                icon = "https://mynixos.com/favicon.ico";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://mynixos.com/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "chatgpt" = {
                definedAliases = defineAliasVariants [
                  "ct"
                  "chat"
                  "chatgpt"
                ];
                icon = "https://cdn.oaistatic.com/assets/favicon-miwirzcw.ico";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://chatgpt.com";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              # TODO: Need kagi definition with search suggestion url
              "kagi" = {
                definedAliases = defineAliasVariants [
                  "k"
                  "kagi"
                ];
                icon = "https://kagi.com/favicon-16x16.png?v=2";
                updateInterval = iconRefreshInterval;
                urls = [
                  {
                    template = "https://kagi.com/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "bing".metaData.alias = "@bing";
              "google".metaData.alias = "@g";
            };
            default = "kagi";
            order = [
              "kagi"
              "google"
              "github"
              "duckduckgo"
              "youtube"
              "reddit"
            ];
          };
        };
      };
    };
  };
}

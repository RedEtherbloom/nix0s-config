{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.firefox;
in {
  options.myOptions.firefox = {
    enable = mkOption {
      description = "Enable firefox";
      type = with types; bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      languagePacks = [
        "en-US"
        "de"
      ];
    };
    programs.firefox.profiles."personal" = {
      id = 0;
      isDefault = true;
      extraConfig = lib.strings.concatLines [
        (builtins.readFile ../../dotfiles/firefox/betterfox.js)
        (builtins.readFile ../../dotfiles/firefox/media_decoding.js)
      ];
      search = {
        enable = true;

        # TODO: Add Icon settings
        engines = {
          "NixPkgs(Unstable)" = {
            definedAliases = ["@nix" "@nixpkgs"];
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
          "NixOS Options(Unstable)" = {
            definedAliases = ["@no" "@nopt" "@nixopt" "@nix-options"];
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
            definedAliases = ["@nw" "@nixwiki"];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            urls = [
              {
                template = "https://wiki.nixos.org/index.php";
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
            definedAliases = ["@ni" "@nixi" "@nix-issues"];
            # icon = "";
            urls = [
              {
                template = "https://github.com/NixOS/nixpkgs/issues?q=is:issue {searchTerms}";
              }
            ];
          };
          "NixOS PRs" = {
            definedAliases = ["@np" "@nixp" "@nix-pr"];
            # icon = "";
            urls = [
              {
                template = "https://github.com/NixOS/nixpkgs/issues?q=is:pr {searchTerms}";
              }
            ];
          };
          "NixOS PR build status" = {
            definedAliases = ["@npr" "@nix-pr-status"];
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
            definedAliases = ["@disc" "@discourse"];
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
            definedAliases = ["@hm" "@hmo" "@hmoptions"];
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
            definedAliases = ["@hmi" "@home-i" "@home-manager-issues"];
            # icon = "";
            urls = [
              {
                template = "https://github.com/nix-community/home-manager/issues?q=is:issue {searchTerms}";
              }
            ];
          };
          "Home-Manager PRs" = {
            definedAliases = ["@hmp" "@home-pr" "@home-manager-pr"];
            # icon = "";
            urls = [
              {
                template = "https://github.com/nix-community/home-manager/issues?q=is:pr {searchTerms}";
              }
            ];
          };
          "Go Pkgs" = {
            definedAliases = ["@go"];
            iconUpdateURL = "https://pkg.go.dev/static/shared/icon/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000; # every day
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

          "PerplexityAI" = {
            definedAliases = ["@p" "@per" "@perplexity"];
            iconUpdateURL = "https://www.perplexity.ai/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            urls = [
              {
                template = "https://www.perplexity.ai/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
          };
          # Gemini does not have a simple search URL
          "Dict.cc English" = {
            definedAliases = ["@dc" "@dict"];
            iconUpdateURL = "https://www4.dict.cc/img/favicons/favicon4.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
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
          "YouTube" = {
            definedAliases = ["@youtube" "@yt"];
            iconUpdateURL = "https://www.youtube.com/s/desktop/c01ea7e3/img/logos/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000; # every day
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
          "DuckDuckGo" = {
            definedAliases = ["@dg" "@duckduckgo"];
            iconUpdateURL = "https://duckduckgo.com/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000; # every day
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
          "Reddit" = {
            definedAliases = ["@red" "@reddit"];
            iconUpdateURL = "https://www.redditstatic.com/shreddit/assets/favicon/64x64.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
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
	  
          "GitHub" = {
            definedAliases = ["@git" "github"];
            iconUpdateURL = "https://github.githubassets.com/favicons/favicon-dark.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
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

          "Bing".metaData.alias = "@bing";
          "Google".metaData.alias = "@g";
        };
        default = "Google";
        order = [
          "Google"
          "PerplexityAI"
	  "GitHub"
          "DuckDuckGo"
          "YouTube"
          "Reddit"
        ];
        # Force it onto firefox and overwrite
        force = true;
      };
    };
    programs.firefox.profiles."i2p" = {
      id = 1;
      settings = {
        "media.peerConnection.ice.proxy_only" = true;
	# manual mode
        "network.proxy.type" = 1;
        "network.proxy.socks_version" = 5;
        "network.proxy.http" = "127.0.0.1";
        "network.proxy.http_port" = 4444;
        "network.proxy.ssl" = "127.0.0.1";
        "network.proxy.ssl_port" = 4444;
      };
      #TODO: Try out i2p for private browsing extension
    };
  };
}

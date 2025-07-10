{pkgs, ...}: let
  kscreen-filter-connected-outputs = pkgs.writeShellApplication {
    name = "kscreen-filter-connected-outputs";
    runtimeInputs = with pkgs; [
      kdePackages.libkscreen
      jq
    ];
    text = ''
      readarray -d " " -t COMMAND
      # Remove newlines
      COMMAND=("''${COMMAND[@]//$'\n'/}")

      CONNECTED_OUTPUTS=$(kscreen-doctor --json | jq '.outputs | map(select(.connected == true).name)')
      echo -n "''${COMMAND[@]}" | jq -s --argjson connected "$CONNECTED_OUTPUTS" --raw-input --slurp --raw-output 'split(" ") | .[0] as $base_command |  .[1:] as $output_commands | $output_commands | map(select(. as $el | any($connected[]; . as $output | $el | test(".+\\.\($output)\\..+")))) | {$base_command, present:., rejected:$output_commands-.}'
    '';
  };
  kscreen-execute-filtered-command = pkgs.writeShellApplication {
    name = "kscreen-execute-filtered-command";
    runtimeInputs = [kscreen-filter-connected-outputs];
    text = ''
      FILTERED="$(cat - | kscreen-filter-connected-outputs)"
      echo -n "$FILTERED" | jq '.rejected' | echo "Rejected: $(cat -)"
      eval "$(echo -n "$FILTERED" | jq --raw-output '[.base_command,.present] | flatten | @sh')"
    '';
  };
  define-kscreen-layout = baseName: text: hotkey: let
    name = "kscreen-layout-${baseName}";
  in {
    home.packages = [
      (pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = [
          pkgs.kdePackages.libkscreen
          kscreen-execute-filtered-command
        ];
        text = ''
          echo -n "kscreen-doctor ${text}" | kscreen-execute-filtered-command
        '';
      })
    ];
    programs.plasma.hotkeys.commands = {
      "${name}" = {
        command = name;
        keys = [hotkey];
        comment = "Home screen layout";
      };
    };
  };
in {
  inherit kscreen-filter-connected-outputs kscreen-execute-filtered-command define-kscreen-layout;
}

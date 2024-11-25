{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.taskwarrior;
in {
  options.myOptions.taskwarrior = {
    enable = mkOption {
      description = "Enable taskwarrior";
      type = types.bool;
      default = false;
    };
    enableSync = mkOption {
      description = "Enable taskwarrior sync with secrets";
      type = types.bool;
      default = true;
    };
    taskopen = mkOption {
      description = "Enable taskopen";
      type = types.bool;
      default = true;
    };
    vit = mkOption {
      description = "Enable vit";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      xdg.configFile."task/themes".source = ../../dotfiles/taskwarrior/themes;

      programs.taskwarrior = {
        enable = true;
        colorTheme = "${config.home.homeDirectory}/${
          config.xdg.configFile."task/themes".target
        }/dark-16-override";
        package = pkgs.taskwarrior3;
        config = {
          "weekstart" = "monday";
          "confirmation" = "yes";
          "regex" = "on";
          "search.case.sensitive" = "no";

          "urgency.inherit" = "1";
          "urgency.project.coefficient" = "0";
          "urgency.tags.coefficient" = "0";
          "urgency.annotations.coefficient" = "0";
          "urgency.scheduled.coefficient" = "5";
          "urgency.user.tag.next.coefficient" = "20";
          "uda.priority.values" = "H,M,,L";
          "urgency.uda.priority.L.coefficient" = "-5";
          "urgency.uda.priority.M.coefficient" = "3";
          "urgency.due.coefficient" = "15";
          # Done due to prio-L blocking tasks being to high
          "urgency.blocking.coefficient" = "6";

          # Remove page limit for default report view
          "report.next.filter" = "status:pending -WAITING";
          # Try a more focussed view
          # wtf, how did this duplicate shit
          #"report.next.filter" = "status:pending -WAITING scheduled.by:2w or due.by:2w";

          # Only the main client should do recurrence
          "recurrence" = lib.mkDefault "off";

          # Verbose
          # "report.next.labels"="ID,P,Sch,Due,Unt,Act,Age,Deps,Description,Tag,Project,Recur,Urg";
          # "report.next.columns"="id,priority,scheduled.relative,due.relative,until.remaining,start.age,entry.age,depends,description.truncated_count,tags,project,recur,urgency";

          "report.next.labels" = "ID,P,Sch,Due,Act,Age,Deps,Description,Tag,Project,Urg";
          "report.next.columns" = "id,priority,scheduled.relative,due.relative,start.age,entry.age,depends,description.truncated_count,tags,project,urgency";

          # Cassea: Hopefully prettier burndown
          "burndown.cumulative" = "0";

          "uda.reviewed.type" = "date";
          "uda.reviewed.label" = "Reviewed";
          "report._reviewed.description" = "Tasksh review report.  Adjust the filter to your needs.";
          "report._reviewed.columns" = "uuid";
          "report._reviewed.sort" = "reviewed+,modified+";
          "report._reviewed.filter" = "( reviewed.none: or reviewed.before:now-6days ) and ( +PENDING or +WAITING )";
          "uda.blocks.type" = "string";
          "uda.blocks.label" = "Blocks";
          "uda.blocked.type" = "string";
          "uda.blocked.label" = "Blocked";

          "context.Next_2_weeks.read" = "(scheduled.by:2w or due.by:2w)";
          "context.Next_2_weeks.write" = "due:2w";
          "context.Easy🦿.read" = "+last_mile or +easy";
          "context.Easy🦿.write" = "+easy";
          "context.Hard🧠.read" = "+hard or +dry or +draining";
          "context.Hard🧠.write" = "+hard";
          "context.Fun.read" = "+fun or +infotainment or +entertainment or +video_game or +movie or +novel or +anime or +cartoon";
          "context.Fun.write" = "+fun";
          "context.Transition.read" = "project:transition";
          "context.Transition.write" = "project:transition";
          "context.home.read" = "+home";
          "context.home.write" = "+home";
          "context.hackerspace.read" = "+entropia or +rzl";
          "context.hackerspace.write" = "+entropia";
          "context.system.read" = "+headmate or +system or +system_fight or +system_work or +system_organization";
          "context.system.write" = "+system";
          "context.transport.read" = "+transport";
          "context.transport.write" = "+transport";
          "context.shop.read" = "+shopping or +buy";
          "context.shop.write" = "+shopping";
          "context.to_plan.read" = "+to_schedule or +to_plan";
          "context.to_plan.write" = "+to_schedule";
        };
      };
    }
    (mkIf cfg.enableSync {
      services.taskwarrior-sync = {
        enable = true;
        package = pkgs.taskwarrior3;
      };
      programs.taskwarrior.extraConfig = ''
        include ${osConfig.sops.templates."taskwarrior-sync.rc".path}
      '';
    })
    (mkIf cfg.taskopen {home.packages = [pkgs.taskopen];})
    (mkIf cfg.vit {
      home.packages = with pkgs; [
        (callPackage vit.override {taskwarrior2 = pkgs.taskwarrior3;})
      ];
    })
  ]);
}

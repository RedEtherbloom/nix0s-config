{
  config,
  osConfig,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    taskopen
  ];

  xdg.configFile."task/taskwarrior-tui.rc" = {
    source = ../../dotfiles/taskwarrior/taskwarrior-tui.rc;
  };
  xdg.configFile."task/themes" = {
    source = ../../dotfiles/taskwarrior/themes;
  };

  services.taskwarrior-sync = {
    enable = true;
    package = pkgs.taskwarrior3;
  };

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
      "recurrence" = "off";

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

      # TODO: Move to end of taskrc so that it becomes mutable. But then I'll have to somehow link .taskrc back to the dotfiles...
      "context.Due.read" = "+DUE or +OVERDUE";
      # Better or worse?
      #"context.Due.read" = "due:today";
      "context.Easy🦿.read" = "+last_mile or +easy";
      "context.Easy🦿.write" = "+easy";
      "context.Hard🧠.read" = "+hard or +dry or +draining";
      "context.Hard🧠.write" = "+hard";
      "context.transition.read" = "project:transition";
      "context.transition.write" = "project:transition";
      "context.home.read" = "+home";
      "context.home.write" = "+home";
      "context.entropia.read" = "+entropia";
      "context.entropia.write" = "+entropia";
      "context.system.read" = "+headmate or +system or +system_fight or +system_work or +system_organization";
      "context.all_tasks.read" = "(status:waiting or status:pending) all";
      "context.all_tasks.write" = "(status:waiting or status:pending) all";
      "context.transport.read" = "+transport";
      "context.transport.write" = "+transport";
      "context.shop💴.read" = "+shopping or +buy";
      "context.shop💴.write" = "+shopping";
      "context.system.write" = "+system";
      "context.to_plan🕛.read" = "+to_schedule or +to_plan";
      "context.to_plan🕛.write" = "+to_schedule";
      "context.Fun.read" = "+fun or +infotainment or +entertainment or +video_game or +movie or +novel or +anime or +cartoon";
      "context.Fun.write" = "+fun";
    };
    extraConfig = ''
      include ${osConfig.sops.templates."taskwarrior-sync.rc".path}
      include ${config.home.homeDirectory}/${config.xdg.configFile."task/taskwarrior-tui.rc".target}
    '';
  };
}

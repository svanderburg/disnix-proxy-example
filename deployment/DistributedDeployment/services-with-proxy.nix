{ system, distribution, invDistribution, pkgs
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager ? "systemd"
}:

let
  customPkgs = import ../top-level/all-packages.nix {
    inherit system pkgs stateDir logDir runtimeDir tmpDir forceDisableUserChange processManager;
  };
  portsConfiguration = if builtins.pathExists ./ports.nix then import ./ports.nix else {};

  processType =
    if processManager == null then "managed-process"
    else if processManager == "sysvinit" then "sysvinit-script"
    else if processManager == "systemd" then "systemd-unit"
    else if processManager == "supervisord" then "supervisord-program"
    else if processManager == "bsdrc" then "bsdrc-script"
    else if processManager == "cygrunsrv" then "cygrunsrv-service"
    else if processManager == "launchd" then "launchd-daemon"
    else throw "Unknown process manager: ${processManager}";
in
rec {
  hello_world_server = rec {
    name = "hello_world_server";
    pkg = customPkgs.hello_world_server { inherit port; };
    port = portsConfiguration.ports.hello_world_server or 0;
    portAssign = "shared";
    type = processType;
  };

  hello_world_client = {
    name = "hello_world_client";
    pkg = customPkgs.hello_world_client;
    dependsOn = {
      hello_world_server = disnix_tcp_proxy;
    };
    type = "package";
  };

  disnix_tcp_proxy = rec {
    name = "disnix_tcp_proxy";
    pkg = customPkgs.disnix_tcp_proxy { inherit port processType; };
    port = portsConfiguration.ports.disnix_tcp_proxy or 0;
    portAssign = "shared";
    dependsOn = {
      inherit hello_world_server;
    };
    type = "wrapper";
  };
}

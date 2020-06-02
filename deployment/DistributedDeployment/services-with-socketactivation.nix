{ system, distribution, invDistribution, pkgs
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
}:

let
  customPkgs = import ../top-level/all-packages.nix {
    inherit system pkgs stateDir logDir runtimeDir tmpDir forceDisableUserChange;
    processManager = "systemd"; # Harcoded systemd, because nothing in this example will work with another process manager
  };
  portsConfiguration = if builtins.pathExists ./ports.nix then import ./ports.nix else {};
in
rec {
  hello_world_server = rec {
    name = "hello_world_server";
    pkg = customPkgs.hello_world_server {
      inherit port;
      enableSystemdSocketActivation = true;
    };
    port = portsConfiguration.ports.hello_world_server or 0;
    portAssign = "shared";
    type = "systemd-unit";
  };
  
  hello_world_client = {
    name = "hello_world_client";
    pkg = customPkgs.hello_world_client;
    dependsOn = {
      inherit hello_world_server;
    };
    type = "package";
  };
}

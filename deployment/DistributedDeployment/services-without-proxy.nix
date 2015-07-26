{system, distribution, pkgs}:

let
  customPkgs = import ../top-level/all-packages.nix { inherit system pkgs; };
  portsConfiguration = if builtins.pathExists ./ports.nix then import ./ports.nix else {};
in
rec {
  hello_world_server = rec {
    name = "hello_world_server";
    pkg = customPkgs.hello_world_server { inherit port; };
    port = portsConfiguration.ports.hello_world_server or 0;
    portAssign = "shared";
    type = "wrapper";
  };
  
  hello_world_client = {
    name = "hello_world_client";
    pkg = customPkgs.hello_world_client;
    dependsOn = {
      inherit hello_world_server;
    };
    type = "echo";
  };
}

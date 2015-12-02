{system, distribution, invDistribution, pkgs}:

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
    type = "process";
  };
  
  hello_world_client = {
    name = "hello_world_client";
    pkg = customPkgs.hello_world_client;
    dependsOn = {
      hello_world_server = disnix_tcp_proxy;
    };
    type = "echo";
  };
  
  disnix_tcp_proxy = rec {
    name = "disnix_tcp_proxy";
    pkg = customPkgs.disnix_tcp_proxy { inherit port; };
    port = portsConfiguration.ports.disnix_tcp_proxy or 0;
    portAssign = "shared";
    dependsOn = {
      inherit hello_world_server;
    };
    type = "wrapper";
  };
}

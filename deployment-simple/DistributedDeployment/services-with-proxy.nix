{ system, distribution, invDistribution, pkgs
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
}:

let
  customPkgs = import ../top-level/all-packages.nix {
    inherit system pkgs runtimeDir;
  };

  ids = if builtins.pathExists ./ids.nix then (import ./ids.nix).ids else {};
in
rec {
  hello_world_server = rec {
    name = "hello_world_server";
    port = ids.ports.hello_world_server or 0;
    pkg = customPkgs.hello_world_server { inherit port; };
    type = "process";
    requiresUniqueIdsFor = [ "ports" ];
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
    port = ids.ports.disnix_tcp_proxy or 0;
    pkg = customPkgs.disnix_tcp_proxy { inherit port; };
    dependsOn = {
      inherit hello_world_server;
    };
    type = "wrapper";
    requiresUniqueIdsFor = [ "ports" ];
  };
}

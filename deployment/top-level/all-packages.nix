{system, pkgs}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // self);

  self = {
    disnix_tcp_proxy = callPackage ../pkgs/disnix-tcp-proxy { };
    
    hello_world_server = callPackage ../pkgs/hello-world-server { };
    
    hello_world_client = callPackage ../pkgs/hello-world-client { };
  };
in
self

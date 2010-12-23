{system, distribution, pkgs}:

let customPkgs = import ../top-level/all-packages.nix { inherit system pkgs; };
in
rec {
  hello_world_server = rec {
    name = "hello_world_server";
    pkg = customPkgs.hello_world_server { inherit port; };
    port = 5000;
    type = "wrapper";
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
    port = 6000;
    dependsOn = {
      inherit hello_world_server;
    };
    type = "wrapper";
  };
}

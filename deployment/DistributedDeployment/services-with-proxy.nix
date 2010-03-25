{system, distribution}:

let pkgs = import ../top-level/all-packages.nix { inherit system; };
in
rec {
  hello_world_server = rec {
    name = "hello_world_server";
    pkg = pkgs.hello_world_server { inherit port; };
    port = 5000;
    type = "wrapper";
  };
  
  hello_world_client = {
    name = "hello_world_client";
    pkg = pkgs.hello_world_client;
    dependsOn = {
      hello_world_server = disnix_tcp_proxy;
    };
    type = "echo";
  };
  
  disnix_tcp_proxy = rec {
    name = "disnix_tcp_proxy";
    pkg = pkgs.disnix_tcp_proxy { inherit port; };
    port = 6000;
    dependsOn = {
      inherit hello_world_server;
    };
    type = "wrapper";
  };
}

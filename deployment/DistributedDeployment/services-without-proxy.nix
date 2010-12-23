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
      inherit hello_world_server;
    };
    type = "echo";
  };  
}

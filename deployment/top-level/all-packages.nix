{system}:

let pkgs = import (builtins.getEnv "NIXPKGS_ALL") { inherit system; };
in
with pkgs;

rec {
  disnix_tcp_proxy = import ../pkgs/disnix-tcp-proxy {
    inherit stdenv;
  };
  
  hello_world_server = import ../pkgs/hello-world-server {
    inherit stdenv;
  };
  
  hello_world_client = import ../pkgs/hello-world-client {
    inherit stdenv inetutils;
  };
}

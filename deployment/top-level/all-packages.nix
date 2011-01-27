{system, pkgs}:

rec {
  disnix_tcp_proxy = import ../pkgs/disnix-tcp-proxy {
    inherit (pkgs) stdenv;
  };
  
  hello_world_server = import ../pkgs/hello-world-server {
    inherit (pkgs) stdenv;
  };
  
  hello_world_client = import ../pkgs/hello-world-client {
    inherit (pkgs) stdenv inetutils;
  };
}

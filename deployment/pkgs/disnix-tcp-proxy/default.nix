{stdenv}:
{port}:
{hello_world_server}:

let 
  makeFlags = "PREFIX=$out srcPort=${toString port} destHostname=${hello_world_server.target.properties.hostname} destPort=${toString (hello_world_server.port)}";
in
stdenv.mkDerivation {
  name = "disnix-tcp-proxy";
  src = ../../../services/disnix-tcp-proxy;
  buildPhase = "make ${makeFlags}";
  installPhase = "make ${makeFlags} install";
}

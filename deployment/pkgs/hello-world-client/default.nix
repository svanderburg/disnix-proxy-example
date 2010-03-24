{stdenv}:
{hello_world_server}:

let makeFlags = "PREFIX=$out helloWorldHostname=${hello_world_server.target.hostname} helloWorldPort=${toString (hello_world_server.port)}";
in
stdenv.mkDerivation {
  name = "hello-world-client";
  src = ../../../services/hello-world-client;
  buildPhase = "make ${makeFlags}";
  installPhase = "make ${makeFlags} install";
}

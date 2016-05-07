{stdenv, inetutils}:
{hello_world_server}:

let makeFlags = "PREFIX=$out helloWorldHostname=${hello_world_server.target.properties.hostname} helloWorldPort=${toString (hello_world_server.port)} inetutils=${inetutils}";
in
stdenv.mkDerivation {
  name = "hello-world-client";
  src = ../../../services/hello-world-client;
  buildPhase = "make ${makeFlags}";
  installPhase = "make ${makeFlags} install";
}

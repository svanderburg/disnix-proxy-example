{stdenv}:
{port}:

let makeFlags = "PREFIX=$out port=${toString port}";
in
stdenv.mkDerivation {
  name = "hello-world-server";
  src = ../../../services/hello-world-server;
  buildPhase = "make ${makeFlags}";
  installPhase = "make ${makeFlags} install";
}

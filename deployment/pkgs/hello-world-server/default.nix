{stdenv, pkgconfig, systemd}:
{port, enableSystemdSocketActivation ? false}:

let
  makeFlags = "PREFIX=$out port=${toString port}${stdenv.lib.optionalString enableSystemdSocketActivation " SYSTEMD_SOCKET_ACTIVATION=1"}";
in
stdenv.mkDerivation {
  name = "hello-world-server";
  src = ../../../services/hello-world-server;
  buildPhase = "make ${makeFlags}";
  installPhase = "make ${makeFlags} install";
  buildInputs = if enableSystemdSocketActivation then [ pkgconfig systemd ] else [];
}

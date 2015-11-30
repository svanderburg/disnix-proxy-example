{stdenv, pkgconfig, systemd}:
{port, enableSystemdSocketActivation ? false}:

let
  makeFlags = "PREFIX=$out port=${toString port}${stdenv.lib.optionalString enableSystemdSocketActivation " SYSTEMD_SOCKET_ACTIVATION=1"}";
in
stdenv.mkDerivation {
  name = "hello-world-server";
  src = ../../../services/hello-world-server;
  buildInputs = if enableSystemdSocketActivation then [ pkgconfig systemd ] else [];
  buildPhase = "make ${makeFlags}";
  installPhase = ''
    make ${makeFlags} install
    ${stdenv.lib.optionalString enableSystemdSocketActivation ''
      mkdir -p $out/etc
      cat > $out/etc/socket <<EOF
      [Unit]
      Description=Server socket that the hello world services listens to
      
      [Socket]
      ListenStream=${toString port}
      EOF
    ''}
  '';
}

{stdenv, lib, createManagedProcess, pkgconfig, systemd}:
{port, enableSystemdSocketActivation ? false}:

let
  makeFlags = "PREFIX=$out${lib.optionalString enableSystemdSocketActivation " SYSTEMD_SOCKET_ACTIVATION=1"}";

  hello-world-service = stdenv.mkDerivation {
    name = "hello-world-server";
    src = ../../../services/hello-world-server;
    buildInputs = if enableSystemdSocketActivation then [ pkgconfig systemd ] else [];
    buildPhase = "make ${makeFlags}";
    installPhase = "make ${makeFlags} install";
  };
in
createManagedProcess {
  name = "hello-world-server";
  description = "Hello world server";
  foregroundProcess = "${hello-world-service}/bin/hello-world-server";
  args = [ (toString port) ];

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };

  postInstall = lib.optionalString enableSystemdSocketActivation ''
    servicePath=$(echo $out/etc/systemd/system/*.service)

    cat > $out/etc/systemd/system/$(basename $servicePath .service).socket <<EOF
    [Unit]
    Description=Hello world server socket

    [Socket]
    ListenStream=${toString port}
    EOF
  '';
}

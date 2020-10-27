{stdenv, daemon, runtimeDir}:
{port}:

let
  makeFlags = "PREFIX=$out";

  hello-world-service = stdenv.mkDerivation {
    name = "hello-world-server";
    src = ../../../services/hello-world-server;
    buildPhase = "make ${makeFlags}";
    installPhase = "make ${makeFlags} install";
  };
in
stdenv.mkDerivation {
  name = "hello-world-server";
  buildCommand = ''
    instanceName="hello-world-server-${toString port}"

    mkdir -p $out/bin
    cat > $out/bin/$instanceName <<EOF
    #! ${stdenv.shell} -e

    exec ${daemon}/bin/daemon --unsafe --pidfile ${runtimeDir}/$instanceName.pid -- ${hello-world-service}/bin/hello-world-server ${toString port}
    EOF
    chmod +x $out/bin/$instanceName
  '';
}

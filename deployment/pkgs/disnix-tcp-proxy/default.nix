{stdenv, createManagedProcess, dysnomia}:
{port, processType}:
{hello_world_server}:

let
  makeFlags = "PREFIX=$out";

  disnix-tcp-proxy = stdenv.mkDerivation {
    name = "disnix-tcp-proxy";
    src = ../../../services/disnix-tcp-proxy;
    buildPhase = "make ${makeFlags}";
    installPhase = "make ${makeFlags} install";
  };
in
createManagedProcess {
  name = "disnix-tcp-proxy";
  description = "Disnix TCP Proxy";
  foregroundProcess = "${disnix-tcp-proxy}/bin/disnix-tcp-proxy";
  args = [ (toString port) hello_world_server.target.properties.hostname (toString hello_world_server.port) "/tmp/disnix-tcp-proxy-${toString port}.lock" ];

  postInstall = ''
    mkdir -p $out/bin
    cat > $out/bin/wrapper <<EOF
#! ${stdenv.shell} -e

export PATH=${disnix-tcp-proxy}/bin:\$PATH

case "\$1" in
    lock)
        if [ -f /tmp/disnix-tcp-proxy-${toString port}.lock ]
        then
            exit 1
        else
            touch /tmp/disnix-tcp-proxy-${toString port}.lock

            if [ "\$(ps aux | grep disnix-tcp-proxy)" != "" ] # Only obtain a lock when the service is running
            then
                while [ "\$(disnix-tcp-proxy-client)" != "0" ]
                do
                    sleep 1
                done
            fi
        fi
        ;;
    unlock)
        rm -f /tmp/disnix-tcp-proxy-${toString port}.lock
        ;;
    *)
        ${dysnomia}/libexec/dysnomia/${processType} "\$1" "$out"
        ;;
esac
EOF
    chmod +x $out/bin/wrapper
  '';

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}

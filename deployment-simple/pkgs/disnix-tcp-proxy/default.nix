{stdenv, daemon, dysnomia, runtimeDir}:
{port}:
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
stdenv.mkDerivation {
  name = "disnix-tcp-proxy";
  buildCommand = ''
    mkdir -p $out/bin

    cat > $out/bin/disnix-tcp-proxy <<EOF
    #! ${stdenv.shell} -e

    exec ${daemon}/bin/daemon --unsafe --pidfile ${runtimeDir}/disnix-tcp-proxy.pid -- ${disnix-tcp-proxy}/bin/disnix-tcp-proxy ${toString port} ${hello_world_server.target.properties.hostname} ${toString hello_world_server.port} "/tmp/disnix-tcp-proxy-${toString port}.lock"
    EOF

    chmod +x $out/bin/disnix-tcp-proxy

    mkdir -p $out/etc/dysnomia/process
    cat > $out/etc/dysnomia/process/disnix-tcp-proxy <<EOF
    process=$out/bin/disnix-tcp-proxy
    EOF

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
            ${dysnomia}/libexec/dysnomia/process "\$1" "$out"
            ;;
    esac
    EOF
    chmod +x $out/bin/wrapper
  '';
}

{ system, pkgs
, stateDir
, logDir
, runtimeDir
, tmpDir
, forceDisableUserChange
, processManager
, nix-processmgmt
}:

let
  createManagedProcess = import "${nix-processmgmt}/nixproc/create-managed-process/universal/create-managed-process-universal.nix" {
    inherit pkgs stateDir runtimeDir logDir tmpDir forceDisableUserChange processManager;
  };

  callPackage = pkgs.lib.callPackageWith (pkgs // self);

  self = {
    disnix_tcp_proxy = callPackage ../pkgs/disnix-tcp-proxy {
      inherit createManagedProcess;
    };

    hello_world_server = callPackage ../pkgs/hello-world-server {
      inherit createManagedProcess;
    };

    hello_world_client = callPackage ../pkgs/hello-world-client { };
  };
in
self

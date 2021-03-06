{ nixpkgs ? <nixpkgs>
, disnix_proxy_example ? { outPath = ./.; rev = 1234; }
, nix-processmgmt ? { outPath = ../nix-processmgmt; rev = 1234; }
, officialRelease ? false
, systems ? [ "i686-linux" "x86_64-linux" ]
}:

let
  pkgs = import nixpkgs {};

  disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
    inherit nixpkgs;
  };

  version = builtins.readFile ./version;

  jobs = rec {
    tarball = disnixos.sourceTarball {
      name = "disnix-proxy-example-tarball";
      src = disnix_proxy_example;
      inherit officialRelease version;
    };

    builds =
      let
        extraParams = { inherit nix-processmgmt; };
      in
      {
        simple_without_proxy = pkgs.lib.genAttrs systems (system:
          let
            disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
              inherit nixpkgs system;
            };
          in
          disnixos.buildManifest {
            name = "disnix-proxy-example-without-proxy";
            inherit tarball version extraParams;
            servicesFile = "deployment-simple/DistributedDeployment/services-without-proxy.nix";
            networkFile = "deployment-simple/DistributedDeployment/network.nix";
            distributionFile = "deployment-simple/DistributedDeployment/distribution-without-proxy.nix";
          });

        simple_with_proxy = pkgs.lib.genAttrs systems (system:
          let
            disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
              inherit nixpkgs system;
            };
          in
          disnixos.buildManifest {
            name = "disnix-proxy-example-without-proxy";
            inherit tarball version extraParams;
            servicesFile = "deployment-simple/DistributedDeployment/services-with-proxy.nix";
            networkFile = "deployment-simple/DistributedDeployment/network.nix";
            distributionFile = "deployment-simple/DistributedDeployment/distribution-with-proxy.nix";
          });

        without_proxy = pkgs.lib.genAttrs systems (system:
          let
            disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
              inherit nixpkgs system;
            };
          in
          disnixos.buildManifest {
            name = "disnix-proxy-example-without-proxy";
            inherit tarball version extraParams;
            servicesFile = "deployment/DistributedDeployment/services-without-proxy.nix";
            networkFile = "deployment/DistributedDeployment/network.nix";
            distributionFile = "deployment/DistributedDeployment/distribution-without-proxy.nix";
          });

        with_proxy = pkgs.lib.genAttrs systems (system:
          let
            disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
              inherit nixpkgs system;
            };
          in
          disnixos.buildManifest {
            name = "disnix-proxy-example-with-proxy";
            inherit tarball version extraParams;
            servicesFile = "deployment/DistributedDeployment/services-with-proxy.nix";
            networkFile = "deployment/DistributedDeployment/network.nix";
            distributionFile = "deployment/DistributedDeployment/distribution-with-proxy.nix";
          });

        with_socketactivation = pkgs.lib.genAttrs systems (system:
          let
            disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
              inherit nixpkgs system;
            };
          in
          disnixos.buildManifest {
            name = "disnix-proxy-example-with-socketactivation";
            inherit tarball version extraParams;
            servicesFile = "deployment/DistributedDeployment/services-with-socketactivation.nix";
            networkFile = "deployment/DistributedDeployment/network.nix";
            distributionFile = "deployment/DistributedDeployment/distribution-without-proxy.nix";
          });
      };

    tests =
      let
        testScript = {manifest}: ''
          # Check whether a connection can be established between client and
          # server. This test should succeed.

          result = test2.succeed("sleep 10; (echo 'hello'; sleep 10) | hello-world-client")

          if "Hello world" in result:
              print("Output contains: Hello world!")
          else:
              raise Exception("Output should contain: Hello world!")
        '';
      in
      {
        simple_without_proxy =
          let
            manifest = builtins.getAttr (builtins.currentSystem) (builds.simple_without_proxy);
          in
          disnixos.disnixTest {
            name = "disnix-proxy-example-without-proxy-test";
            inherit tarball manifest;
            networkFile = "deployment-simple/DistributedDeployment/network.nix";
            testScript = testScript { inherit manifest; };
          };

        simple_with_proxy =
          let
            manifest = builtins.getAttr (builtins.currentSystem) (builds.simple_with_proxy);
          in
          disnixos.disnixTest {
            name = "disnix-proxy-example-with-proxy-test";
            inherit tarball manifest;
            networkFile = "deployment-simple/DistributedDeployment/network.nix";
            testScript = testScript { inherit manifest; };
          };

        without_proxy =
          let
            manifest = builtins.getAttr (builtins.currentSystem) (builds.without_proxy);
          in
          disnixos.disnixTest {
            name = "disnix-proxy-example-without-proxy-test";
            inherit tarball manifest;
            networkFile = "deployment/DistributedDeployment/network.nix";
            testScript = testScript { inherit manifest; };
          };

        with_proxy =
          let
            manifest = builtins.getAttr (builtins.currentSystem) (builds.with_proxy);
          in
          disnixos.disnixTest {
            name = "disnix-proxy-example-with-proxy-test";
            inherit tarball manifest;
            networkFile = "deployment/DistributedDeployment/network.nix";
            testScript = testScript { inherit manifest; };
          };

        with_socketactivation =
          let
            manifest = builtins.getAttr (builtins.currentSystem) (builds.with_socketactivation);
          in
          disnixos.disnixTest {
            name = "disnix-proxy-example-with-socketactivation-test";
            inherit tarball manifest;
            networkFile = "deployment/DistributedDeployment/network.nix";
            testScript = testScript { inherit manifest; };
          };
      };
    };
in
jobs

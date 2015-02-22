{ nixpkgs ? <nixpkgs>
, disnix_proxy_example ? {outPath = ./.; rev = 1234;}
, officialRelease ? false
, systems ? [ "i686-linux" "x86_64-linux" ]
}:

let
  pkgs = import nixpkgs {};
  
  jobs = rec {
    tarball =
      let
        disnixos = import "${((import /home/sander/Development/disnixos/release.nix) {}).build.x86_64-linux}/share/disnixos/testing.nix" {
          inherit nixpkgs;
        };
      in
      disnixos.sourceTarball {
        name = "disnix-proxy-example-tarball";
        version = builtins.readFile ./version;
        src = disnix_proxy_example;
        inherit officialRelease;
      };
    
    doc =
      pkgs.releaseTools.nixBuild {
        name = "disnix-proxy-example-doc";
        version = builtins.readFile ./version;
        src = tarball;
        buildInputs = [ pkgs.libxml2 pkgs.libxslt pkgs.dblatex pkgs.tetex ];
        
        buildPhase = ''
          cd doc
          make docbookrng=${pkgs.docbook5}/xml/rng/docbook docbookxsl=${pkgs.docbook5_xsl}/xml/xsl/docbook
        '';
        
        checkPhase = "true";
        
        installPhase = ''
          make DESTDIR=$out install
         
          echo "doc manual $out/share/doc/disnix-proxy-example/manual" >> $out/nix-support/hydra-build-products
        '';
      };
      
    builds =
      {
        without_proxy = pkgs.lib.genAttrs systems (system:
          let
            disnixos = import "${((import /home/sander/Development/disnixos/release.nix) {}).build.x86_64-linux}/share/disnixos/testing.nix" {
              inherit nixpkgs system;
            };
          in
          disnixos.buildManifest {
            name = "disnix-proxy-example-without-proxy";
            version = builtins.readFile ./version;
            inherit tarball;
            servicesFile = "deployment/DistributedDeployment/services-without-proxy.nix";
            networkFile = "deployment/DistributedDeployment/network.nix";
            distributionFile = "deployment/DistributedDeployment/distribution-without-proxy.nix";
          });
        
        with_proxy = pkgs.lib.genAttrs systems (system:
          let
            disnixos = import "${((import /home/sander/Development/disnixos/release.nix) {}).build.x86_64-linux}/share/disnixos/testing.nix" {
              inherit nixpkgs system;
            };
          in
          disnixos.buildManifest {
            name = "disnix-proxy-example-with-proxy";
            version = builtins.readFile ./version;
            inherit tarball;
            servicesFile = "deployment/DistributedDeployment/services-with-proxy.nix";
            networkFile = "deployment/DistributedDeployment/network.nix";
            distributionFile = "deployment/DistributedDeployment/distribution-with-proxy.nix";
          });
      };
    
    tests = 
      let
        disnixos = import "${((import /home/sander/Development/disnixos/release.nix) {}).build.x86_64-linux}/share/disnixos/testing.nix" {
          inherit nixpkgs;
        };
      in
      {
        without_proxy = 
          let
            manifest = builtins.getAttr (builtins.currentSystem) (builds.without_proxy);
          in
          disnixos.disnixTest {
            name = "disnix-proxy-example-without-proxy-test";
            inherit manifest tarball;
            networkFile = "deployment/DistributedDeployment/network.nix";
            testScript =
              ''
                # Check whether a connection can be established between client and
                # server. This test should succeed.
              
                my $hello_world_client = $test2->mustSucceed("${pkgs.libxslt}/bin/xsltproc ${./extractservices.xsl} ${manifest}/manifest.xml | grep hello-world-client");
                my $result = $test2->mustSucceed("(echo 'hello'; sleep 10) | ".substr($hello_world_client, 0, -1)."/bin/hello-world-client || exit 0");
              
                if ($result =~ /Hello world/) {
                    print "Output contains: Hello world!\n";
                } else {
                    die "Output should contain: Hello world!\n";
                }
              '';
          };
        
        with_proxy = 
          let
            manifest = builtins.getAttr (builtins.currentSystem) (builds.with_proxy);
          in
          disnixos.disnixTest {
            name = "disnix-proxy-example-with-proxy-test";
            inherit manifest tarball;
            networkFile = "deployment/DistributedDeployment/network.nix";
            testScript =
              ''
                # Check whether a connection can be established between client and
                # server. This test should succeed.
            
                my $hello_world_client = $test2->mustSucceed("${pkgs.libxslt}/bin/xsltproc ${./extractservices.xsl} ${manifest}/manifest.xml | grep hello-world-client");
                my $result = $test2->mustSucceed("(echo 'hello'; sleep 10) | ".substr($hello_world_client, 0, -1)."/bin/hello-world-client || exit 0");
            
                if ($result =~ /Hello world/) {
                    print "Output contains: Hello world!\n";
                } else {
                    die "Output should contain: Hello world!\n";
                }
              '';
          };
        };
    };
in
jobs

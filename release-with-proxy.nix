{ nixpkgs ? /etc/nixos/nixpkgs
, nixos ? /etc/nixos/nixos
}:

let
  
  jobs = rec {
    tarball =
      { disnix_proxy_example ? {outPath = ./.; rev = 1234;}
      , officialRelease ? false}:
    
      let
        pkgs = import nixpkgs {};
  
        disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
          inherit nixpkgs nixos;
        };
      in
      disnixos.sourceTarball {
        name = "disnix-proxy-example";
	version = builtins.readFile ./version;
	src = disnix_proxy_example;
        inherit officialRelease;
      };
      
    build =
      { tarball ? jobs.tarball {}
      , system ? "x86_64-linux"
      }:
      
      let
        pkgs = import nixpkgs { inherit system; };
  
        disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
          inherit nixpkgs nixos system;
        };
      in
      disnixos.buildManifest {
        name = "disnix-proxy-example";
	version = builtins.readFile ./version;
	inherit tarball;
	servicesFile = "deployment/DistributedDeployment/services-with-proxy.nix";
	networkFile = "deployment/DistributedDeployment/network.nix";
	distributionFile = "deployment/DistributedDeployment/distribution-with-proxy.nix";
      };
            
    tests = 

      let
        pkgs = import nixpkgs {};
  
        disnixos = import "${pkgs.disnixos}/share/disnixos/testing.nix" {
          inherit nixpkgs nixos;
        };
	
	manifest = build { system = "x86_64-linux"; };
      in
      disnixos.disnixTest {
        name = "disnix-proxy-example";
        tarball = tarball {};
        inherit manifest;
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
in
jobs

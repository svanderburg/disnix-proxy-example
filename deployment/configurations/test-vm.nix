{pkgs, ...}:

{
  services = {
    openssh = {
      enable = true;
    };
  };
  
  environment = {
    systemPackages = [
      pkgs.mc
      pkgs.subversion
    ];
  };
}

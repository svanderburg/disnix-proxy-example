{pkgs, ...}:

{
  services = {
    disnix = {
      enable = true;
    };
    
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

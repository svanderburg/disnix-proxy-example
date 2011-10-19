{pkgs, ...}:

{
  services = {
    openssh = {
      enable = true;
    };
    
    disnix = {
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

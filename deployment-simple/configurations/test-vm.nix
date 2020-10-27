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
  
  networking.firewall.enable = false;
  
  environment = {
    systemPackages = [
      pkgs.mc
      pkgs.subversion
    ];
  };
}

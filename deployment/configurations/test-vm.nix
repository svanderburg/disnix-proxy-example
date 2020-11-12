{pkgs, ...}:

{
  services = {
    disnix = {
      enable = true;
      enableProfilePath = true;
    };

    openssh = {
      enable = true;
    };
  };

  networking.firewall.enable = false;

  environment = {
    systemPackages = [
      pkgs.mc
    ];
  };
}

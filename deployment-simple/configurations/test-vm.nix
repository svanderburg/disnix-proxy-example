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

  dysnomia.enableLegacyModules = false;

  networking.firewall.enable = false;

  environment = {
    systemPackages = [
      pkgs.mc
    ];
  };
}

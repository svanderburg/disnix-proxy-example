{
  ports = {
    disnix_tcp_proxy = 3001;
    hello_world_server = 3002;
  };
  portConfiguration = {
    globalConfig = {
      lastPort = 3002;
      minPort = 3000;
      maxPort = 4000;
      servicesToPorts = {
        hello_world_server = 3002;
        disnix_tcp_proxy = 3001;
      };
    };
    targetConfigs = {
    };
  };
}

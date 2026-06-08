{ pkgs, config, inputs, ... }:
{
  imports = [
    inputs.cosmic.flakeModules.default
  ];

  configurations.nixos = {
    "laptop" = {
      system = "x86_64-linux";
      module = {
        sops.age.keyFile = "/etc/sudhalaptoptpm";
        sops.defaultSopsFile = "${inputs.self}/modules/machines/laptop/laptopsecrets.yaml";
        sops.secrets."sudhalaptopssh" = {
          path = "/etc/ssh/ssh_host_ed25519_key";
          mode = "0600";
          owner = "root";
        };
        imports = 
        with inputs.opinions.nixosModules; 
        with config.flake.nixosModules;    
        [ 
          laptop
          system
          plasma
          sudha
        ];
      }; 
    }; 
  };

  configurations.home = {
    "sudha@laptop" = {
      hostName = "laptop";
      modules = 
        with config.flake.homeModules;
        with inputs.opinions.homeModules; 
        [
          sudhacli
          sudhagui
          plasma
          helium-browser
        ];
    };
  }; 
}
flakeContext@{ inputs, ... }:
{
  imports = [
    inputs.cosmic.flakeModules.default
  ];

  configurations.nixos = {
    "laptop" = {
      system = "x86_64-linux";
      module = { config, ... }:{
        imports =   
        [ 
          inputs.sops-nix.nixosModules.sops
          flakeContext.config.flake.nixosModules.laptop-hardware
          flakeContext.config.flake.nixosModules.laptop-configuration
          inputs.opinions.nixosModules.plasma
          inputs.opinions.nixosModules.sudha-yggdrasil
        ];
        sops.age.keyFile = "/etc/${config.networking.hostName}boot.txt";
        sops.secrets."ssh/ssh_host_ed25519_key" = {
          sopsFile = "${inputs.self}/secrets/laptop.yaml";
          format = "yaml";
          path = "/etc/ssh/ssh_host_ed25519_key"; # This is the symlink location
        };
        # command to generate yggdrasil key
        # nix run nixpkgs#yggdrasil -- -useconffile <(yggdrasil -genconf -json) -exportkey
        sops.secrets."yggdrasil" = {
          sopsFile = "${inputs.self}/secrets/laptop.yaml";
          format = "yaml";
        };
        sops.secrets."syncthing_cert" = {
          sopsFile = "${inputs.self}/secrets/laptop.yaml";
          format = "yaml";
          owner = "root"; 
        };
        sops.secrets."syncthing_key" = {
          sopsFile = "${inputs.self}/secrets/laptop.yaml";
          format = "yaml";
          owner = "root";
        };
        # sops.secrets."git-access-tokens" = {
        #   sopsFile = "${inputs.self}/secrets/laptop.yaml"; 
        #   mode = "0440";
        #   owner = "root"; 
        #   group = "wheel";
        # };
    
        

        networking.hostName = "laptop";
        users.users.sudha = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" "dialout" "docker" "adbusers"];          
          # hashedPasswordFile = config.sops.secrets."sudha-login-password".path;
        };
      }; 
    }; 
  };

  # configurations.home = {
  #   "sudha@laptop" = {
  #     hostName = "laptop";
  #     modules = 
  #       with config.flake.homeModules;
  #       with inputs.opinions.homeModules; 
  #       [
  #         sudhacli
  #         sudhagui
  #         plasma
  #         helium-browser
  #       ];
  #   };
  # }; 
}


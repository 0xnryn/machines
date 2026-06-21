flakeContext@{ inputs, ... }:
{
  imports = [
    inputs.cosmic.flakeModules.default
  ];

  configurations.nixos = {
    "laptop" = {
      system = "x86_64-linux";
      module = { config, ... }:{
        networking.hostName = "laptop";
        imports =   
        [ 
          inputs.sops-nix.nixosModules.sops
          flakeContext.config.flake.nixosModules.laptop-hardware
          flakeContext.config.flake.nixosModules.laptop-configuration
          inputs.opinions.nixosModules.plasma
          inputs.opinions.nixosModules.sudha-yggdrasil
          # inputs.opinions.nixosModules.sudha-gnunet
        ];
        sops.age.keyFile = "/etc/${config.networking.hostName}boot.txt";
        sops.secrets."ssh/ssh_host_ed25519_key" = {
          sopsFile = "${inputs.self}/secrets/${config.networking.hostName}.yaml";
          format = "yaml";
          path = "/etc/ssh/ssh_host_ed25519_key"; # This is the symlink location
        };
        # command to generate yggdrasil key
        # nix run nixpkgs#yggdrasil -- -useconffile <(yggdrasil -genconf -json) -exportkey
        sops.secrets."yggdrasil" = {
          sopsFile = "${inputs.self}/secrets/${config.networking.hostName}.yaml";
          format = "yaml";
        };
        users.users.sudha = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" "dialout" "docker" "adbusers" ];          
          # hashedPasswordFile = config.sops.secrets."sudha-login-password".path;
        };
      }; 
    }; 
  };
}


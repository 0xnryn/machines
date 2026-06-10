{ pkgs, config, inputs, ... }:
{
  imports = [
    inputs.cosmic.flakeModules.default
  ];

  configurations.nixos = {
    "laptop" = {
      system = "x86_64-linux";
      module = {
        environment.variables = {
          EDITOR = "nano";
          VISUAL = "nano"; 
          SOPS_AGE_KEY_FILE = "/etc/laptopboot.txt"; 
        };
        sops.age.keyFile = "/etc/laptopboot.txt";
        # Explicitly tell sops-nix where to put the key and link it
        sops.secrets."ssh/ssh_host_ed25519_key" = {
          sopsFile = "${inputs.self}/secrets/laptop.yaml";
          format = "yaml";
          path = "/etc/ssh/ssh_host_ed25519_key"; # This is the symlink location
        };
        # sops.secrets."git-access-tokens" = {
        #   sopsFile = "${inputs.self}/modules/machines/laptop/laptopsecrets.yaml"; 
        #   mode = "0440";
        #   owner = "root"; 
        #   group = "wheel";
        # };
        # nix.extraOptions = ''
        #   !include /run/secrets/git-access-tokens
        # '';
        users.users.sudha = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" "dialout" ];          
          # hashedPasswordFile = config.sops.secrets."sudha-login-password".path;
        };
        imports = 
        with inputs.opinions.nixosModules; 
        with config.flake.nixosModules;    
        [ 
          laptop
          system
          plasma
          ollama_cuda
        ];
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


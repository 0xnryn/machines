# sudo EDITOR=nano SOPS_AGE_KEY_FILE=/etc/sudhalaptoptpm nix run nixpkgs#sops -- modules/users/sudha/secrets.yaml
{ pkgs, config, inputs, ... }:
{
  imports = [
    inputs.cosmic.flakeModules.default
  ];

  configurations.nixos = {
    "laptop" = {
      system = "x86_64-linux";
      module = {
        sops.secrets."git-access-tokens" = {
          sopsFile = "${inputs.self}/modules/machines/laptop/laptopsecrets.yaml"; 
          mode = "0440";
          owner = "root"; 
          group = "wheel";
        };
        nix.extraOptions = ''
          !include /run/secrets/git-access-tokens
        '';
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


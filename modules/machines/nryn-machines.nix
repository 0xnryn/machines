flakeContext@{ inputs, ... }:
{
  imports = [
    inputs.cosmic.flakeModules.default
  ];

  configurations.nixos = {
    "nryn-laptop" = {
      system = "x86_64-linux";
      module = { config, ... }:
      let
        hostName = "nryn-laptop";
      in
      {
        networking = {
          networkmanager.enable = true;
          inherit hostName;
        };
        imports =   
        [ 
          inputs.sops-nix.nixosModules.sops
          inputs.self.nixosModules."${hostName}-hardware"
          inputs.self.nixosModules."${hostName}-configuration"
          # flakeContext.config.flake.nixosModules.${hostName}-hardware
          # flakeContext.config.flake.nixosModules.${hostName}-configuration
          inputs.opinions.nixosModules.plasma
          inputs.opinions.nixosModules.sudha-yggdrasil
        ];
        sops.age.keyFile = "/etc/${hostName}-boot.txt";
        sops.secrets."ssh/ssh_host_ed25519_key" = {
          sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
          format = "yaml";
          path = "/etc/ssh/ssh_host_ed25519_key"; # This is the symlink location
        };
        # command to generate yggdrasil key
        # nix run nixpkgs#yggdrasil -- -useconffile <(yggdrasil -genconf -json) -exportkey
        sops.secrets."yggdrasil" = {
          sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
          format = "yaml";
        };
        # "sudha-user-password" = {
        #   sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
        #   format = "yaml";
        #   neededForUsers = true; # <-- ADD THIS TO BOTH MACHINES
        # };
        users.users.sudha = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" "dialout" "docker" "adbusers" ];          
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4TE/APdx0IU0wXNtmQaJK98Or3TwqRwEBS2bQNOpfO sudha"            
          ];
          # hashedPasswordFile = config.sops.secrets."sudha-user-password".path;
        };
      }; 
    };
  };
  configurations.nixos = {
    "nryn-server" = {
      system = "x86_64-linux";
      module = { config, pkgs, ... }:
      let
        hostName = "nryn-server";
      in
      {
        networking = {
          inherit hostName;
          networkmanager.enable = true;
          firewall.enable = true;
        };
        imports =   
        [ 
          inputs.sops-nix.nixosModules.sops
          inputs.self.nixosModules."${hostName}-hardware"
          inputs.self.nixosModules."${hostName}-configuration"
          # inputs.opinions.nixosModules.nryn-openwebui
        ];
        sops.age.keyFile = "/etc/${hostName}-boot.txt";
        sops.secrets = {
          "ssh/ssh_host_ed25519_key" = {
            sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
            format = "yaml";
            path = "/etc/ssh/ssh_host_ed25519_key"; # This is the symlink location
          };
          # command to generate yggdrasil key
          # nix run nixpkgs#yggdrasil -- -useconffile <(yggdrasil -genconf -json) -exportkey
          "yggdrasil" = {
            sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
            format = "yaml";
          };
          "cloudflare" = {
            sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
            format = "yaml";
            owner = config.users.users.cloudflared.name;
            group = config.users.groups.cloudflared.name;
          };
          "sudha-user-password" = {
            sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
            format = "yaml";
            neededForUsers = true; # <-- ADD THIS TO BOTH MACHINES
          };
        };

        users.users.sudha = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" "dialout" "docker" "adbusers" ];          
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4TE/APdx0IU0wXNtmQaJK98Or3TwqRwEBS2bQNOpfO sudha"            
          ];
          hashedPasswordFile = config.sops.secrets."sudha-user-password".path;
        };
        
        systemd.tmpfiles.rules = [
          # f = create a file if it doesn't exist
          # 0400 = Read-only for owner, nothing for others
          # root = owner
          # root = group
          "f /etc/${config.networking.hostName}-boot.txt 0400 root root -"
        ];
      }; 
    }; 
  };
 
  # configurations.nixondroid = {
  #   "phone" = {
  #     system = "aarch64-linux";
  #     module = { config, pkgs, ... }: {
  #       system.stateVersion = "24.05";
  #       environment.packages = with pkgs; [
  #         vim
  #         git
  #         curl
  #         htop
  #       ];    
  #       imports = [ inputs.sops-nix.nixosModules.sops ];
  #       sops = {
  #         defaultSopsFile = "${inputs.self}/secrets/phone.yaml";
  #         age.keyFile = "/data/data/com.termux.nix/files/home/.config/sops/age/keys.txt";
  #       };
  #       terminal.font = "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono.ttf";
  #     };
  #   };
  # }; 
}


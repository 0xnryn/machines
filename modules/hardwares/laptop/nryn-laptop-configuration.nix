{ ... }:
{
  flake.nixosModules.nryn-laptop-configuration = { pkgs, ... }: 
  {
    
    nix = {
      settings = { 
        experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
      };
      extraOptions = ''
        !include /run/secrets/git-access-tokens
      '';
    };
    nixpkgs.config.allowUnfree = true;
    programs.nix-ld.enable = true;
    system.stateVersion = "26.05";
    time.timeZone = "Asia/Kolkata";
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";
    virtualisation.docker.enable = true;
    # virtualisation.podman = {
    #   enable = true;
    #   dockerCompat = true; # You can still type 'docker run', it just uses podman securely
    # };
    services = {
      printing.enable = true;
      openssh.enable = true;
      pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        wireplumber.enable = true; 
      };
      avahi = {
        enable = true;
        nssmdns4 = true; 
      };
      ollama = {
        enable = true;
      };
      pcscd.enable = true;
    };
    
    environment.variables = {
      EDITOR = "nano"; VISUAL = "nano"; 
    };
    environment.systemPackages = with pkgs; [
      age age-plugin-tpm android-tools alfis-nogui alfis
      bind
      cloudflared curl
      droidcam docker
      git gptfdisk
      home-manager htop helix
      jq
      mtr
      pciutils
      ryzenadj
      sbctl sops ssh-to-age
      tcpdump tree
      util-linux unzip
      vim
      wget
      yggdrasil    
      zenmonitor 
    ];
    networking = {
      networkmanager.enable = true;
      firewall.enable = true;
    };
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
  };
}


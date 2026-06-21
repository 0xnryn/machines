    # command to generate yggdrasil key
    # nix run nixpkgs#yggdrasil -- -useconffile <(yggdrasil -genconf -json) -exportkey
    sops.secrets."yggdrasil" = {
      sopsFile = "${inputs.self}/secrets/laptop.yaml";
      format = "yaml";
    };

    users.users.sudha = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "dialout" "docker" "adbusers"];          
    };

    # ==========================================
    # 1. SOPS SECRETS DEFINITION
    # ==========================================
    sops.secrets."laptop" = {
      sopsFile = "${inputs.self}/secrets/laptop.yaml";
      format = "yaml";
      owner = "gnunet"; # <-- REQUIRED: Allows the GNUnet daemon to read the key in RAM
    };

    sops.secrets."erpnext" = {
      sopsFile = "${inputs.self}/secrets/laptop.yaml";
      format = "yaml";
      owner = "gnunet"; # <-- REQUIRED
    };

    # ==========================================
    # 2. GNUNET MULTI-TENANT CONFIGURATION
    # ==========================================
    cosmic.gnunet = {
      enable = true;          
      
      # Map the identity names to their decrypted SOPS paths
      identities = {
        "laptop" = config.sops.secrets."laptop".path;
        "erpnext" = config.sops.secrets."erpnext".path;
      };

      # Pure raw commands executed after Yggdrasil gets its IP
      zoneRecords = ''
        echo "Initializing GNS Records..."

        # --- LAPTOP IDENTITY ---
        # Claim the .sudha TLD locally
        gnunet-identity -d -e laptop -n sudha
        # Point laptop.sudha to the machine's Yggdrasil IP
        gnunet-namestore -z laptop -a -n "@" -t AAAA -d $YGG_IP -e never
        # Add a subdomain (www.laptop.sudha)
        gnunet-namestore -z laptop -a -n "www" -t CNAME -d laptop.sudha -e never

        # --- ERPNEXT IDENTITY ---
        # Claim the .erp TLD locally
        gnunet-identity -d -e erpnext -n erp
        # Point erpnext.erp to the machine's Yggdrasil IP
        gnunet-namestore -z erpnext -a -n "@" -t AAAA -d $YGG_IP -e never
      '';
    };
  }; 
}; 


};
}
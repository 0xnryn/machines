{ inputs, lib, ... }:
{
  flake.nixosModules.nryn-laptop-hardware = { pkgs, config, modulesPath,... }: {

    imports = [ 
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote # Inject Secure Boot framework
      (modulesPath + "/installer/scan/not-detected.nix") 
    ];
    
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    
    boot = {
      initrd.systemd.enable = true;      
      binfmt.emulatedSystems = [ "aarch64-linux" ];
      kernelPackages = pkgs.linuxPackages;
      extraModulePackages = [ config.boot.kernelPackages.zenpower ];
      kernelModules = [ "kvm-amd" "zenpower" ];
      initrd.luks.devices."enc".crypttabExtraOpts = [ 
        "tpm2-device=auto"
        "tpm2-pcrs=7" 
      ];
  
      loader.systemd-boot.enable = lib.mkForce false;
      loader.efi.canTouchEfiVariables = true;
  
      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
        autoGenerateKeys.enable = true; 
        autoEnrollKeys = {
          enable = true;
        };
      };
  
      kernelParams = [
        # "amdgpu.gttsize=16384"
        # "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      ];
  
      initrd.availableKernelModules = [ 
        "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" "tpm_crb" "tpm_tis" 
      ];
      initrd.kernelModules = [ ];
    };

    services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

    hardware = {

      bluetooth.enable = true;

      cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      cpu.amd.ryzen-smu.enable = true;
      
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      
      nvidia = {
        modesetting.enable = true;
        open = false;
        powerManagement.enable = true;
        powerManagement.finegrained = true;
        dynamicBoost.enable = true;
        nvidiaSettings = true;        
        package = config.boot.kernelPackages.nvidiaPackages.beta;
        prime = {
          offload.enable = true;
          offload.enableOffloadCmd = true;
          amdgpuBusId = "PCI:5:0:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };

    disko.devices = {
      disk = {
        main = {
          device = lib.mkDefault "/dev/nvme0n1"; 
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "enc"; 
                  settings = {
                    allowDiscards = true; # Crucial for NVMe SSD health (TRIM)
                  };
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
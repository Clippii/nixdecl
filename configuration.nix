# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

let
  hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  programs.appimage.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  security.polkit.enable = true;

  # CachyOS-inspired kernel — better for Ryzen + gaming
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Ryzen 9 9950X3D kernel params
  boot.kernelParams = [
    "amd_pstate=active"       # AMD P-state driver for better CPU perf
    "quiet"
    "splash"
  ];

  networking.hostName = "PuppyDesktop";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # ── Display / greeter ─────────────────────────────────────────────────────
  services.displayManager.sddm.enable = false;
  services.xserver.enable = false;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${hyprlandPkg}/bin/Hyprland";
        user = "clippi";
      };
    };
  };

  console.keyMap = "uk";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # ── NVIDIA RTX 4070 ───────────────────────────────────────────────────────
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;                          # proprietary — more stable for gaming
    nvidiaSettings = true;
    powerManagement.enable = false;        # desktop, no need
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;                    # needed for Steam + Proton
  };

  # ── Gaming ────────────────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;        # gamescope compositor for better perf
    extraCompatPackages = with pkgs; [
      proton-ge-bin                        # GE-Proton for better game compat
    ];
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # ── Audio via pipewire ────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;                    # useful for low-latency audio
  };

  services.printing.enable = true;
  services.seatd.enable = true;
  services.gvfs.enable = true;

  # ── User ──────────────────────────────────────────────────────────────────
  users.users.clippi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "gamemode" ];
    packages = with pkgs; [
      tree
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Hyprland ──────────────────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    package = hyprlandPkg;
    xwayland.enable = true;
  };

  environment.pathsToLink = [ "/share/icons" ];

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # ── Apps (carried over from laptop) ──
    (discord.override {
      withOpenASAR = false;
      withVencord = true;
    })
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    })
    zip
    mpv
    p7zip
    cava
    unzip
    catppuccin-cursors
    parted
    efibootmgr
    libnotify
    wget
    git
    code-cursor
    spotify
    jq
    inputs.matugen.packages.${stdenv.hostPlatform.system}.default
    grimblast
    rustc
    python3
    bun
    kitty
    fd
    cbonsai
    nautilus
    bat
    docker
    tree
    ripgrep
    curl
    btop
    swaynotificationcenter
    swww
    matugen
    zsh
    wireplumber
    grim
    slurp
    wf-recorder
    pamixer
    playerctl
    psmisc
    hyprpicker
    gnome-disk-utility
    neovim
    waybar
    rofi
    hyprpaper
    hypridle
    hyprlock
    wl-clipboard
    lxappearance
    nwg-look
    papirus-icon-theme
    bibata-cursors
    dunst
    lf
    pavucontrol
    bluez
    blueman
    protonmail-desktop
    protonvpn-gui
    fastfetch

    # ── Gaming ──
    mangohud                               # in-game overlay (FPS, temps, etc)
    lutris                                 # non-Steam games / GOG / Epic
    heroic                                 # Epic / GOG native launcher
    bottles                                # Wine manager
    winetricks
    wine-staging
    vulkan-tools
    vulkan-loader
    libvdpau-va-gl

    # ── Desktop-specific (no laptop battery stuff needed) ──
    nvtopPackages.nvidia                   # GPU monitor
    lm_sensors                             # CPU/mobo temps
    pciutils
    usbutils
  ];

  # ── Fonts ─────────────────────────────────────────────────────────────────
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];
  };

  # ── Environment variables ─────────────────────────────────────────────────
  environment.variables = {
    XCURSOR_THEME = "catppuccin-frappe-rosewater-cursors";
    XCURSOR_SIZE = "24";

    # NVIDIA + Wayland
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
    __NV_PRIME_RENDER_OFFLOAD = "1";

    # Wayland
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";             # Firefox/Edge native Wayland
  };

  system.stateVersion = "25.11";
}

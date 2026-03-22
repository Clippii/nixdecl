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

  # Zen kernel — good all-rounder for ThinkPad T14s
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Intel Iris Xe (Tiger Lake i7-1165G7) kernel params
  boot.kernelParams = [
    "i915.enable_fbc=1"       # framebuffer compression — saves power on battery
    "i915.enable_psr=2"       # panel self-refresh (PSR2 supported on Xe)
    "i915.enable_guc=3"       # enable GuC + HuC firmware (better power + perf on Xe)
    "quiet"
    "splash"
  ];

  networking.hostName = "PuppyBox";
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

  # ── Intel Iris Xe Graphics (Tiger Lake) ──────────────────────────────────
  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;                    # needed for Steam + Proton
    extraPackages = with pkgs; [
      intel-media-driver                   # iHD VAAPI driver — required for Xe
      intel-compute-runtime                # OpenCL via NEO (Xe supported)
      libva-vdpau-driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
    ];
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
      # Intel integrated GPU — no vendor-specific perf levels available
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

  # ── Power management (laptop) ─────────────────────────────────────────────
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };
  services.power-profiles-daemon.enable = false; # conflicts with TLP

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
    microsoft-edge
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

    # ── Laptop / ThinkPad T14s ──
    nvtopPackages.intel                    # GPU monitor (Intel)
    lm_sensors                             # CPU/mobo temps
    powertop                               # battery usage analysis
    tlp                                    # power management daemon
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

    # Intel Iris Xe VAAPI
    LIBVA_DRIVER_NAME = "iHD";             # intel-media-driver (required for Xe)
    VDPAU_DRIVER = "va_gl";

    # Wayland
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";             # Firefox/Edge native Wayland
  };

  system.stateVersion = "26.05";
}

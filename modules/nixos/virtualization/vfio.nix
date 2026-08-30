{
  pkgs,
  config,
  lib,
  ...
}:

let
  physicalKeyboard = "/dev/input/by-id/usb-Lenovo_Lenovo_Traditional_USB_Keyboard-event-kbd";
  physicalMouse = "/dev/input/by-id/usb-Logitech_USB_Receiver-event-mouse";

  # evsieve's control FIFO lets the libvirt lifecycle hook reset the routing
  # state without restarting evsieve (which would recreate the uinput nodes
  # and invalidate libvirt's device ACLs).
  evsieve = pkgs.evsieve.overrideAttrs (_: {
    cargoBuildFeatures = [ "control-fifo" ];
  });
  evsieveControlFifo = "/run/evsieve-vfio-input/control";
  evsieveGuestStateDir = "/run/evsieve-vfio-input/guests";

  hostKeyboard = "/dev/input/by-id/evsieve-host-keyboard";
  hostMouse = "/dev/input/by-id/evsieve-host-mouse";
  guestKeyboard = "/dev/input/by-id/evsieve-guest-keyboard";
  guestMouse = "/dev/input/by-id/evsieve-guest-mouse";

  evsieveQemuHook = pkgs.writeShellScript "evsieve-vfio-qemu-hook" ''
    set -eu

    domain="''${1:-}"
    operation="''${2:-}"
    phase="''${3:-}"
    stateDir="${evsieveGuestStateDir}"
    fifo="${evsieveControlFifo}"

    # Only VMs that actually use the evsieve guest links participate in this
    # lifecycle bookkeeping. This deliberately leaves manually-managed VMs
    # (such as win10-school) untouched.
    xml="$(${pkgs.coreutils}/bin/cat)"
    case "$xml" in
      *evsieve-guest-keyboard*|*evsieve-guest-mouse*) ;;
      *) exit 0 ;;
    esac

    ${pkgs.coreutils}/bin/mkdir -p "$stateDir"
    exec 9>"$stateDir/.lock"
    ${pkgs.util-linux}/bin/flock -x 9

    domainKey="$(${pkgs.coreutils}/bin/printf '%s' "$domain" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d ' ' -f 1)"
    stateFile="$stateDir/$domainKey"

    resetToHost() {
      # A missing FIFO means evsieve is not running. The hook must remain
      # successful so a VM shutdown/start is never blocked by input routing.
      if [ -p "$fifo" ]; then
        ${pkgs.coreutils}/bin/printf '%s\n' \
          'toggle keyboard-toggle:1' \
          'toggle mouse-toggle:1' > "$fifo" || true
      fi
    }

    hasActiveGuest() {
      [ -n "$(${pkgs.findutils}/bin/find "$stateDir" -maxdepth 1 -type f ! -name '.lock' -print -quit)" ]
    }

    case "$operation:$phase" in
      start:begin|reconnect:begin)
        # If no other evsieve VM is active, force a clean host baseline before
        # marking this VM active. This also recovers from a missed release
        # callback without touching an already-running guest.
        if ! hasActiveGuest; then
          resetToHost
        fi
        : > "$stateFile"
        ;;
      release:end)
        ${pkgs.coreutils}/bin/rm -f "$stateFile"
        # Reset only after the last evsieve-managed VM has released its guest
        # devices; another running guest keeps the current routing untouched.
        if ! hasActiveGuest; then
          resetToHost
        fi
        ;;
    esac

    exit 0
  '';

  evsieveArgs = [
    "${evsieve}/bin/evsieve"
    "--control-fifo"
    evsieveControlFifo
    "--input"
    physicalKeyboard
    "domain=keyboard"
    "grab=auto"
    "persist=reopen"
    "--input"
    physicalMouse
    "domain=mouse"
    "grab=auto"
    "persist=reopen"
    # Start on the host. Ctrl-L + Ctrl-R toggles keyboard and mouse together.
    "--hook"
    "key:leftctrl"
    "key:rightctrl"
    "toggle"
    "period=0.5"
    "breaks-on=key::1"
    "--withhold"
    "key:leftctrl"
    "key:rightctrl"
    "--toggle"
    "@keyboard"
    "@host-keyboard"
    "@guest-keyboard"
    "id=keyboard-toggle"
    "--toggle"
    "@mouse"
    "@host-mouse"
    "@guest-mouse"
    "id=mouse-toggle"
    "--output"
    "@host-keyboard"
    "create-link=${hostKeyboard}"
    "name=evsieve-host-keyboard"
    "--output"
    "@host-mouse"
    "create-link=${hostMouse}"
    "name=evsieve-host-mouse"
    "--output"
    "@guest-keyboard"
    "create-link=${guestKeyboard}"
    "name=evsieve-guest-keyboard"
    "--output"
    "@guest-mouse"
    "create-link=${guestMouse}"
    "name=evsieve-guest-mouse"
  ];
in

{
  virtualisation.libvirtd = {
    qemu = {
      verbatimConfig = ''
        cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
            "/dev/rtc", "/dev/hpet",
            "${guestKeyboard}",
            "${guestMouse}",
            "/dev/kvmfr0"
        ]
      '';
    };
    hooks.qemu.evsieve-vfio-input = evsieveQemuHook;
  };

  systemd.services = {
    evsieve-vfio-input = {
      description = "Route keyboard and mouse between host and VFIO guest";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      wants = [ "systemd-udev-settle.service" ];
      before = [ "libvirtd.service" ];
      path = [
        evsieve
        pkgs.systemd
      ];

      serviceConfig = {
        Type = "notify";
        NotifyAccess = "all";
        RuntimeDirectory = "evsieve-vfio-input";
        RuntimeDirectoryMode = "0750";
        ExecStart = lib.escapeShellArgs evsieveArgs;
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };

    # Ensure libvirt never starts before evsieve has created the guest links.
    libvirtd = {
      wants = [ "evsieve-vfio-input.service" ];
      after = [ "evsieve-vfio-input.service" ];
      # libvirtd caches cgroup_device_acl at daemon startup. Restart it when
      # the declarative QEMU ACL changes so newly-created evsieve links are
      # authorized without requiring a reboot.
      restartTriggers = [
        (pkgs.writeText "libvirt-qemu-device-acl" config.virtualisation.libvirtd.qemu.verbatimConfig)
        evsieveQemuHook
      ];
    };
  };

  services.udev.extraRules = ''
    KERNEL=="kvmfr*", GROUP="kvm", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="vfio", KERNEL=="[0-9]*", GROUP="kvm", MODE="0660", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    evsieve
    looking-glass-client
  ];

  boot = {
    kernelModules = [
      "kvmfr"
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];

    kernelParams = [
      "intel_iommu=on"
      "vfio-pci.ids=1002:73ff,1002:ab28,144d:a808"
    ];

    extraModulePackages = [ config.boot.kernelPackages.kvmfr ];

    extraModprobeConfig = ''
      options kvmfr static_size_mb=32
    '';
  };
}

{ pkgs, ... }: {
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true; # Required for Windows 11 TPM 2.0
      };
    };
    spiceUSBRedirection.enable = true; # Required for USB passthrough via SPICE
  };

  programs.virt-manager.enable = true; # Install the VM manager GUI

  environment.systemPackages = with pkgs; [
    spice
    spice-gtk
    spice-protocol
    virt-viewer
    virtio-win # VirtIO drivers for Windows
    # win-spice # SPICE guest tools for Windows
  ];
}

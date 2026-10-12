{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
  systemd.services.bluetooth-resume = {
    description = "Restart Bluetooth after resume";
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/rfkill unblock bluetooth";
    };
  };
}

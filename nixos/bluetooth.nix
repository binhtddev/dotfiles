{
  hardware.bluetooth = {
    enable = true;
    # Bluetooth stays off until the user turns it on. btusb re-probes the
    # controller on resume on its own, so no resume hook is needed here.
    powerOnBoot = false;
  };
}

# pwr-cap-rs

Flake that provides an easy way to limit the power consumption of your Ryzen CPU.
Built using [ryzenadj libraries mappings to rust](https://crates.io/crates/libryzenadj)

Note: for information about supported CPUs check the 
[ryzenadj repo](https://github.com/FlyGoat/RyzenAdj)

## Usage

First add it to your system flake inputs:

`pwr-cap-rs.url = "github:cch000/pwr-cap-rs;`

Then you can use it by adding somewhere in your config:

```nix
  imports = [
    inputs.power-cap-rs.nixosModules.pwr-cap-rs
  ];

  #example config
  services.pwr-cap-rs = {
    enable = true;
    tctl_limit = 85;
    quiet = {
      unplugged = {
        enable = true;
        stapm_limit = 7000;
        fast_limit = 7000; #cannot be null if the profile is enabled
        #slow_limit = 7000;
        apu_slow_limit = 20000;
      };
      plugged.enable = false;
    };
    balanced = {
      unplugged.enable = false;
      plugged.enable = false;
    };
    performance = {
      unplugged.enable = false;
      plugged.enable = false;
    };
  };
```

For information about the options check the 
[ryzenadj repo](https://github.com/FlyGoat/RyzenAdj)

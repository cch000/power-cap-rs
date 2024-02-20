# pwr-cap-rs

Flake that provides an easy way to limit the power consumption of your ryzen mobile cpu.
The limit is only triggered when the power profile is set to `power-saver`.
Built using [ryzenadj libraries mappings to rust](https://crates.io/crates/libryzenadj)

Note: for information about supported models check the 
[ryzenadj repo](https://github.com/FlyGoat/RyzenAdj)

**WIP:** basically every commit is going to break something.

## Usage

First add it to your system flake inputs:

`pwr-cap-rs.url = "github:cch000/pwr-cap-rs;`

Then you can use it by adding somewhere in your config:

```nix
  imports = [
    inputs.power-cap-rs.nixosModules.pwr-cap-rs
  ];

  services.pwr-cap-rs = {
    enable = true;
    stapm-limit = 7000; # Change to your liking
    fast-limit = 7000;
    slow-limit = 7000;
    tctl-temp = 70;
  };
```

For information about the options check the 
[ryzenadj repo](https://github.com/FlyGoat/RyzenAdj)

use libryzenadj::RyzenAdj;
use std::fs;
use std::thread::sleep;
use std::time::{self, Duration};

use serde::{Deserialize, Serialize};
use serde_json::Result;

#[cfg(debug_assertions)]
const CONFIG_PATH: &str = "./data/pwr-cap-rs.json";

#[cfg(not(debug_assertions))]
const CONFIG_PATH: &str = "/etc/pwr-cap-rs.json";

#[derive(Serialize, Deserialize)]
struct Config {
    sus_pl: u32,    // Sustained Power Limit (mW)
    actual_pl: u32, // ACTUAL Power Limit    (mW)
    avg_pl: u32,    // Average Power Limit   (mW)
    max_tmp: u32,   // Max Tctl              (C)
}

impl Config {
    pub fn load() -> Result<Self> {
        let buffer = fs::read_to_string(CONFIG_PATH).expect("Failed to load config");
        Ok(serde_json::from_str(&buffer)?)
    }
}

fn main() {
    let power_saver: Config = Config::load().unwrap();

    const SYS_POWER_PROFILE: &str = "/sys/firmware/acpi/platform_profile";

    const NAP_TIME: Duration = time::Duration::from_secs(10);

    let ryzen_adj = RyzenAdj::new().unwrap();

    loop {
        let current_pwr_profile = fs::read_to_string(SYS_POWER_PROFILE)
            .expect("Reading pwr profile failed")
            .trim()
            .to_owned();

        if current_pwr_profile == "quiet" {
            let short_stamp_limit = ryzen_adj.get_stapm_limit().unwrap() as u32 * 1000;

            if short_stamp_limit != power_saver.sus_pl {
                ryzen_adj.set_stapm_limit(power_saver.sus_pl).unwrap();
                ryzen_adj.set_fast_limit(power_saver.actual_pl).unwrap();
                ryzen_adj.set_slow_limit(power_saver.avg_pl).unwrap();
                ryzen_adj.set_tctl_temp(power_saver.max_tmp).unwrap();

                println!("Adjusting ryzenadj values\n");
            }

            ryzen_adj
                .refresh()
                .expect("Failed to refresh ryzenadj values");
        }

        sleep(NAP_TIME);
    }
}

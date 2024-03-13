use libryzenadj::RyzenAdj;
use std::fs;
use std::thread::sleep;
use std::time::{self, Duration};

use serde::{Deserialize, Serialize};
use serde_json::Result;

const NAP_TIME: Duration = time::Duration::from_secs(10);
const SYS_POWER_PROFILE: &str = "/sys/firmware/acpi/platform_profile";

#[cfg(debug_assertions)]
const CONFIG_PATH: &str = "./data/pwr-cap-rs.json";
#[cfg(not(debug_assertions))]
const CONFIG_PATH: &str = "/etc/pwr-cap-rs.json";

#[derive(Serialize, Deserialize)]
struct Config {
    sus_pl: Option<u32>,    // Sustained Power Limit (mW)
    actual_pl: Option<u32>, // ACTUAL Power Limit    (mW)
    avg_pl: Option<u32>,    // Average Power Limit   (mW)
    max_tmp: Option<u32>,   // Max Tctl              (C)
}

impl Config {
    pub fn load() -> Result<Self> {
        let buffer = fs::read_to_string(CONFIG_PATH).expect("Failed to load config");
        Ok(serde_json::from_str(&buffer)?)
    }
}

fn main() {
    let config: Config = Config::load().unwrap();

    let ryzen_adj: RyzenAdj = RyzenAdj::new().unwrap();

    loop {
        let current_pwr_profile = fs::read_to_string(SYS_POWER_PROFILE)
            .expect("Reading pwr profile failed")
            .trim()
            .to_owned();

        if current_pwr_profile == "quiet" {
            let short_fast_limit = ryzen_adj.get_fast_limit().unwrap() as u32 * 1000;

            if short_fast_limit != config.actual_pl.expect("actual_pl cannot be null") {
                apply_values(&config, &ryzen_adj);

                println!("Adjusting ryzenadj values");
            }

            ryzen_adj
                .refresh()
                .expect("Failed to refresh ryzenadj values");
        }

        sleep(NAP_TIME);
    }
}

// function to dynamically call ryzenadj traits
fn apply_values(config: &Config, ryzenadj: &RyzenAdj) {
    config.sus_pl.map(|sus_pl| ryzenadj.set_stapm_limit(sus_pl));

    config.actual_pl.map(|actual_pl| ryzenadj.set_fast_limit(actual_pl));

    config.avg_pl.map(|avg_pl| ryzenadj.set_slow_limit(avg_pl));

    config.max_tmp.map(|max_tmp| ryzenadj.set_tctl_temp(max_tmp));
}

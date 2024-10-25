use libryzenadj::RyzenAdj;
use std::fs;
use std::thread::sleep;
use std::time::{self, Duration};

use serde::{Deserialize, Serialize};
use serde_json::Result;

const NAP_TIME: Duration = time::Duration::from_secs(10);
const SYS_POWER_PROFILE: &str = "/sys/firmware/acpi/platform_profile";
const SYS_CONNECTED: &str = "/sys/class/power_supply/AC0/online";

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

enum PowerProfileValue {
    Quiet,
    Balaced,
    Performance,
}

enum RyzenAdjValueType {
    ActualPl,
    SustainedPl,
    AveragePl,
    Tctl,
}

struct System {}
impl System {
    pub fn get_power_profile() -> PowerProfileValue {
        match fs::read_to_string(SYS_POWER_PROFILE)
            .expect("Reading pwr profile failed")
            .trim()
        {
            "quiet" => PowerProfileValue::Quiet,
            "balanced" => PowerProfileValue::Balaced,
            "performance" => PowerProfileValue::Performance,
            _ => panic!("power profile not valid"),
        }
    }

    pub fn get_connected() -> bool {
        if fs::read_to_string(SYS_CONNECTED)
            .expect("Reading plugged status failed")
            .trim()
            == "1"
        {
            true
        } else {
            false
        }
    }
}

fn main() {
    let config: Config = Config::load().unwrap();
    let ryzenadj: RyzenAdj = RyzenAdj::new().unwrap();

    loop {
        let power_profile: PowerProfileValue = System::get_power_profile();
        let connected: bool = System::get_connected();
        let short_fast_limit = ryzenadj.get_fast_limit().unwrap() as u32 * 1000;

        match power_profile {
            PowerProfileValue::Quiet => {
                //should be the config for actual pl in quiet mode, once is implemented
                if short_fast_limit != config.actual_pl.expect("actual_pl cannot be null") {
                    quiet_actions(&config, &ryzenadj, connected)
                }
            }
            PowerProfileValue::Balaced => {}
            PowerProfileValue::Performance => {}
        }

        apply_value(config.max_tmp, RyzenAdjValueType::Tctl, &ryzenadj);

        ryzenadj
            .refresh()
            .expect("Failed to refresh ryzenadj values");

        sleep(NAP_TIME);
    }
}

fn quiet_actions(config: &Config, ryzenadj: &RyzenAdj, connected: bool) {
    if connected {
        //nothing for the moment
        apply_value(None, RyzenAdjValueType::ActualPl, ryzenadj);
        apply_value(None, RyzenAdjValueType::AveragePl, ryzenadj);
        apply_value(None, RyzenAdjValueType::SustainedPl, ryzenadj);
        dbg!("Adjusting ryzenadj values for the quiet not connected profile");
    } else {
        apply_value(config.actual_pl, RyzenAdjValueType::ActualPl, ryzenadj);
        apply_value(config.avg_pl, RyzenAdjValueType::AveragePl, ryzenadj);
        apply_value(config.sus_pl, RyzenAdjValueType::SustainedPl, ryzenadj);
        dbg!("Adjusting ryzenadj values for the quiet not connected profile");
    }
}

fn apply_value(value: Option<u32>, ryzenadj_type: RyzenAdjValueType, ryzenadj: &RyzenAdj) {
    if value.is_some() {
        let value = value.unwrap();
        match ryzenadj_type {
            RyzenAdjValueType::ActualPl => ryzenadj
                .set_fast_limit(value)
                .expect("failed to set fast limit"),
            RyzenAdjValueType::SustainedPl => ryzenadj
                .set_stapm_limit(value)
                .expect("failed to set stapm limit"),
            RyzenAdjValueType::AveragePl => ryzenadj
                .set_slow_limit(value)
                .expect("failed to set slow limit"),
            RyzenAdjValueType::Tctl => ryzenadj
                .set_tctl_temp(value)
                .expect("failed to set tctl temp"),
        }
    }
}

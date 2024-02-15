use libryzenadj::RyzenAdj;
use std::fs;
use std::thread::sleep;
use std::time::{self, Duration};

struct RyzenadjValues {
    sus_pl: u32,    // Sustained Power Limit (mW)
    actual_pl: u32, // ACTUAL Power Limit    (mW)
    avg_pl: u32,    // Average Power Limit   (mW)
    max_tmp: u32,   // Max Tctl              (C)
}

fn main() {
    const POWER_SAVER: RyzenadjValues = RyzenadjValues {
        sus_pl: 7000,
        actual_pl: 7000,
        avg_pl: 7000,
        max_tmp: 70,
    };

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

            if short_stamp_limit != POWER_SAVER.sus_pl {
                ryzen_adj.set_stapm_limit(POWER_SAVER.sus_pl).unwrap();
                ryzen_adj.set_fast_limit(POWER_SAVER.actual_pl).unwrap();
                ryzen_adj.set_slow_limit(POWER_SAVER.avg_pl).unwrap();
                ryzen_adj.set_tctl_temp(POWER_SAVER.max_tmp).unwrap();

                println!("Adjusting ryzenadj values\n");
            }

            ryzen_adj
                .refresh()
                .expect("Failed to refresh ryzenadj values");
        }

        sleep(NAP_TIME);
    }
}

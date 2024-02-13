use std::thread::sleep;
use std::time::{self, Duration};

use libryzenadj::RyzenAdj;
//use zbus::blocking::proxy;
//use zbus::export::ordered_stream;
//use zbus::fdo::Properties;
//use zbus::{blocking::connection, fdo, Connection, Result};

struct RyzenadjValues {
    sus_pl: u32,    // Sustained Power Limit (mW)
    actual_pl: u32, // ACTUAL Power Limit    (mW)
    avg_pl: u32,    // Average Power Limit   (mW)
    vrm_edc: u32,   // VRM EDC Current       (mA)
    max_tmp: u32,   // Max Tctl              (C)
}

fn main() {
    const POWER_SAVER: RyzenadjValues = RyzenadjValues {
        sus_pl: 7000,
        actual_pl: 7000,
        avg_pl: 7000,
        vrm_edc: 90000,
        max_tmp: 70,
    };

    const NAP_TIME: Duration = time::Duration::from_secs(20);

    let ryzen_adj = RyzenAdj::new().unwrap();

    loop {
        sleep(NAP_TIME);

        if short_stamp_limit != POWER_SAVER.sus_pl {
            ryzen_adj.set_stapm_limit(POWER_SAVER.sus_pl).unwrap();
            ryzen_adj.set_fast_limit(POWER_SAVER.actual_pl).unwrap();
            ryzen_adj.set_slow_limit(POWER_SAVER.sus_pl).unwrap();
            ryzen_adj.set_tctl_temp(POWER_SAVER.max_tmp).unwrap();

            println!("Adjusting ryzenadj values\n");
            println!("{}", short_stamp_limit);
        }

        let stamp_limit = ryzen_adj.get_stapm_limit().unwrap();

        let short_stamp_limit: u32 = stamp_limit as u32 * 1000;
    }
}

use libryzenadj::RyzenAdj;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct Profile {
    enable: bool,
    stapm_limit: Option<u32>,    // Sustained Power Limit (mW)
    fast_limit: Option<u32>,     // ACTUAL Power Limit    (mW)
    slow_limit: Option<u32>,     // Average Power Limit   (mW)
    apu_slow_limit: Option<u32>, // APU Power Limit       (mW)
}

impl Profile {
    pub fn apply(&self, ryzenadj: &RyzenAdj) {
        if self.enable {
            let fast_limit = ryzenadj.get_fast_limit().unwrap() as u32 * 1000;
            if fast_limit != self.fast_limit.expect("fast limit cannot be null") {
                ryzenadj
                    .set_fast_limit(self.fast_limit.unwrap())
                    .expect("failed to apply fast_limit");

                if self.stapm_limit.is_some() {
                    ryzenadj
                        .set_stapm_limit(self.stapm_limit.unwrap())
                        .expect("failed to apply stapm_limit");
                }

                if self.slow_limit.is_some() {
                    ryzenadj
                        .set_slow_limit(self.slow_limit.unwrap())
                        .expect("failed to apply slow_limit");
                }

                if self.apu_slow_limit.is_some() {
                    ryzenadj
                        .set_apu_slow_limit(self.apu_slow_limit.unwrap())
                        .expect("failed to APU slow limit");
                }
            }
        }
    }
}

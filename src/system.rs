use std::fs;

const SYS_POWER_PROFILE: &str = "/sys/firmware/acpi/platform_profile";
const SYS_CONNECTED: &str = "/sys/class/power_supply/AC0/online";
pub enum PowerProfileValue {
    Quiet,
    Balaced,
    Performance,
}

pub struct System {
    power_profile: PowerProfileValue,
    connected: bool,
}
impl System {
    pub fn new() -> Self {
        System {
            power_profile: System::load_power_profile(),
            connected: System::load_connected(),
        }
    }

    fn load_power_profile() -> PowerProfileValue {
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

    fn load_connected() -> bool {
        fs::read_to_string(SYS_CONNECTED)
            .expect("Reading plugged status failed")
            .trim()
            == "1"
    }

    pub fn get_power_profile(&self) -> &PowerProfileValue {
        &self.power_profile
    }
    pub fn get_connected(&self) -> bool {
        self.connected
    }
}

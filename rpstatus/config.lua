local addonName, addon = ...

-- Configuration constants
addon.CONFIG = {
    PREFIX = "RPSTATUS",
    VERSION = "1.0.5",  
    UPDATE_INTERVAL = 30,
    STATUS_TTL = 35,
    AVAILABLE_STATUSES = {
        "Available",
        "Not Available",
        "Busy",
        "Looking for RP"
    },
    DEFAULT_SETTINGS = {
        status = "Available",
        minimized = false,
        position = {
            x = 0,
            y = 0
        },
        minimap = {
            hide = false,
            position = 45
        }
    }
}
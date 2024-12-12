local addonName, addon = ...
addon.Comm = {}

-- Broadcast to channels
function addon.Comm:BroadcastStatus()
    local message = self:EncodeMessage(RPStatusDB.status)
    SendAddonMessage(addon.CONFIG.PREFIX, message, "GUILD")
    if UnitInRaid("player") then
        SendAddonMessage(addon.CONFIG.PREFIX, message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage(addon.CONFIG.PREFIX, message, "PARTY")
    end
end

-- Message encoding (could be expanded for more complex protocols like trp maybe?)
function addon.Comm:EncodeMessage(status)
    return status
end

-- Message decoding (could be expanded for more complex protocols like trp maybe?)
function addon.Comm:DecodeMessage(message)
    return message
end
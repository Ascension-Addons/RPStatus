local addonName, addon = ...
addon.Status = {}

-- Clean expired statuses
function addon.Status:Clean()
    local currentTime = GetTime()
    local playersToRemove = {}
    
    -- Collect expired players
    for player, data in pairs(addon.playerStatus) do
        if currentTime - data.timestamp > addon.CONFIG.STATUS_TTL then
            table.insert(playersToRemove, player)
        end
    end
    
    -- Remove expired players
    for _, player in ipairs(playersToRemove) do
        addon.playerStatus[player] = nil
    end
    
    -- Update display if any players were removed
    if #playersToRemove > 0 then
        addon.UI.PlayerList:Update()
    end
end

-- Add test entries for debugging
function addon.Status:AddTestEntries()
    -- Clear existing entries
    wipe(addon.playerStatus)
    
    -- Add some fancy names 
    local testPlayers = {
        "Arthas", "Sylvanas", "Thrall", "Jaina",
        "Tyrande", "Illidan", "Malfurion", "Varian",
        "Anduin", "Garrosh", "Vol'jin", "Cairne"
    }
    
    for _, player in ipairs(testPlayers) do
        -- Random status
        local randomStatus = addon.CONFIG.AVAILABLE_STATUSES[math.random(#addon.CONFIG.AVAILABLE_STATUSES)]
        
        -- Add to table
        addon.playerStatus[player] = {
            status = randomStatus,
            timestamp = GetTime()
        }
    end
    
    -- Update display
    addon.UI.PlayerList:Update()
end
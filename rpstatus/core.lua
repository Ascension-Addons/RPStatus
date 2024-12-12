local addonName, addon = ...
addon.RPStatus = CreateFrame("Frame")
RPStatusDB = addon.CONFIG.DEFAULT_SETTINGS

-- Move playerStatus to addon namespace
addon.playerStatus = {}

-- Initialize the addon
function addon.RPStatus:Init()
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_LOGOUT")
    
    self:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            self[event](self, ...)
        end
    end)
    
    -- Update timer
    self.updateTimer = 0
    self:SetScript("OnUpdate", function(self, elapsed)
        self.updateTimer = self.updateTimer + elapsed
        if self.updateTimer >= addon.CONFIG.UPDATE_INTERVAL then
            addon.Comm:BroadcastStatus()
            addon.Status:Clean()
            self.updateTimer = 0
        end
    end)
end

-- Event handlers
function addon.RPStatus:ADDON_LOADED(loadedAddon)
    if loadedAddon ~= addonName then return end
    
    -- Initialize UI components
    addon.UI:CreateMainFrame()
    addon.UI.Minimap:Create()
    
    -- Initialize slash commands
    addon.Commands:Init()
end

function addon.RPStatus:PLAYER_LOGIN()
    addon.Comm:BroadcastStatus()
end

function addon.RPStatus:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix ~= addon.CONFIG.PREFIX then return end
    
    -- Don't process our own messages
    if sender == UnitName("player") then return end
    
    local status = addon.Comm:DecodeMessage(message)
    if status then
        addon.playerStatus[sender] = {
            status = status,
            timestamp = GetTime()
        }
        addon.UI.PlayerList:Update()
    end
end

-- Initialize the addon
addon.RPStatus:Init()
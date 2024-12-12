local addonName, addon = ...
addon.Commands = {}

function addon.Commands:Init()
    -- Test command
    SLASH_RPSTATUSTEST1 = "/rptest"
    SlashCmdList["RPSTATUSTEST"] = function(msg)
        addon.Status:AddTestEntries()
    end
    
    -- Main commands
    SLASH_RPSTATUS1 = "/rpstatus"
    SLASH_RPSTATUS2 = "/rps"
    SlashCmdList["RPSTATUS"] = function(msg)
        msg = msg:lower()
        if msg == "hide" then
            RPStatusDB.minimap.hide = true
            addon.UI.Minimap:UpdateVisibility()
            print("RP Status: Minimap button hidden")
        elseif msg == "show" then
            RPStatusDB.minimap.hide = false
            addon.UI.Minimap:UpdateVisibility()
            print("RP Status: Minimap button shown")
        elseif msg == "settings" then
            addon.UI:ToggleSettingsFrame()
        else
            -- Toggle main window
            if addon.UI.mainFrame:IsShown() then
                addon.UI.mainFrame:Hide()
            else
                addon.UI.mainFrame:Show()
            end
        end
    end
end
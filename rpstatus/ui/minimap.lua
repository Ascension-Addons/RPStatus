local addonName, addon = ...
addon.UI.Minimap = {}

function addon.UI.Minimap:Create()
    local button = CreateFrame("Button", "RPStatusMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:EnableMouse(true)
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    
    -- Icon texture
    local texture = button:CreateTexture(nil, "BACKGROUND")
    texture:SetSize(18, 18)
    texture:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -7)
    texture:SetTexture("Interface\\ICONS\\inv_inscription_83_contract_rajani")
    button.texture = texture
    
    -- Border highlight
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(54, 54)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    -- Position handler
    local function UpdatePosition()
        if not RPStatusDB.minimap then
            RPStatusDB.minimap = addon.CONFIG.DEFAULT_SETTINGS.minimap
        end
        local angle = math.rad(RPStatusDB.minimap.position)
        local x = math.cos(angle) * 80
        local y = math.sin(angle) * 80
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
    
    -- Drag handlers
    local function OnDragStart(self)
        self.isMoving = true
        self:StartMoving()
    end
    
    local function OnDragStop(self)
        self.isMoving = false
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local cx, cy = Minimap:GetCenter()
        RPStatusDB.minimap.position = math.deg(math.atan2(y - cy, x - cx))
        UpdatePosition()
    end
    
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnDragStop", OnDragStop)
    
    -- Click handler
    button:SetScript("OnClick", function()
        if addon.UI.mainFrame:IsShown() then
            addon.UI.mainFrame:Hide()
        else
            addon.UI.mainFrame:Show()
        end
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:AddLine("RP Status")
        GameTooltip:AddLine("Click to toggle window", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    UpdatePosition()
    self.button = button
    self:UpdateVisibility()
end

function addon.UI.Minimap:UpdateVisibility()
    if RPStatusDB.minimap.hide then
        self.button:Hide()
    else
        self.button:Show()
    end
end
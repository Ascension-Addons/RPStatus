local addonName, addon = ...
addon.UI = {}

function addon.UI:CreateMainFrame()
    local frame = CreateFrame("Frame", "RPStatusFrame", UIParent)
    frame:SetSize(200, 300)
    frame:SetPoint("CENTER", UIParent, "CENTER", RPStatusDB.position.x, RPStatusDB.position.y)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    -- Border
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Movement handling
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local x, y = frame:GetCenter()
        RPStatusDB.position.x = x - GetScreenWidth()/2
        RPStatusDB.position.y = y - GetScreenHeight()/2
    end)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("RP Status")

    -- Subtitle
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("by Random Encounters")
    subtitle:SetTextColor(0.7, 0.7, 0.7)
    
    -- Settings button
    local settingsButton = CreateFrame("Button", nil, frame)
    settingsButton:SetSize(15, 15)
    settingsButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton-Highlight")
    
    settingsButton:SetScript("OnClick", function()
        self:ToggleSettingsFrame()
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Create UI components
    self:CreateStatusDropdown(frame)
    addon.UI.PlayerList:Create(frame)
    
    self.mainFrame = frame
    
    -- Show/hide based on settings
    if RPStatusDB.minimized then
        frame:Hide()
    else
        frame:Show()
    end
end

function addon.UI:CreateSettingsFrame()
    if self.settingsFrame then
        return self.settingsFrame
    end

    local frame = CreateFrame("Frame", "RPStatusSettingsFrame", UIParent)
    frame:SetSize(250, 150)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("RP Status Settings")

    -- version
    local version = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("TOP", title, "BOTTOM", 0, -5)
    version:SetText("Version: " .. addon.CONFIG.VERSION)
    version:SetTextColor(0.7, 0.7, 0.7)
        
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Hide Minimap checkbox
    local hideMinimapCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    hideMinimapCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
    hideMinimapCheck:SetChecked(RPStatusDB.minimap.hide)
    
    local hideMinimapLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hideMinimapLabel:SetPoint("LEFT", hideMinimapCheck, "RIGHT", 5, 0)
    hideMinimapLabel:SetText("Hide Minimap Button")
    
    hideMinimapCheck:SetScript("OnClick", function()
        RPStatusDB.minimap.hide = hideMinimapCheck:GetChecked()
        addon.UI.Minimap:UpdateVisibility()
    end)
    
    frame:Hide()
    self.settingsFrame = frame
    return frame
end

function addon.UI:ToggleSettingsFrame()
    local frame = self:CreateSettingsFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function addon.UI:CreateStatusDropdown(parent)
    local dropdown = CreateFrame("Frame", "RPStatusDropDown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOP", parent, "TOP", 0, -40)
    
    local function OnClick(self)
        RPStatusDB.status = self.value
        UIDropDownMenu_SetText(dropdown, self.value)
        addon.Comm:BroadcastStatus()
    end
    
    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        for _, status in ipairs(addon.CONFIG.AVAILABLE_STATUSES) do
            info.text = status
            info.value = status
            info.checked = status == RPStatusDB.status
            info.func = OnClick
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, Initialize)
    UIDropDownMenu_SetText(dropdown, RPStatusDB.status)
    UIDropDownMenu_SetWidth(dropdown, 150)
end
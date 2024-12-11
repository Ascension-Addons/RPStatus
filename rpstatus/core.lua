-- initialization
local addonName, addon = ...
local RPStatus = CreateFrame("Frame")
local PREFIX = "RPSTATUS"
local UPDATE_INTERVAL = 30
local STATUS_TTL = 35

-- default 
RPStatusDB = {
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

-- status tracking
local playerStatus = {}

-- Initialize 
function RPStatus:Init()
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_LOGOUT")
    
    self:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            self[event](self, ...)
        end
    end)
    
    -- update timer
    self.updateTimer = 0
    self:SetScript("OnUpdate", function(self, elapsed)
        self.updateTimer = self.updateTimer + elapsed
        if self.updateTimer >= UPDATE_INTERVAL then
            self:BroadcastStatus()
            self:CleanExpiredStatuses()
            self.updateTimer = 0
        end
    end)
end

-- Minimap button functions
function RPStatus:CreateMinimapButton()
    local button = CreateFrame("Button", "RPStatusMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:EnableMouse(true)
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    
    -- icon texture
    local texture = button:CreateTexture(nil, "BACKGROUND")
    texture:SetSize(18, 18)  -- Slightly smaller for better fit
    texture:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -7)  -- Offset to center in border
    texture:SetTexture("Interface\\ICONS\\inv_inscription_83_contract_rajani")
    button.texture = texture
    
    -- border highlight
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(54, 54)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0,0)  -- Adjust border position
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    -- Position minimap
    local function UpdatePosition()
        if not RPStatusDB.minimap then
            RPStatusDB.minimap = {
                hide = false,
                position = 45
            }
        end
        local angle = math.rad(RPStatusDB.minimap.position)
        local x = math.cos(angle) * 80
        local y = math.sin(angle) * 80
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
    
    -- Make the button dragggeble
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
    
    -- Click handling
    button:SetScript("OnClick", function()
        if self.mainFrame:IsShown() then
            self.mainFrame:Hide()
        else
            self.mainFrame:Show()
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
    self.minimapButton = button
    return button
end

function RPStatus:UpdateMinimapButtonVisibility()
    if RPStatusDB.minimap.hide then
        self.minimapButton:Hide()
    else
        self.minimapButton:Show()
    end
end

-- Event handlers
function RPStatus:ADDON_LOADED(loadedAddon)
    if loadedAddon ~= addonName then return end
    
    -- main UI
    self:CreateMainFrame()
    self:CreateMinimapButton()
end

function RPStatus:PLAYER_LOGIN()
    -- Broadcast status
    self:BroadcastStatus()
end

function RPStatus:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix ~= PREFIX then return end
    
    -- Don't process our own messages
    if sender == UnitName("player") then return end
    
    local status = self:DecodeMessage(message)
    if status then
        playerStatus[sender] = {
            status = status,
            timestamp = GetTime()
        }
        self:UpdateDisplay()
    end
end

-- Communication 
function RPStatus:BroadcastStatus()
    local message = self:EncodeMessage(RPStatusDB.status)
    SendAddonMessage(PREFIX, message, "GUILD")
    if UnitInRaid("player") then
        SendAddonMessage(PREFIX, message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage(PREFIX, message, "PARTY")
    end
end

function RPStatus:EncodeMessage(status)
    return status
end

function RPStatus:DecodeMessage(message)
    return message
end

-- UI 
function RPStatus:CreateMainFrame()
    local frame = CreateFrame("Frame", "RPStatusFrame", UIParent)
    frame:SetSize(200, 300)
    frame:SetPoint("CENTER", UIParent, "CENTER", RPStatusDB.position.x, RPStatusDB.position.y)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    -- border
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local x, y = frame:GetCenter()
        RPStatusDB.position.x = x - GetScreenWidth()/2
        RPStatusDB.position.y = y - GetScreenHeight()/2
    end)
    
    -- title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("RP Status")

    -- subtile
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("by Random Encounters")
    subtitle:SetTextColor(0.7, 0.7, 0.7)
    
    -- setting button
    local settingsButton = CreateFrame("Button", nil, frame)
    settingsButton:SetSize(15, 15)
    settingsButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton-Highlight")
    
    settingsButton:SetScript("OnClick", function()
        self:ToggleSettingsFrame()
    end)
    
    -- colse button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- status dropdown
    self:CreateStatusDropdown(frame)
    
    -- player list
    self:CreatePlayerList(frame)
    
    self.mainFrame = frame
    
    -- Show/hide 
    if RPStatusDB.minimized then
        frame:Hide()
    else
        frame:Show()
    end
end

function RPStatus:CreateSettingsFrame()
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
    
    -- Make it draggable
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("RP Status Settings")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Hide Minimapbox
    local hideMinimapCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    hideMinimapCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
    hideMinimapCheck:SetChecked(RPStatusDB.minimap.hide)
    
    local hideMinimapLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hideMinimapLabel:SetPoint("LEFT", hideMinimapCheck, "RIGHT", 5, 0)
    hideMinimapLabel:SetText("Hide Minimap Button")
    
    hideMinimapCheck:SetScript("OnClick", function()
        RPStatusDB.minimap.hide = hideMinimapCheck:GetChecked()
        RPStatus:UpdateMinimapButtonVisibility()
    end)
    
    frame:Hide()
    self.settingsFrame = frame
    return frame
end

function RPStatus:ToggleSettingsFrame()
    local frame = self:CreateSettingsFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function RPStatus:CreateStatusDropdown(parent)
    local dropdown = CreateFrame("Frame", "RPStatusDropDown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOP", parent, "TOP", 0, -40)
    
    local function OnClick(self, arg1, arg2, checked)
        RPStatusDB.status = self.value
        UIDropDownMenu_SetText(dropdown, self.value)
        RPStatus:BroadcastStatus()
    end
    
    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local statuses = {"Available", "Not Available", "Busy", "Looking for RP"}
        
        for _, status in ipairs(statuses) do
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

function RPStatus:CreatePlayerList(parent)
    -- Create the main scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "RPStatusPlayerList", parent)
    scrollFrame:SetPoint("TOP", parent, "TOP", 0, -75)
    scrollFrame:SetSize(180, 210)
    
    -- Create the scrollbar
    local scrollbar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollbar:SetMinMaxValues(1, 1)
    scrollbar:SetValueStep(1)
    scrollbar.scrollStep = 1
    
    -- Create the content frame that will hold our entries
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(180, 210)
    scrollFrame:SetScrollChild(content)
    
    -- Background for scroll area
    local bg = content:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetTexture(0, 0, 0, 0.1)
    
    -- Store references
    self.playerList = content
    self.scrollFrame = scrollFrame
    self.scrollbar = scrollbar
    
    -- Scrolling functions
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local min, max = scrollbar:GetMinMaxValues()
        local step = 30  -- Adjust scroll speed
        
        if delta < 0 then
            local new = math.min(current + step, max)
            scrollbar:SetValue(new)
        else
            local new = math.max(current - step, min)
            scrollbar:SetValue(new)
        end
    end)
end

function RPStatus:UpdateDisplay()
    if not self.playerList then return end
    
    -- Clear existing entries
    for _, child in pairs({self.playerList:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Add player entries
    local yOffset = 0
    local totalHeight = 0
    
    for player, statusData in pairs(playerStatus) do
        local entry = CreateFrame("Button", nil, self.playerList)
        entry:SetSize(170, 20)
        entry:SetPoint("TOPLEFT", self.playerList, "TOPLEFT", 5, -yOffset)
        
        -- Highlight on mouseover
        entry:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        
        local name = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("LEFT", entry, "LEFT", 5, 0)
        name:SetText(player)
        
        local statusText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusText:SetPoint("RIGHT", entry, "RIGHT", -5, 0)
        statusText:SetText(statusData.status)
        
        -- Add whisper functionality
        entry:SetScript("OnClick", function()
            ChatFrame_OpenChat("/w " .. player .. " ")
        end)
        
        -- Add tooltip
        entry:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(player)
            GameTooltip:AddLine("Click to whisper", 1, 1, 1)
            GameTooltip:Show()
        end)
        
        entry:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        yOffset = yOffset + 25
        totalHeight = totalHeight + 25
    end
    
    -- Update content and scroll frame sizes
    self.playerList:SetHeight(math.max(totalHeight, 210))
    
    -- Update scrollbar range
    local maxScroll = math.max(0, totalHeight - 210)  -- 210 is visible frame height
    self.scrollbar:SetMinMaxValues(0, maxScroll)
    
    -- Show/hide scrollbar based on content
    if totalHeight > 210 then
        self.scrollbar:Show()
    else
        self.scrollbar:Hide()
    end
end

function RPStatus:AddTestEntries()
    -- Clear existing entries
    playerStatus = {}
    
    -- List of possible statuses
    local statuses = {"Available", "Not Available", "Busy", "Looking for RP"}
    
    -- Add some fancy names and random statuses
    local testPlayers = {
        "Arthas", "Sylvanas", "Thrall", "Jaina",
        "Tyrande", "Illidan", "Malfurion", "Varian",
        "Anduin", "Garrosh", "Vol'jin", "Cairne",
        "Genn", "Velen", "Lor'themar", "Gallywix",
        "Nathanos", "Khadgar", "Medivh", "Garona",
        "Akama", "Chen", "Rexxar", "Muradin",
        "Magni", "Baine", "Bolvar", "Lilian",
        "Wrathion", "Alexstrasza", "Ysera", "Nozdormu",
        "Chromie", "Kalecgos", "Malygos", "Deathwing"
    }
    
    for _, player in ipairs(testPlayers) do
        -- random status
        local randomStatus = statuses[math.random(#statuses)]
        
        -- Add to table
        playerStatus[player] = {
            status = randomStatus,
            timestamp = GetTime()
        }
    end
    
    -- Update display
    self:UpdateDisplay()
end


function RPStatus:CleanExpiredStatuses()
    local currentTime = GetTime()
    local playersToRemove = {}
    
    -- Collect expired players
    for player, data in pairs(playerStatus) do
        if currentTime - data.timestamp > STATUS_TTL then
            table.insert(playersToRemove, player)
        end
    end
    
    -- Remove expired players
    for _, player in ipairs(playersToRemove) do
        playerStatus[player] = nil
    end
    
    -- Update display if any players were removed
    if #playersToRemove > 0 then
        self:UpdateDisplay()
    end
end

-- test command
SLASH_RPSTATUSTEST1 = "/rptest"
SlashCmdList["RPSTATUSTEST"] = function(msg)
    RPStatus:AddTestEntries()
end
-- commands to toggle
SLASH_RPSTATUS1 = "/rpstatus"
SLASH_RPSTATUS2 = "/rps"
SlashCmdList["RPSTATUS"] = function(msg)
    msg = msg:lower()
    if msg == "hide" then
        RPStatusDB.minimap.hide = true
        RPStatus:UpdateMinimapButtonVisibility()
        print("RP Status: Minimap button hidden")
    elseif msg == "show" then
        RPStatusDB.minimap.hide = false
        RPStatus:UpdateMinimapButtonVisibility()
        print("RP Status: Minimap button shown")
    elseif msg == "settings" then
        RPStatus:ToggleSettingsFrame()
    else
        -- Toggle main window
        if RPStatus.mainFrame:IsShown() then
            RPStatus.mainFrame:Hide()
        else
            RPStatus.mainFrame:Show()
        end
    end
end
-- Initialize the addon
RPStatus:Init()


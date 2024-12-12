local addonName, addon = ...
addon.UI.PlayerList = {}

function addon.UI.PlayerList:Create(parent)
    --  main scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "RPStatusPlayerList", parent)
    scrollFrame:SetPoint("TOP", parent, "TOP", 0, -75)
    scrollFrame:SetSize(180, 210)
    
    -- scrollbar
    local scrollbar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollbar:SetMinMaxValues(1, 1)
    scrollbar:SetValueStep(1)
    scrollbar.scrollStep = 1
    
    --  frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(180, 210)
    scrollFrame:SetScrollChild(content)
    
    -- Background
    local bg = content:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetTexture(0, 0, 0, 0.1)
    
    -- Store references
    self.content = content
    self.scrollFrame = scrollFrame
    self.scrollbar = scrollbar
    
    -- Scrolling functions
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    -- Mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local min, max = scrollbar:GetMinMaxValues()
        local step = 30
        
        if delta < 0 then
            local new = math.min(current + step, max)
            scrollbar:SetValue(new)
        else
            local new = math.max(current - step, min)
            scrollbar:SetValue(new)
        end
    end)
end

function addon.UI.PlayerList:Update()
    if not self.content then return end
    
    -- Clear existing entries
    for _, child in pairs({self.content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Add entries
    local yOffset = 0
    local totalHeight = 0
    
    -- CHANGED: addon.playerStatus instead  playerStatus
    for player, statusData in pairs(addon.playerStatus) do
        local entry = self:CreatePlayerEntry(player, statusData)
        entry:SetPoint("TOPLEFT", self.content, "TOPLEFT", 5, -yOffset)
        
        yOffset = yOffset + 25
        totalHeight = totalHeight + 25
    end
    
    -- Update content height
    self.content:SetHeight(math.max(totalHeight, 210))
    
    -- Update scrollbar
    local maxScroll = math.max(0, totalHeight - 210)
    self.scrollbar:SetMinMaxValues(0, maxScroll)
    
    -- Show/hide scrollbar
    if totalHeight > 210 then
        self.scrollbar:Show()
    else
        self.scrollbar:Hide()
    end
end

function addon.UI.PlayerList:CreatePlayerEntry(player, statusData)
    local entry = CreateFrame("Button", nil, self.content)
    entry:SetSize(170, 20)
    
    -- Highlight on mouseover
    entry:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    
    -- Player name
    local name = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", entry, "LEFT", 5, 0)
    name:SetText(player)
    
    -- Status text
    local statusText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("RIGHT", entry, "RIGHT", -5, 0)
    statusText:SetText(statusData.status)
    
    -- Whisper functionality
    entry:SetScript("OnClick", function()
        ChatFrame_OpenChat("/w " .. player .. " ")
    end)
    
    -- Tooltip
    entry:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(player)
        GameTooltip:AddLine("Click to whisper", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    entry:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return entry
end
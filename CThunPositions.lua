--Metadata----------------------------------------------------------------------------------------------------------------------
    
    AddonName = "C'Thun Positions"
    Version = "1.1"
    VState = "release"



--Onload & Minimap Clik/Drag---------------------------------------------------------------------------------------------------
  
    local isMoving = false

    function CThunPositions_OnLoad(self)
        self:RegisterForDrag("LeftButton")
        self:SetScript("OnDragStart", function() CThunPositions_OnDragStart(self) end)
        self:SetScript("OnDragStop", function() CThunPositions_OnDragStop(self) end)
        self:SetScript("OnClick", function(_, button) CThunPositions_OnClick(self, button) end)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. AddonName .. " Loaded! (version " .. Version .. "-" .. VState .. ")|r |cff808080[Made by Horyoshi]|r")
    end

    function CThunPositions_OnClick(self, button)
        if not self then return end -- Check if self is nil
        if IsShiftKeyDown() and button == "LeftButton" then
            if not isMoving then
                self:StartMoving()
                isMoving = true
            else
                self:StopMovingOrSizing()
                isMoving = false
            end
        else
            CThunPositions_Map()
        end
    end

    function CThunPositions_OnDragStart(self)
        if IsShiftKeyDown() then
            self:StartMoving()
            self.isMoving = true
        end
    end

    function CThunPositions_OnDragStop(self)
        if self and self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = false
        end
    end

    function GroupChangeNotifier_OnEvent()

    end



--The Actual Functionality ------------------------------------------------------------------------------------------------------

-- Class Colors (Define manually for WoW 1.12)
local classColors = {
    ["DRUID"] = { r = 1.00, g = 0.49, b = 0.04 },
    ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["MAGE"] = { r = 0.41, g = 0.80, b = 0.94 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["PRIEST"] = { r = 1.00, g = 1.00, b = 1.00 },
    ["ROGUE"] = { r = 1.00, g = 0.96, b = 0.41 },
    ["SHAMAN"] = { r = 0.00, g = 0.44, b = 0.87 },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
}

function CThunPositions_Map(self)
    -- Check if the player is in a raid
    if not UnitInRaid("player") then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000You are not in a raid.|r")
        return
    end

    -- Create the main frame if it doesn't exist
    if not CThunMapFrame then
        -- Main Frame
        CThunMapFrame = CreateFrame("Frame", "CThunMapFrame", UIParent)
        CThunMapFrame:SetWidth(512)
        CThunMapFrame:SetHeight(512)
        CThunMapFrame:SetPoint("CENTER", UIParent, "CENTER")
        CThunMapFrame:SetFrameStrata("DIALOG")
        CThunMapFrame:SetMovable(true)
        CThunMapFrame:EnableMouse(true)
        CThunMapFrame:RegisterForDrag("LeftButton")
        CThunMapFrame:SetScript("OnDragStart", function() 
            CThunMapFrame:StartMoving() 
        end)
        CThunMapFrame:SetScript("OnDragStop", function() 
            CThunMapFrame:StopMovingOrSizing() 
        end)

        -- Add a Blizzard-style border and background
        CThunMapFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  -- Blizzard-style background
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",    -- Blizzard-style border
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })

        CThunMapFrame:SetBackdropColor(0, 0, 0, 0)

        -- Background texture for the frame (image)
        local background = CThunMapFrame:CreateTexture(nil, "BACKGROUND")
        background:SetTexture("Interface\\AddOns\\CThunPositions\\images\\cthun_map.tga")
        background:SetAllPoints(CThunMapFrame)
        background:SetTexCoord(0, 1, 0, 1)

        -- Close Button
        local closeButton = CreateFrame("Button", nil, CThunMapFrame)
        closeButton:SetWidth(32)
        closeButton:SetHeight(32)
        closeButton:SetPoint("TOPRIGHT", CThunMapFrame, "TOPRIGHT", -5, -5)
        closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
        closeButton:SetScript("OnClick", function() CThunMapFrame:Hide() end)

        -- Reset Button
        local resetButton = CreateFrame("Button", nil, CThunMapFrame, "UIPanelButtonTemplate")
        resetButton:SetWidth(80)
        resetButton:SetHeight(22)
        resetButton:SetPoint("BOTTOM", CThunMapFrame, "BOTTOM", 0, 0)
        resetButton:SetText("Reset")
        resetButton:SetScript("OnClick", function()
            -- Reset positions
            local i = 0
            for name, playerFrame in pairs(CThunMapFrame.playerFrames) do
                i = i + 1
                playerFrame:ClearAllPoints()
                playerFrame:SetPoint("TOPLEFT", CThunMapFrame, "TOPLEFT", 15, -15 - (i - 1) * 15)
                playerFrame.xOffset = 15
                playerFrame.yOffset = -15 - (i - 1) * 15
                playerFrame.relativeX = playerFrame.xOffset / CThunMapFrame:GetWidth()
                playerFrame.relativeY = playerFrame.yOffset / CThunMapFrame:GetHeight()
            end
        end)

        -- Create a resize handle for scaling
        local resizeHandle = CreateFrame("Button", nil, CThunMapFrame)
        resizeHandle:SetWidth(16)
        resizeHandle:SetHeight(16)
        resizeHandle:SetPoint("BOTTOMRIGHT", CThunMapFrame, "BOTTOMRIGHT", -10, 10)
        resizeHandle:SetNormalTexture("Interface\\AddOns\\CThunPositions\\images\\resize_icon.tga")

        -- Maintain 1:1 aspect ratio while resizing
        resizeHandle:SetScript("OnMouseDown", function()
            CThunMapFrame:StartSizing("BOTTOMRIGHT")
            resizeHandle:SetScript("OnUpdate", function()
                local width = CThunMapFrame:GetWidth()
                CThunMapFrame:SetHeight(width)  -- Keep height equal to width for 1:1 ratio
            end)
        end)

        resizeHandle:SetScript("OnMouseUp", function()
            CThunMapFrame:StopMovingOrSizing()
            resizeHandle:SetScript("OnUpdate", nil)  -- Stop adjusting size after mouse up

            -- Adjust the background texture and other elements to match the new size
            background:SetAllPoints(CThunMapFrame)
        end)

        -- Set the frame's min and max scale size limits
        CThunMapFrame:SetResizable(true)
        CThunMapFrame:SetMinResize(300, 300) -- minimum size
        CThunMapFrame:SetMaxResize(1024, 1024) -- maximum size

        -- Table to hold player frames
        CThunMapFrame.playerFrames = {}

        -- Function to update player list and group numbers
        local function UpdatePlayerList()
            -- Clear existing frames
            for _, frame in pairs(CThunMapFrame.playerFrames) do
                frame:Hide()
            end
            CThunMapFrame.playerFrames = {}

            local numRaidMembers = GetNumRaidMembers()
            local playerIndex = 1
            for i = 1, numRaidMembers do
                local name, rank, subgroup, level, class, fileName = GetRaidRosterInfo(i)

                -- Create a frame for each player
                local playerFrame = CreateFrame("Button", nil, CThunMapFrame)
                playerFrame:SetWidth(150)
                playerFrame:SetHeight(20)
                playerFrame.xOffset = 15
                playerFrame.yOffset = -15 - (playerIndex - 1) * 15
                playerFrame.relativeX = playerFrame.xOffset / CThunMapFrame:GetWidth()  -- Store relative X
                playerFrame.relativeY = playerFrame.yOffset / CThunMapFrame:GetHeight() -- Store relative Y
                playerFrame:SetPoint("TOPLEFT", CThunMapFrame, "TOPLEFT", playerFrame.xOffset, playerFrame.yOffset)
                playerFrame:SetMovable(true)
                playerFrame:EnableMouse(true)
                playerFrame:RegisterForDrag("LeftButton")
                playerFrame.name = name  -- Store the player's name in the frame

                -- Start dragging player frame
                playerFrame:SetScript("OnDragStart", function()
                    playerFrame:StartMoving()
                end)

                -- Stop dragging player frame and update position
                playerFrame:SetScript("OnDragStop", function() 
                    playerFrame:StopMovingOrSizing()

                    -- Calculate new position relative to the main frame
                    local x, y = playerFrame:GetLeft() - CThunMapFrame:GetLeft(), playerFrame:GetTop() - CThunMapFrame:GetTop()
                    playerFrame.xOffset = x
                    playerFrame.yOffset = y

                    playerFrame:ClearAllPoints()
                    playerFrame:SetPoint("TOPLEFT", CThunMapFrame, "TOPLEFT", playerFrame.xOffset, playerFrame.yOffset)

                    -- Update relative positions after dragging
                    playerFrame.relativeX = playerFrame.xOffset / CThunMapFrame:GetWidth()
                    playerFrame.relativeY = playerFrame.yOffset / CThunMapFrame:GetHeight()
                end)

                local color = classColors[fileName] or { r = 1, g = 1, b = 1 }

                -- Create Font String
                local text = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetPoint("LEFT", playerFrame, "LEFT")
                text:SetJustifyH("LEFT")
                text:SetWidth(150)
                text:SetTextHeight(12)
                text:SetTextColor(color.r, color.g, color.b)
                text:SetShadowOffset(1, -1)

                -- Set player name with group number
                text:SetText(string.format("|cff%02x%02x%02x(%d)|r %s", color.r * 255, color.g * 255, color.b * 255, subgroup, name))

                playerFrame.groupText = text  -- Store the text object for future updates

                CThunMapFrame.playerFrames[name] = playerFrame
                playerIndex = playerIndex + 1
            end
        end

        -- Update the player list initially
        UpdatePlayerList()

        -- Function to update group numbers, add new players, and remove players who leave
        local function UpdateGroupNumbersOnly()
            local numRaidMembers = GetNumRaidMembers()

            -- Create a temporary table to track current raid members
            local currentRaidMembers = {}
                
            -- Loop through current raid members
            for i = 1, numRaidMembers do
                local name, rank, subgroup, level, class, fileName = GetRaidRosterInfo(i)
                currentRaidMembers[name] = true  -- Mark the player as present in the raid

                -- Find the player frame for this raid member
                local playerFrame = CThunMapFrame.playerFrames[name]
                if playerFrame then
                    -- Update just the group number if the frame exists
                    local color = classColors[fileName] or { r = 1, g = 1, b = 1 }
                    playerFrame.groupText:SetText(string.format("|cff%02x%02x%02x(%d)|r %s", color.r * 255, color.g * 255, color.b * 255, subgroup, name))
                else
                    -- If the frame doesn't exist, create a new frame for the player
                    local playerFrame = CreateFrame("Button", nil, CThunMapFrame)
                    playerFrame:SetWidth(150)
                    playerFrame:SetHeight(20)
                    playerFrame.xOffset = 15
                    playerFrame.yOffset = -15 - ((i - 1) * 15)  -- Adjust based on player index
                    playerFrame.relativeX = playerFrame.xOffset / CThunMapFrame:GetWidth()
                    playerFrame.relativeY = playerFrame.yOffset / CThunMapFrame:GetHeight()
                    playerFrame:SetPoint("TOPLEFT", CThunMapFrame, "TOPLEFT", playerFrame.xOffset, playerFrame.yOffset)
                    playerFrame:SetMovable(true)
                    playerFrame:EnableMouse(true)
                    playerFrame:RegisterForDrag("LeftButton")
                    playerFrame.name = name  -- Store the player's name in the frame

                    -- Add drag functionality to move player frames
                    playerFrame:SetScript("OnDragStart", function()
                        playerFrame:StartMoving()
                    end)

                    playerFrame:SetScript("OnDragStop", function() 
                        playerFrame:StopMovingOrSizing()
                        -- Calculate new position relative to the main frame
                        local x, y = playerFrame:GetLeft() - CThunMapFrame:GetLeft(), playerFrame:GetTop() - CThunMapFrame:GetTop()
                        playerFrame.xOffset = x
                        playerFrame.yOffset = y

                        playerFrame:ClearAllPoints()
                        playerFrame:SetPoint("TOPLEFT", CThunMapFrame, "TOPLEFT", playerFrame.xOffset, playerFrame.yOffset)

                        -- Update relative positions after dragging
                        playerFrame.relativeX = playerFrame.xOffset / CThunMapFrame:GetWidth()
                        playerFrame.relativeY = playerFrame.yOffset / CThunMapFrame:GetHeight()
                    end)

                    -- Create Font String
                    local text = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    text:SetPoint("LEFT", playerFrame, "LEFT")
                    text:SetJustifyH("LEFT")
                    text:SetWidth(150)
                    text:SetTextHeight(12)
                    local color = classColors[fileName] or { r = 1, g = 1, b = 1 }
                    text:SetTextColor(color.r, color.g, color.b)
                    text:SetShadowOffset(1, -1)
                    text:SetText(string.format("|cff%02x%02x%02x(%d)|r %s", color.r * 255, color.g * 255, color.b * 255, subgroup, name))

                    playerFrame.groupText = text  -- Store the text object for future updates

                    -- Insert the player frame into the playerFrames table, keyed by the player's name
                    CThunMapFrame.playerFrames[name] = playerFrame
                end
            end

            -- Remove players who are no longer in the raid
            for name, playerFrame in pairs(CThunMapFrame.playerFrames) do
                if not currentRaidMembers[name] then
                    -- The player is no longer in the raid, so hide and remove their frame
                    playerFrame:Hide()
                    CThunMapFrame.playerFrames[name] = nil
                end
            end
        end

        -- Event handler function
        function GroupChangeNotifier_OnEvent()
            if event == "RAID_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
                UpdateGroupNumbersOnly()
            end
        end

        -- Hook into frame size changes to reposition player frames
        CThunMapFrame:SetScript("OnSizeChanged", function()
            for _, playerFrame in pairs(CThunMapFrame.playerFrames) do
                -- Update the position of each player frame based on the new size
                local newX = playerFrame.relativeX * CThunMapFrame:GetWidth()
                local newY = playerFrame.relativeY * CThunMapFrame:GetHeight()
                playerFrame:ClearAllPoints()
                playerFrame:SetPoint("TOPLEFT", CThunMapFrame, "TOPLEFT", newX, newY)
            end
        end)
    else
        -- Toggle the frame visibility
        if CThunMapFrame:IsShown() then
            CThunMapFrame:Hide()
        else
            CThunMapFrame:Show()
        end
    end
end











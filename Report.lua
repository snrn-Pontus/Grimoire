local ADDON_NAME, ns = ...
local Grimoire = ns.core

-- /grimoire report: every planned slot with what it holds, the spell lookups
-- behind it and the last command's output, as plain text in a window you can
-- copy from. Built like Backhand's /backhand diag copy.

ns.report = {}

local function StripMarkup(text)
    text = tostring(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|A.-|a", "")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("||", "|")
    return text
end

local function GetVersion()
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return getMetadata and getMetadata(ADDON_NAME, "Version") or "unknown"
end

local function YesNo(value)
    return value and "yes" or "no"
end

-- Each candidate name with the spell ID the client finds for it, and whether
-- the character knows that spell. A name the client cannot find shows "-".
local function DescribeLookups(names)
    local parts = {}
    for _, name in ipairs(names) do
        local spellID = Grimoire.GetSpellID(name)
        local text
        if not spellID then
            text = name .. " -"
        elseif IsPlayerSpell then
            text = string.format("%s %d %s", name, spellID, IsPlayerSpell(spellID) and "known" or "not known")
        else
            text = string.format("%s %d", name, spellID)
        end
        parts[#parts + 1] = text
    end
    return table.concat(parts, ", ")
end

local BAR_NAMES = { "top", "left", "right", "bottom" }
local BUTTON_NAMES = { "D-Left", "D-Up", "D-Right", "D-Down", "X", "Y", "B", "A" }

local function GetPageableBars()
    local pageUnit = GamepadMainActionBarFrame and GamepadMainActionBarFrame.PageUnit
    local bars = pageUnit and pageUnit.GetPageableActionBarsInIndexOrder and pageUnit:GetPageableActionBarsInIndexOrder()
    return pageUnit, type(bars) == "table" and bars or nil
end

local function GetBarName(bar)
    local _, bars = GetPageableBars()
    for index, pageable in ipairs(bars or {}) do
        if pageable == bar then
            return BAR_NAMES[index]
        end
    end
    return bar and (bar:GetDebugName() or "unnamed") or "none"
end

-- The slot a crossbar button fires: its ID shifted by the action bar page.
local function GetFiredSlot(button)
    local slot = button.action
    if type(slot) ~= "number" and button.CalculateAction then
        slot = button:CalculateAction()
    end
    return type(slot) == "number" and slot or 0
end

-- The last presses of the crossbar's action buttons: which bar the client
-- had active, which button index fired and the slot behind it. Shows what a
-- physical button really does when the screen is hard to read.
local presses = {}
local MAX_PRESSES = 24

-- Hooked on the buttons themselves, so a press is recorded whichever way
-- the client fires it.
local function RecordPress(button, mouseButton, down)
    if down == false then
        return
    end
    local pageUnit = GamepadMainActionBarFrame and GamepadMainActionBarFrame.PageUnit
    local active = pageUnit and pageUnit.GetActiveBar and pageUnit:GetActiveBar()
    local slot = GetFiredSlot(button)
    local holds = slot > 0 and Grimoire.DescribeSlot(slot, { kind = "none" }) or "nothing"
    local left = GamepadMode and GamepadMode.IsLeftModifierDown and GamepadMode.IsLeftModifierDown()
    local right = GamepadMode and GamepadMode.IsRightModifierDown and GamepadMode.IsRightModifierDown()
    table.insert(presses, string.format("%s  LT %s, RT %s, active %s bar: pressed %s bar %s (%s), slot %d, %s",
        date("%H:%M:%S"), YesNo(left), YesNo(right), GetBarName(active), button.grimoireBar,
        BUTTON_NAMES[button.grimoireIndex] or "?", tostring(mouseButton), slot, holds))
    if #presses > MAX_PRESSES then
        table.remove(presses, 1)
    end
end

local hooked = false
local function HookPresses()
    local _, bars = GetPageableBars()
    if hooked or not bars then
        return
    end
    hooked = true
    for barIndex, bar in ipairs(bars) do
        for index = 1, 8 do
            local button = bar:GetActionButtonByIndex(index)
            if button then
                button.grimoireBar = BAR_NAMES[barIndex]
                button.grimoireIndex = index
                button:HookScript("OnClick", RecordPress)
            end
        end
    end
end

local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_LOGIN")
hookFrame:RegisterEvent("ADDON_LOADED")
hookFrame:SetScript("OnEvent", HookPresses)

-- Where a button is drawn, in screen pixels from the top left, to match it
-- with a screenshot.
local function DescribePosition(button)
    if not button:IsVisible() then
        return "hidden"
    end
    local x, y = button:GetCenter()
    if not x then
        return "no position"
    end
    local width, height = GetPhysicalScreenSize()
    local scale = button:GetEffectiveScale()
    local pixelsPerUnitX = width / (GetScreenWidth() * UIParent:GetEffectiveScale())
    local pixelsPerUnitY = height / (GetScreenHeight() * UIParent:GetEffectiveScale())
    return string.format("at %d,%d", x * scale * pixelsPerUnitX, height - y * scale * pixelsPerUnitY)
end

local function BuildLines()
    local gameVersion, build, _, interface = GetBuildInfo()
    local _, race = UnitRace("player")
    local _, class = UnitClass("player")
    local lines = {
        string.format("Grimoire %s report", GetVersion()),
        string.format("Client: %s (build %s, interface %s)", tostring(gameVersion), tostring(build), tostring(interface)),
        string.format("Character: level %d %s %s", UnitLevel("player") or 0, tostring(race), tostring(class)),
        string.format("Action bar page: %d%s", Grimoire.GetActionBarPage(),
            Grimoire.GetActionBarPage() ~= 1 and " (not 1: the crossbar fires other slots than the plan)" or ""),
        string.format("Backhand: loaded %s, paddle slots %s, fill paddles %s",
            YesNo(Grimoire.IsAddOnLoaded("Backhand")), YesNo(Grimoire.HasPaddleSlots()), YesNo(GrimoireDB.fillPaddles)),
        string.format("Rummage: loaded %s", YesNo(Grimoire.IsAddOnLoaded("Rummage"))),
        string.format("Options: clear unlearned %s, update macros %s, auto apply %s",
            YesNo(GrimoireDB.clearUnlearned), YesNo(GrimoireDB.updateMacros), YesNo(GrimoireDB.autoApply)),
        "",
        "Macros:",
    }

    local macroNames = {}
    for name in pairs(Grimoire.MACROS) do
        macroNames[#macroNames + 1] = name
    end
    table.sort(macroNames)
    for _, name in ipairs(macroNames) do
        local index = GetMacroIndexByName(name)
        if index and index > 0 then
            local _, icon = GetMacroInfo(index)
            lines[#lines + 1] = string.format("  %s: #%d, icon %s", name, index, tostring(icon))
        else
            lines[#lines + 1] = string.format("  %s: missing", name)
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Slots (OK, or DIFF when the slot holds something else):"
    if not GamepadActionBarBindingUtil then
        lines[#lines + 1] = "  The native gamepad crossbar is not loaded. Switch to gamepad mode first."
    else
        local currentLayer
        local ok, err = pcall(Grimoire.ForEachEntry, function(layer, label, slot, action)
            if layer ~= currentLayer then
                currentLayer = layer
                lines[#lines + 1] = Grimoire.LAYER_LABEL[layer]
            end
            local holds, matches = "no slot", false
            if slot then
                holds, matches = Grimoire.DescribeSlot(slot, action)
            end
            lines[#lines + 1] = string.format("  %s %s (slot %s): planned %s, has %s",
                matches and "OK  " or "DIFF", label, tostring(slot), Grimoire.Describe(action), holds)
            if action.kind == "spell" then
                lines[#lines + 1] = "        lookup: " .. DescribeLookups(action.names)
            end
        end)
        if not ok then
            lines[#lines + 1] = "  Error while reading the slots: " .. tostring(err)
        end
    end

    -- What the client's own crossbar buttons point at, to compare with the
    -- slots above when the screen and the plan disagree.
    local pageUnit, bars = GetPageableBars()
    if bars then
        lines[#lines + 1] = ""
        lines[#lines + 1] = string.format("Crossbar buttons (page %s, bars in client order):", tostring(pageUnit:GetCurrentPage()))
        for barIndex, bar in ipairs(bars) do
            lines[#lines + 1] = string.format("%s bar, shown %s", BAR_NAMES[barIndex] or tostring(barIndex), YesNo(bar.IsShown and bar:IsShown()))
            for i = 1, 8 do
                local button = bar.GetActionButtonByIndex and bar:GetActionButtonByIndex(i)
                if button then
                    local id = button.GetID and button:GetID() or 0
                    local slot = id > 0 and GetFiredSlot(button) or 0
                    local holds = "nothing"
                    if slot > 0 then
                        holds = Grimoire.DescribeSlot(slot, { kind = "none" })
                    end
                    lines[#lines + 1] = string.format("  %d %s: unit slot %s, ID %d, fires slot %d, %s, %s",
                        i, BUTTON_NAMES[i], tostring(button.pageUnitSlotID), id, slot, holds, DescribePosition(button))
                end
            end
        end
    end

    -- The client's other bars on the crossbar (targeting, shortcuts, stance,
    -- possess), which Grimoire does not fill, with where their buttons are.
    if pageUnit and type(pageUnit.actionBars) == "table" then
        local names = {}
        for name, bar in pairs(pageUnit.actionBars) do
            local pageable = false
            for _, pageableBar in ipairs(bars or {}) do
                pageable = pageable or pageableBar == bar
            end
            if not pageable then
                names[#names + 1] = name
            end
        end
        table.sort(names)
        local width, height = GetPhysicalScreenSize()
        lines[#lines + 1] = ""
        lines[#lines + 1] = string.format("Other crossbar bars (screen %dx%d):", width, height)
        for _, name in ipairs(names) do
            local bar = pageUnit.actionBars[name]
            lines[#lines + 1] = string.format("%s, shown %s", name, YesNo(bar:IsVisible()))
            for _, group in ipairs({ "Left", "Right" }) do
                for i = 1, 4 do
                    local button = bar[group] and bar[group]["ActionButton" .. i]
                    if button and button:IsVisible() then
                        local slot = button.GetID and button:GetID() or 0
                        lines[#lines + 1] = string.format("  %s %d: slot %d, %s, %s", group, i, slot,
                            slot > 0 and Grimoire.DescribeSlot(slot, { kind = "none" }) or "no slot", DescribePosition(button))
                    end
                end
            end
        end
    end

    -- Which controller buttons the client binds to action buttons 1-8.
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Bindings of the crossbar's action buttons:"
    for index = 1, 8 do
        local keys = { GetBindingKey("GAMEPADACTIONBUTTON" .. index) }
        lines[#lines + 1] = string.format("  %d (%s): %s", index, BUTTON_NAMES[index],
            #keys > 0 and table.concat(keys, ", ") or "none")
    end

    lines[#lines + 1] = ""
    if not hooked then
        lines[#lines + 1] = "Button presses: not recorded, the crossbar was not loaded."
    elseif #presses == 0 then
        lines[#lines + 1] = "Button presses: none yet. Press some buttons, then Refresh."
    else
        lines[#lines + 1] = "Button presses (oldest first):"
        for _, line in ipairs(presses) do
            lines[#lines + 1] = "  " .. line
        end
    end

    lines[#lines + 1] = ""
    local output = Grimoire.output
    if #output == 0 then
        lines[#lines + 1] = "Last command: none yet this session."
    else
        lines[#lines + 1] = "Last command: " .. tostring(output.command)
        for _, line in ipairs(output) do
            lines[#lines + 1] = StripMarkup(line)
        end
    end
    return lines
end

local reportFrame

local function EnsureFrame()
    if reportFrame then
        return reportFrame
    end

    local frame = CreateFrame("Frame", "GrimoireReportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(720, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -18)
    frame.title:SetText("Grimoire report")

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.hint:SetPoint("TOPLEFT", 24, -44)
    frame.hint:SetWidth(672)
    frame.hint:SetJustifyH("LEFT")
    frame.hint:SetText("Click Select All, then press Ctrl+C to copy the report. Run /grimoire apply or check first to include its output.")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 24, -66)
    scrollFrame:SetPoint("BOTTOMRIGHT", -44, 48)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(646)
    editBox:SetMaxLetters(0)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        frame:Hide()
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    -- Read-only: typing into the box restores the report.
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and frame.text then
            self:SetText(frame.text)
            self:HighlightText()
        end
    end)
    scrollFrame:SetScrollChild(editBox)
    frame.editBox = editBox

    -- Clicking anywhere in the text area focuses the box and selects everything.
    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)

    function frame:Refresh()
        self.text = table.concat(BuildLines(), "\n")
        self.editBox:SetText(self.text)
        self.editBox:SetCursorPosition(0)
        if self.editBox:HasFocus() then
            self.editBox:HighlightText()
        end
    end

    local refresh = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refresh:SetSize(100, 22)
    refresh:SetPoint("BOTTOMLEFT", 22, 16)
    refresh:SetText("Refresh")
    refresh:SetScript("OnClick", function()
        frame:Refresh()
    end)

    local selectAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectAll:SetSize(100, 22)
    selectAll:SetPoint("LEFT", refresh, "RIGHT", 8, 0)
    selectAll:SetText("Select All")
    selectAll:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetSize(100, 22)
    close:SetPoint("BOTTOMRIGHT", -22, 16)
    close:SetText("Close")
    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:SetScript("OnHide", function()
        editBox:ClearFocus()
    end)

    -- Escape closes it like other dialogs.
    table.insert(UISpecialFrames, "GrimoireReportFrame")

    frame:Hide()
    reportFrame = frame
    return frame
end

function ns.report.Show()
    local frame = EnsureFrame()
    frame:Show()
    frame:Refresh()
end

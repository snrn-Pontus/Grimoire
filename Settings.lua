local _, ns = ...
local Grimoire = ns.core

-- Settings > AddOns > Grimoire.
--
-- Forever hangs when the Settings window is closed with the controller after
-- the gamepad cursor (SmartNavigation) has picked up addon-created controls,
-- and Blizzard's vertical-layout settings list triggers that on its own. So,
-- as in Rummage and Tally, this page is a canvas built once at login from
-- plain widgets and never announced to the cursor.

ns.settings = {}
local controls = {}
local registered = false
local panel

local function PanelVisible()
    return panel and panel:IsVisible()
end

local function AttachTooltip(control, title, text)
    control:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if text then
            GameTooltip:AddLine(text, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)
    control:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateCheckbox(parent, key, labelText, tooltip, y)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 4, y)
    check:SetSize(26, 26)
    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    check.label:SetText(labelText)
    check:SetScript("OnClick", function(self)
        Grimoire.Set(key, self:GetChecked() and true or false)
    end)
    if tooltip then
        AttachTooltip(check, labelText, tooltip)
    end
    check.Refresh = function()
        check:SetChecked(GrimoireDB[key] and true or false)
    end
    controls[#controls + 1] = check
    return y - 30
end

local function CreateHeader(parent, text, y)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 1, 1, 0.15)
    divider:SetPoint("TOPLEFT", 6, y)
    divider:SetSize(540, 1)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 6, y - 10)
    header:SetText(text)
    return y - 32
end

local function StatusText()
    local paddles
    if not Grimoire.IsAddOnLoaded("Backhand") then
        paddles = "Backhand not loaded, only the crossbar is filled."
    elseif not Grimoire.HasPaddleSlots() then
        paddles = "Backhand has no paddle slots on this character yet, only the crossbar is filled."
    elseif GrimoireDB.fillPaddles then
        paddles = "Backhand paddle slots found."
    else
        paddles = "Backhand paddle slots found, but turned off below."
    end
    local smart = Grimoire.IsAddOnLoaded("Rummage") and "Rummage loaded, its Smart macros fill the consumable slots."
        or "Rummage not loaded, the consumable slots are left as they are."
    return paddles .. "\n" .. smart
end

function ns.settings.Refresh()
    if not PanelVisible() then
        return
    end
    for _, control in ipairs(controls) do
        control.Refresh()
    end
    if controls.status then
        controls.status:SetText(StatusText())
    end
end

function ns.settings.Register()
    if registered or not Settings or type(Settings.RegisterCanvasLayoutCategory) ~= "function" then
        return
    end
    registered = true

    -- Hidden until the Settings window displays it, so OnShow always fires.
    panel = CreateFrame("Frame")
    panel.name = "Grimoire"
    panel:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 1)
    scrollFrame:SetScrollChild(content)

    local y = -6
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 6, y)
    title:SetText("Grimoire")
    y = y - 26

    local note = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 6, y)
    note:SetWidth(540)
    note:SetJustifyH("LEFT")
    note:SetText("Lays out an Affliction Warlock on the gamepad crossbar and, with Backhand, its paddles. The buttons below do the same as /grimoire, /grimoire apply, /grimoire check and /grimoire report; the first three print in chat, the report opens as text you can copy. With a controller, use the mouse on this page: the gamepad cursor cannot enter it without freezing Forever when Settings is closed.")
    y = y - (note:GetStringHeight() + 12)

    local status = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    status:SetPoint("TOPLEFT", 6, y)
    status:SetWidth(540)
    status:SetJustifyH("LEFT")
    controls.status = status
    y = y - 40

    y = CreateHeader(content, "Layout", y)
    local buttons = {
        { text = "Show plan", func = Grimoire.Preview, tooltip = "Prints every planned slot in chat, with its action slot number." },
        { text = "Apply layout", func = Grimoire.Apply, tooltip = "Places the layout on the crossbar and paddles. Whatever was in those slots is replaced." },
        { text = "Check slots", func = Grimoire.Check, tooltip = "Compares every slot with the plan and lists the ones that differ." },
        { text = "Copy report", func = ns.report.Show, tooltip = "Opens every slot, the spell lookups behind it and the last command's output as text you can select and copy (Ctrl+C). Same as /grimoire report." },
    }
    local previous
    for _, info in ipairs(buttons) do
        local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        button:SetSize(126, 24)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 8, 0)
        else
            button:SetPoint("TOPLEFT", 6, y)
        end
        button:SetText(info.text)
        button:SetScript("OnClick", function()
            info.func()
            ns.settings.Refresh()
        end)
        AttachTooltip(button, info.text, info.tooltip)
        previous = button
    end
    y = y - 36

    y = CreateHeader(content, "Options", y)
    y = CreateCheckbox(content, "fillPaddles", "Fill Backhand's paddles", "Places the P1-P4 actions of each layer in the paddle slots Backhand reserved for this character. Turn off to leave the paddles as they are and fill only the crossbar.", y)
    y = CreateCheckbox(content, "clearUnlearned", "Empty slots for spells not learned yet", "A slot whose planned spell you do not know yet is cleared, so an action from an older layout does not stay behind looking like part of this one. Turn off to leave those slots as they are until the spell is learned.", y)
    y = CreateCheckbox(content, "updateMacros", "Update the WL macros", "Rewrites the text and icon of existing WL macros on every apply. Turn off to keep your own edits; missing macros are still created.", y)
    y = CreateCheckbox(content, "autoApply", "Apply again after learning a spell", "On a Warlock, the layout is applied again a moment after you learn a new spell (after combat, if you are fighting), so new ranks and upgrades like Demon Armor land on their slots without typing /grimoire apply. Slots you changed by hand are overwritten too.", y)

    content:SetHeight(-y + 10)

    -- Deliberately not announced to the gamepad cursor (SmartNavigation):
    -- the controls exist from login and are only reparented into the
    -- Settings window, so the cursor never picks them up on its own.
    panel:SetScript("OnShow", ns.settings.Refresh)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    ns.settings.category = category
end

function ns.settings.Open()
    if not registered then
        ns.settings.Register()
    end
    if ns.settings.category and Settings and type(Settings.OpenToCategory) == "function" then
        Settings.OpenToCategory(ns.settings.category:GetID())
    end
end

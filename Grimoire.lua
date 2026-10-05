-- Grimoire places an Affliction Warlock leveling layout (up to the level 30
-- beta cap) on Forever's native gamepad crossbar and, when Backhand is
-- installed, on its P1-P4 paddle slots. /grimoire prints the plan,
-- /grimoire apply places it. Settings.lua draws the options page.

local ADDON_NAME, ns = ...

local Grimoire = {}
ns.core = Grimoire

local function Print(fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or fmt
    print("|cff7fd8ffGrimoire|r: " .. msg)
end

--------------------------------------------------------------------------------
-- Saved variables
--------------------------------------------------------------------------------

local DEFAULTS = {
    fillPaddles = true,     -- with Backhand: fill its P1-P4 slots too
    clearUnlearned = true,  -- empty a slot whose planned spell is not learned yet
    updateMacros = true,    -- rewrite existing WL macros; off keeps your edits
    autoApply = false,      -- apply again after learning a new spell
}

local function InitSavedVariables()
    GrimoireDB = GrimoireDB or {}
    for key, value in pairs(DEFAULTS) do
        if GrimoireDB[key] == nil then
            GrimoireDB[key] = value
        end
    end
end

function Grimoire.Set(key, value)
    GrimoireDB[key] = value
    if ns.settings and ns.settings.Refresh then
        ns.settings.Refresh()
    end
end

-- Crossbar bar order (GamepadActionBarPageUnit pageableActionBarsIndexOrder):
-- top = no trigger, left = LT, right = RT, bottom = LT + RT.
-- Button order inside a bar (Bindings.xml): 1 D-Left, 2 D-Up, 3 D-Right,
-- 4 D-Down, 5 X, 6 Y, 7 B, 8 A. Base layer 5-8 are reserved by the client.
local BAR = { base = 0, lt = 1, rt = 2, both = 3 }
local BUTTON = { DL = 1, DU = 2, DR = 3, DD = 4, X = 5, Y = 6, B = 7, A = 8 }
local BACKHAND_PANEL = { base = 1, lt = 2, rt = 3, both = 4 }

-- Macros the layout creates (per character). Names stay under 16 characters.
local MACROS = {
    ["WL Corruption"] = "#showtooltip Corruption\n/petattack\n/cast Corruption",
    ["WL PetAttack"] = "/petattack",
    ["WL PetFollow"] = "/petfollow",
    ["WL PetPassive"] = "/petpassive",
    ["WL Torment"] = "#showtooltip\n/cast [pet:Voidwalker] Torment",
    ["WL Sacrifice"] = "#showtooltip\n/cast [pet:Voidwalker] Sacrifice",
    ["WL PetAbility"] = "#showtooltip\n/cast [pet:Voidwalker] Suffering; [pet:Imp] Phase Shift; [pet:Succubus] Lash of Pain; [pet:Felhunter] Devour Magic",
    ["WL PetCC"] = "#showtooltip\n/cast [pet:Succubus] Seduction; [pet:Felhunter] Spell Lock",
    -- The beta caps at level 30: Lesser is the best healthstone and soulstone.
    ["WL Healthstone"] = "#showtooltip\n/use Lesser Healthstone\n/use Minor Healthstone",
    ["WL UseSoulstn"] = "#showtooltip\n/use [@player] Lesser Soulstone\n/use [@player] Minor Soulstone",
}

-- Every macro gets a fixed icon. The "?" icon only resolves to a real one
-- when #showtooltip finds a usable spell, which the pet macros do not have
-- while that pet is not summoned.
local MACRO_ICONS = {
    ["WL Corruption"] = { spell = "Corruption" },
    ["WL PetAttack"] = { path = "Ability_GhoulFrenzy" },
    ["WL PetFollow"] = { path = "Ability_Tracking" },
    ["WL PetPassive"] = { path = "Ability_Seal" },
    ["WL Torment"] = { spell = 3716 },
    ["WL Sacrifice"] = { spell = 7812 },
    ["WL PetAbility"] = { spell = 17735 }, -- Suffering
    ["WL PetCC"] = { spell = 6358 }, -- Seduction
    ["WL Healthstone"] = { item = 5511 }, -- Lesser Healthstone
    ["WL UseSoulstn"] = { item = 5232 }, -- Minor Soulstone
}

local FALLBACK_ICON = "INV_MISC_QUESTIONMARK"

local function ResolveIcon(name)
    local spec = MACRO_ICONS[name]
    local icon
    if not spec then
        return FALLBACK_ICON
    elseif spec.spell then
        icon = (C_Spell and C_Spell.GetSpellTexture or GetSpellTexture)(spec.spell)
    elseif spec.item then
        icon = (C_Item and C_Item.GetItemIconByID or GetItemIcon)(spec.item)
    elseif spec.path then
        icon = GetFileIDFromPath and GetFileIDFromPath("Interface\\Icons\\" .. spec.path) or spec.path
    end
    if not icon then
        Print("No icon found for %s, it will show a question mark.", name)
    end
    return icon or FALLBACK_ICON
end

-- kind: spell (list of candidate names, first known wins), macro, item.
-- R is one of Rummage's Smart macros: only placed while Rummage is loaded.
local function S(...) return { kind = "spell", names = { ... } } end
local function M(name) return { kind = "macro", name = name } end
local function R(name) return { kind = "macro", name = name, addon = "Rummage" } end
local function I(itemID, label) return { kind = "item", itemID = itemID, label = label } end

local LAYOUT = {
    base = {
        buttons = {
            DL = S("Shadow Bolt"),
            DU = S("Drain Soul"),
            DR = S("Fear"),
            DD = S("Shoot"),
        },
        paddles = { M("WL Corruption"), S("Bane of Agony", "Curse of Agony"), S("Drain Life"), S("Life Tap") },
    },
    lt = {
        buttons = {
            -- Siphon Life (talent, 29) takes over from Searing Pain once learned.
            X = S("Siphon Life", "Searing Pain"),
            Y = S("Health Funnel"),
            B = S("Curse of Weakness"),
            A = S("Immolate"),
            DU = M("WL PetAttack"),
            DD = M("WL PetFollow"),
            DL = R("SmartManaPotion"),
            DR = S("Rain of Fire"),
        },
        paddles = { M("WL Healthstone"), R("SmartHealthPotion"), M("WL Torment"), M("WL Sacrifice") },
    },
    rt = {
        buttons = {
            X = S("Summon Voidwalker"),
            -- The Felhunter (30) replaces the Imp once learned.
            Y = S("Summon Felhunter", "Summon Imp"),
            B = S("Summon Succubus"),
            A = S("Demon Armor", "Demon Skin"),
            DL = S("Eye of Kilrogg"),
            DU = S("Unending Breath"),
            DR = S("Sense Demons"),
            DD = R("SmartQuestItem"),
        },
        paddles = { M("WL PetAbility"), M("WL PetCC"), M("WL PetPassive"),
            -- Forever renames or moves some curses; the first one known wins.
            S("Curse of Recklessness", "Curse of Tongues", "Curse of Exhaustion", "Drain Mana") },
    },
    both = {
        buttons = {
            X = S("Create Healthstone (Lesser)", "Create Healthstone (Minor)"),
            Y = S("Create Soulstone (Lesser)", "Create Soulstone (Minor)"),
            B = S("Ritual of Summoning"),
            A = S("Banish"),
            DU = R("SmartBandage"),
            DR = S("Enslave Demon"),
            DD = R("SmartFood"),
            DL = R("SmartFlask"),
        },
        -- No Warlock mount before the level 30 cap, so P1 holds Hellfire (30).
        paddles = { S("Hellfire"), I(6948, "Hearthstone"), R("SmartDrink"), M("WL UseSoulstn") },
    },
}

local LAYER_LABEL = { base = "Base", lt = "LT", rt = "RT", both = "LT+RT" }
local LAYER_ORDER = { "base", "lt", "rt", "both" }
local BUTTON_ORDER = { "DU", "DR", "DD", "DL", "X", "Y", "B", "A" }
local BUTTON_LABEL = { DU = "D-Up", DR = "D-Right", DD = "D-Down", DL = "D-Left", X = "X", Y = "Y", B = "B", A = "A" }

local function Describe(action)
    if action.kind == "spell" then
        return table.concat(action.names, " / ")
    elseif action.kind == "macro" then
        return "macro " .. action.name
    end
    return action.label
end

local function GetSpellID(name)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(name)
        return info and info.spellID
    elseif GetSpellInfo then
        return (select(7, GetSpellInfo(name)))
    end
end

-- Picking up a spell the character has not learned leaves the cursor empty,
-- so the first candidate that lands on the cursor is the one to use.
local function PickUpFirstKnownSpell(names)
    local pickup = (C_Spell and C_Spell.PickupSpell) or PickupSpell
    for _, name in ipairs(names) do
        local spellID = GetSpellID(name)
        if spellID then
            ClearCursor()
            pickup(spellID)
            if GetCursorInfo() then
                return true
            end
        end
    end
    return false
end

local function PickUp(action)
    if action.kind == "spell" then
        if not PickUpFirstKnownSpell(action.names) then
            return false, "not learned yet"
        end
    elseif action.kind == "macro" then
        local index = GetMacroIndexByName(action.name)
        if not index or index == 0 then
            return false, "macro missing"
        end
        PickupMacro(index)
    else
        local pickup = (C_Item and C_Item.PickupItem) or PickupItem
        pickup(action.itemID)
    end
    if not GetCursorInfo() then
        return false, "could not pick up"
    end
    return true
end

local function GetCrossbarSlot(layer, buttonKey)
    local page = 1
    local pageUnit = GamepadMainActionBarFrame and GamepadMainActionBarFrame.PageUnit
    if pageUnit and pageUnit.GetCurrentPage then
        page = pageUnit:GetCurrentPage() or 1
    end
    local pageUnitSlotID = BAR[layer] * 8 + BUTTON[buttonKey]
    return GamepadActionBarBindingUtil.GetGamepadStorageSlotIndexFromPageAndPageUnitSlotID(page, pageUnitSlotID)
end

local function IsAddOnLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    end
    return _G.IsAddOnLoaded and _G.IsAddOnLoaded(name)
end
Grimoire.IsAddOnLoaded = IsAddOnLoaded

-- An action that needs a sibling addon is left out while that addon is not
-- loaded. Its slot is left as it is: old Smart macros from an uninstalled
-- Rummage call Rummage and would error, and you may have put your own food
-- or potions there.
local function IsAvailable(action)
    return not action.addon or IsAddOnLoaded(action.addon)
end

local function PrintUnavailable(count)
    if count > 0 then
        Print("Rummage is not loaded: the %d food, drink, potion, bandage, flask and quest item slots are left as they are.", count)
    end
end

local function GetPaddleSlot(layer, paddle)
    local slots = BackhandCharDB and BackhandCharDB.nativeSlots
    if type(slots) ~= "table" then
        return nil
    end
    return slots[(BACKHAND_PANEL[layer] - 1) * 4 + paddle]
end

-- Backhand creates nativeSlots empty and fills all 16 only once it has
-- reserved them; until then (or when it keeps a profile on its own saved
-- actions) the paddles have no action slots to place into.
local function HasPaddleSlots()
    if not IsAddOnLoaded("Backhand") or type(BackhandCharDB) ~= "table" then
        return false
    end
    local slots = BackhandCharDB.nativeSlots
    if type(slots) ~= "table" or #slots ~= 16 then
        return false
    end
    for _, slot in ipairs(slots) do
        if type(slot) ~= "number" then
            return false
        end
    end
    return true
end
Grimoire.HasPaddleSlots = HasPaddleSlots

local function UsePaddles()
    return GrimoireDB.fillPaddles and HasPaddleSlots()
end

local function EnsureMacros()
    local missing = {}
    for name in pairs(MACROS) do
        local index = GetMacroIndexByName(name)
        if index and index > 0 then
            if GrimoireDB.updateMacros then
                EditMacro(index, name, ResolveIcon(name), MACROS[name])
            end
        else
            missing[#missing + 1] = name
        end
    end
    table.sort(missing)

    local _, numPerChar = GetNumMacros()
    local free = (MAX_CHARACTER_MACROS or 18) - (numPerChar or 0)
    if #missing > free then
        Print("Need %d free character macro slots, only %d left. Delete a few in /macro and try again.", #missing, free)
        return false
    end

    for _, name in ipairs(missing) do
        local ok, err = pcall(CreateMacro, name, ResolveIcon(name), MACROS[name], true)
        if not ok then
            Print("Could not create macro %s: %s", name, tostring(err))
            return false
        end
    end
    if #missing > 0 then
        Print("Created %d macros (WL ...).", #missing)
    end
    return true
end

local function Place(slot, action)
    ClearCursor()
    local ok, reason = PickUp(action)
    if not ok then
        ClearCursor()
        return false, reason
    end
    PlaceAction(slot)
    ClearCursor()
    return true
end

-- Returns how many planned slots were left out because their addon is not
-- loaded.
local function ForEachEntry(func)
    local unavailable = 0
    local function Visit(layer, label, slot, action)
        if not action then
            return
        elseif IsAvailable(action) then
            func(layer, label, slot, action)
        else
            unavailable = unavailable + 1
        end
    end
    for _, layer in ipairs(LAYER_ORDER) do
        local layout = LAYOUT[layer]
        for _, key in ipairs(BUTTON_ORDER) do
            local action = layout.buttons[key]
            if action then
                Visit(layer, BUTTON_LABEL[key], GetCrossbarSlot(layer, key), action)
            end
        end
        -- Paddles need Backhand's reserved slots; without Backhand, or with
        -- paddles turned off in the settings, only the crossbar is filled.
        for paddle = 1, UsePaddles() and 4 or 0 do
            Visit(layer, "P" .. paddle, GetPaddleSlot(layer, paddle), layout.paddles[paddle])
        end
    end
    return unavailable
end

local function Preview()
    Print("Planned layout (type /grimoire apply to place it):")
    local currentLayer
    local unavailable = ForEachEntry(function(layer, label, slot, action)
        if layer ~= currentLayer then
            currentLayer = layer
            print("|cffffd100" .. LAYER_LABEL[layer] .. "|r")
        end
        print(string.format("  %s: %s  (slot %s)", label, Describe(action), tostring(slot)))
    end)
    PrintUnavailable(unavailable)
end

-- quiet (automatic apply after learning a spell) prints one summary line
-- instead of the list of skipped slots.
local function Apply(quiet)
    if InCombatLockdown() then
        Print("Cannot change action slots in combat.")
        return
    end
    if not GamepadActionBarBindingUtil then
        if not quiet then
            Print("The native gamepad crossbar is not loaded. Switch to gamepad mode first.")
        end
        return
    end
    if GrimoireDB.fillPaddles and not HasPaddleSlots() and not quiet then
        if IsAddOnLoaded("Backhand") then
            Print("Backhand has no paddle slots on this character yet; only the crossbar is filled.")
        else
            Print("Backhand is not loaded; only the crossbar is filled.")
        end
    end
    if not EnsureMacros() then
        return
    end

    local placed, skipped = 0, {}
    local unavailable = ForEachEntry(function(layer, label, slot, action)
        local where = LAYER_LABEL[layer] .. " " .. label
        if not slot or not C_GamepadUI.IsValidGamepadActionStorageSlotIndex(slot) then
            skipped[#skipped + 1] = where .. " (" .. Describe(action) .. "): no valid slot"
            return
        end
        local ok, reason = Place(slot, action)
        if ok then
            placed = placed + 1
        else
            -- Clear the slot so an action from an older layout does not stay
            -- behind looking like part of this one.
            if GrimoireDB.clearUnlearned and C_ActionBar.HasAction(slot) then
                PickupAction(slot)
                ClearCursor()
                reason = reason .. ", old action cleared"
            end
            skipped[#skipped + 1] = where .. " (" .. Describe(action) .. "): " .. reason
        end
    end)

    if quiet then
        Print("Learned a new spell; layout applied again (%d actions placed).", placed)
        return
    end
    Print("Placed %d actions.", placed)
    for _, line in ipairs(skipped) do
        print("  skipped " .. line)
    end
    PrintUnavailable(unavailable)
    if #skipped > 0 then
        Print("Run /grimoire apply again after learning a spell or summoning that pet.")
    end
end

local function GetSpellNameByID(spellID)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end
    return GetSpellInfo and (GetSpellInfo(spellID))
end

-- What a slot holds, as text, and whether it is the planned action.
local function DescribeSlot(slot, action)
    local actionType, id = GetActionInfo(slot)
    if not actionType then
        return "empty", false
    elseif actionType == "spell" then
        local name = GetSpellNameByID(id) or ("spell " .. tostring(id))
        return name, action.kind == "spell" and tContains(action.names, name)
    elseif actionType == "macro" then
        local name = GetActionText(slot) or (GetMacroInfo(id)) or ("macro " .. tostring(id))
        return "macro " .. name, action.kind == "macro" and name == action.name
    elseif actionType == "item" then
        local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) or ("item " .. tostring(id))
        return name, action.kind == "item" and id == action.itemID
    end
    return actionType .. " " .. tostring(id), false
end

local function Check()
    local matched, problems = 0, {}
    local unavailable = ForEachEntry(function(layer, label, slot, action)
        local where = LAYER_LABEL[layer] .. " " .. label
        if not slot then
            problems[#problems + 1] = where .. ": no slot"
            return
        end
        local holds, ok = DescribeSlot(slot, action)
        if ok then
            matched = matched + 1
        else
            problems[#problems + 1] = string.format("%s: planned %s, has %s", where, Describe(action), holds)
        end
    end)

    Print("%d slots match the plan.", matched)
    for _, line in ipairs(problems) do
        print("  " .. line)
    end
    PrintUnavailable(unavailable)
    if #problems > 0 then
        Print("Spells you have not learned yet show up here too; /grimoire apply fills them once you have them.")
    end
end

Grimoire.Preview = Preview
Grimoire.Apply = Apply
Grimoire.Check = Check

local function PrintHelp()
    Print("Commands:")
    print("  /grimoire          show the planned layout")
    print("  /grimoire apply    place it on the crossbar and paddles")
    print("  /grimoire check    compare every slot with the plan")
    print("  /grimoire config   open the settings")
    print("  /grimoire help     this list")
end

SLASH_GRIMOIRE1 = "/grimoire"
SLASH_GRIMOIRE2 = "/grim"
SlashCmdList.GRIMOIRE = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "apply" then
        Apply()
    elseif msg == "check" then
        Check()
    elseif msg == "config" or msg == "options" or msg == "settings" then
        if ns.settings and ns.settings.Open then
            ns.settings.Open()
        end
    elseif msg == "help" then
        PrintHelp()
    else
        Preview()
    end
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

-- A trainer visit teaches several spells in a row, and in combat nothing can
-- be placed, so learning a spell only marks the layout as due.
local applyPending = false

local function ApplyIfPending()
    if not applyPending or InCombatLockdown() then
        return
    end
    applyPending = false
    Apply(true)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(frame.RegisterEvent, frame, "LEARNED_SPELL_IN_SKILL_LINE")
pcall(frame.RegisterEvent, frame, "LEARNED_SPELL_IN_TAB")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            InitSavedVariables()
        end
    elseif event == "PLAYER_LOGIN" then
        if ns.settings and ns.settings.Register then
            ns.settings.Register()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        ApplyIfPending()
    elseif GrimoireDB and GrimoireDB.autoApply and select(2, UnitClass("player")) == "WARLOCK" then
        if not applyPending then
            applyPending = true
            C_Timer.After(1, ApplyIfPending)
        end
    end
end)

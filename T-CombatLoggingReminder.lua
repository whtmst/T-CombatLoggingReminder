-- T-CombatLoggingReminder.lua
local raids = {}
raids["Molten Core"] = true
raids["Blackwing Lair"] = true
raids["Zul'Gurub"] = true
raids["Ahn'Qiraj"] = true
raids["Onyxia's Lair"] = true
raids["Ruins of Ahn'Qiraj"] = true
raids["Temple of Ahn'Qiraj"] = true
raids["Naxxramas"] = true
raids["The Upper Necropolis"] = true
raids["Emerald Sanctum"] = true
raids["Tower of Karazhan"] = true
raids["???"] = true

local function T_IsInRaid()
    return UnitInRaid("player") == 1
end

local T_IsRaidInstance = function()
    if not IsInInstance() then
        return false
    end
    local zoneName = GetRealZoneText()
    return zoneName and raids[zoneName] == true
end

local T_lastZone = nil
local function T_IsEnteringRaid()
    local currentZone = GetRealZoneText()
    local isEntering = currentZone and currentZone ~= T_lastZone and raids[currentZone] and T_IsInRaid()
    T_lastZone = currentZone
    return isEntering
end

local function T_EnableCombatLogging()
    LoggingCombat(1)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r |cFF00FF00Combat Logging Enabled|r")
end

local function T_DisableCombatLogging()
    LoggingCombat(0)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r |cFFFF0000Combat Logging Disabled|r")
end

local function T_HandlePlayerEnteringWorld(self, event, isLogin, isReload)
    if T_IsEnteringRaid() and LoggingCombat() ~= 1 then
        StaticPopup_Show("T_ENABLE_COMBAT_LOGGING")
    end
    
    if not T_IsInRaid() and LoggingCombat() == 1 then
        T_DisableCombatLogging()
    end
end

local T_EventFrame = CreateFrame("Frame", "T_EventFrame")
T_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
T_EventFrame:SetScript("OnEvent", T_HandlePlayerEnteringWorld)

StaticPopupDialogs["T_ENABLE_COMBAT_LOGGING"] = {
    text = "|cFF11A6ECT-CombatLoggingReminder:|r Would you like to enable Combat Logging?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = T_EnableCombatLogging,
    timeout = 30,
    whileDead = true,
    hideOnEscape = true
}

local function T_OnPlayerLogin()
    local title = "T-CombatLoggingReminder"
    local notes = "Automatically reminds you to enable combat logging when entering raids and disables it when leaving."
    local loaded = "|cFF11A6ECT-CombatLoggingReminder|r - |cFF00FF00Successfully loaded!|r"
    
    DEFAULT_CHAT_FRAME:AddMessage(loaded)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r " .. notes)
end

T_EventFrame:RegisterEvent("PLAYER_LOGIN")
T_EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        T_OnPlayerLogin()
    elseif event == "PLAYER_ENTERING_WORLD" then
        T_HandlePlayerEnteringWorld(self, event, ...)
    end
end)

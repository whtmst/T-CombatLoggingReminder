--[[
	T-CombatLoggingReminder v1.0 RU Remaster for Turtle WoW
	Оригинальный автор: Михаил Палагин (Wht Mst)
	Основан на: Combat Logging Reminder
	GitHub: https://github.com/whtmst/T-CombatLoggingReminder
	
	Аддон для автоматического напоминания о включении записи боя при входе в рейды
	и автоматического выключения при выходе из рейда.
	Последнее обновление: v1.0
	Протестировано для: Turtle WoW
]]--

-- T-CombatLoggingReminder.lua

-- Список рейдовых подземелий для отслеживания
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
raids["???"] = true  -- Для будущих/неизвестных рейдов

-- Проверка, находится ли игрок в рейдовой группе
local function T_IsInRaid()
    return UnitInRaid("player") == 1
end

-- Проверка, является ли текущая зона рейдовым подземельем
local T_IsRaidInstance = function()
    if not IsInInstance() then
        return false
    end
    local zoneName = GetRealZoneText()
    return zoneName and raids[zoneName] == true
end

-- Отслеживание смены зоны для определения входа в рейд
local T_lastZone = nil
local function T_IsEnteringRaid()
    local currentZone = GetRealZoneText()
    local isEntering = currentZone and currentZone ~= T_lastZone and raids[currentZone] and T_IsInRaid()
    T_lastZone = currentZone
    return isEntering
end

-- Включение записи боя
local function T_EnableCombatLogging()
    LoggingCombat(1)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r |cFF00FF00Combat Logging Enabled|r")
end

-- Выключение записи боя
local function T_DisableCombatLogging()
    LoggingCombat(0)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r |cFFFF0000Combat Logging Disabled|r")
end

-- Основной обработчик события входа в мир/инстанс
local function T_HandlePlayerEnteringWorld(self, event, isLogin, isReload)
    -- Если заходим в рейд и запись боя выключена - показать popup
    if T_IsEnteringRaid() and LoggingCombat() ~= 1 then
        StaticPopup_Show("T_ENABLE_COMBAT_LOGGING")
    end
    
    -- Если вышли из рейда и запись боя включена - выключить
    if not T_IsInRaid() and LoggingCombat() == 1 then
        T_DisableCombatLogging()
    end
end

-- Создание фрейма для обработки событий
local T_EventFrame = CreateFrame("Frame", "T_EventFrame")
T_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
T_EventFrame:SetScript("OnEvent", T_HandlePlayerEnteringWorld)

-- Popup диалог для включения записи боя
StaticPopupDialogs["T_ENABLE_COMBAT_LOGGING"] = {
    text = "|cFF11A6ECT-CombatLoggingReminder:|r Would you like to enable Combat Logging?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = T_EnableCombatLogging,  -- Действие при нажатии "Yes"
    timeout = 30,  -- Таймаут автоматического закрытия (30 секунд)
    whileDead = true,  -- Работает когда персонаж мертв
    hideOnEscape = true  -- Закрывается по клавише Escape
}

-- Функция выполняемая при загрузке аддона
local function T_OnPlayerLogin()
    local title = "T-CombatLoggingReminder"
    local notes = "Automatically reminds you to enable combat logging when entering raids and disables it when leaving."
    local loaded = "|cFF11A6ECT-CombatLoggingReminder|r - |cFF00FF00Successfully loaded!|r"
    
    -- Сообщения в чат о успешной загрузке
    DEFAULT_CHAT_FRAME:AddMessage(loaded)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r " .. notes)
end

-- Регистрация дополнительного события и обновление обработчика
T_EventFrame:RegisterEvent("PLAYER_LOGIN")
T_EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        T_OnPlayerLogin()  -- Обработка загрузки аддона
    elseif event == "PLAYER_ENTERING_WORLD" then
        T_HandlePlayerEnteringWorld(self, event, ...)  -- Обработка входа в мир/инстанс
    end
end)

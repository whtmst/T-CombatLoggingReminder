--[[
	T-CombatLoggingReminder v1.0 RU Remaster for Turtle WoW
	Оригинальный автор: Михаил Палагин (Wht Mst)
	Основан на: Combat Logging Reminder
	GitHub: https://github.com/whtmst/T-CombatLoggingReminder
	
	Аддон для автоматического напоминания о включении ведения логов боя при входе в рейды
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

-- Переменные для отслеживания состояния
local T_wasEnabledByAddon = false
local T_wasInRaidInstance = false

-- Проверка, находится ли игрок в рейдовой группе
local function T_IsInRaid()
    return UnitInRaid("player") == 1
end

-- Проверка, является ли текущая зона рейдовым подземельем
local T_IsRaidInstance = function()
    local inInstance = IsInInstance()
    if inInstance ~= 1 then  -- В WoW 1.12 IsInInstance() возвращает 1 если в инстансе, nil если нет
        return false
    end
    local zoneName = GetRealZoneText()
    return zoneName and raids[zoneName] == true
end

-- Проверка находится ли игрок в инстансе (совместимость с WoW 1.12)
local function T_IsInInstance()
    return IsInInstance() == 1
end

-- Проверка статуса записи боя (обрабатывает nil значение)
local function T_IsCombatLoggingEnabled()
    local status = LoggingCombat()
    return status == 1
end

-- Включение ведения логов боя
local function T_EnableCombatLogging()
    LoggingCombat(1)
    T_wasEnabledByAddon = true
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r |cFF00FF00Ведение логов боя включено|r")
    -- Сообщение как при ручном включении через /combatlog
    DEFAULT_CHAT_FRAME:AddMessage("Логи записываются в файл Logs\\WoWCombatLog.txt")
end

-- Выключение ведения логов боя
local function T_DisableCombatLogging()
    LoggingCombat(0)
    T_wasEnabledByAddon = false
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r |cFFFF0000Ведение логов боя отключено|r")
    -- Сообщение как при ручном выключении через /combatlog
    DEFAULT_CHAT_FRAME:AddMessage("Ведение логов боя отключено.")
end

-- Основной обработчик события входа в мир/инстанс
local function T_HandlePlayerEnteringWorld()
    local currentInInstance = T_IsInInstance()
    local currentIsRaidInstance = T_IsRaidInstance()
    local combatLoggingEnabled = T_IsCombatLoggingEnabled()
    local inRaid = T_IsInRaid()
    
    -- Вход в рейд: сейчас в рейдовом инстансе И ранее не были И в рейде И логи выключены
    if currentIsRaidInstance and not T_wasInRaidInstance and inRaid and not combatLoggingEnabled then
        StaticPopup_Show("T_ENABLE_COMBAT_LOGGING")
    end
    
    -- Выход из рейда: ранее были в рейдовом инстансе И сейчас не в инстансе И логи включены аддоном
    if T_wasInRaidInstance and not currentInInstance and combatLoggingEnabled and T_wasEnabledByAddon then
        StaticPopup_Show("T_DISABLE_COMBAT_LOGGING")
    end
    
    -- Обновляем состояние для следующего вызова
    T_wasInRaidInstance = currentIsRaidInstance
end

-- Функция выполняемая при загрузке аддона
local function T_OnPlayerLogin()
    local loaded = "|cFF11A6ECT-CombatLoggingReminder|r - |cFF00FF00Успешно загружен!|r"
    local notes = "Автоматически напоминает о включении ведения логов боя при входе в рейды и выключает при выходе."
    
    -- Сообщения в чат о успешной загрузке
    DEFAULT_CHAT_FRAME:AddMessage(loaded)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r " .. notes)
end

-- Создание фрейма для обработки событий
local T_EventFrame = CreateFrame("Frame", "T_EventFrame")
T_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
T_EventFrame:RegisterEvent("PLAYER_LOGIN")

-- Универсальный обработчик событий (совместимый с Lua 5.0/5.1)
T_EventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        T_OnPlayerLogin()  -- Обработка загрузки аддона
    elseif event == "PLAYER_ENTERING_WORLD" then
        T_HandlePlayerEnteringWorld()  -- Обработка входа в мир/инстанс
    end
end)

-- Popup диалог для включения ведения логов боя
StaticPopupDialogs["T_ENABLE_COMBAT_LOGGING"] = {
    text = "|cFF11A6ECT-CombatLoggingReminder:|r Вы вошли в рейдовое подземелье. Включить ведение логов боя?",
    button1 = "Да",
    button2 = "Нет",
    OnAccept = T_EnableCombatLogging,
    timeout = 30,
    whileDead = true,
    hideOnEscape = true
}

-- Popup диалог для выключения ведения логов боя
StaticPopupDialogs["T_DISABLE_COMBAT_LOGGING"] = {
    text = "|cFF11A6ECT-CombatLoggingReminder:|r Вы покинули рейдовое подземелье. Выключить ведение логов боя?",
    button1 = "Да",
    button2 = "Нет",
    OnAccept = T_DisableCombatLogging,
    timeout = 30,
    whileDead = true,
    hideOnEscape = true
}

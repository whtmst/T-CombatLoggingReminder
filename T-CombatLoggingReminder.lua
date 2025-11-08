--[[
	T-CombatLoggingReminder v1.18 RU Remaster for Turtle WoW
	Оригинальный автор: Михаил Палагин (Wht Mst)
	Основан на: Combat Logging Reminder
	GitHub: https://github.com/whtmst/T-CombatLoggingReminder
	
	Аддон для автоматического напоминания о включении ведения логов боя при входе в рейды
	и автоматического выключения при выходе из рейда.
	Последнее обновление: v1.18
	Протестировано для: Turtle WoW
]]--

-- T-CombatLoggingReminder.lua

-- Включить расширенный дебаг
local T_DEBUG = false

-- Функция для дебаг-сообщений
local function T_Debug(message)
    if T_DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900T-DEBUG:|r " .. message)
    end
end

-- Вспомогательная функция для размера таблицы
local function GetTableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Список рейдовых подземелий для отслеживания
local raids = {}
raids["Molten Core"] = true
raids["The Molten Core"] = true  -- Добавляем оба варианта названия
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

T_Debug("Список рейдов загружен, количество: " .. GetTableSize(raids))

-- Переменные для отслеживания состояния
local T_wasEnabledByAddon = false
local T_manuallyEnabled = false
local T_wasInRaidInstance = false
local T_wasInRaidGroup = false

-- Проверка, находится ли игрок в рейдовой группе
local function T_IsInRaidGroup()
    local inRaid = UnitInRaid("player") == 1
    T_Debug("T_IsInRaidGroup() = " .. tostring(inRaid))
    return inRaid
end

-- Проверка, является ли текущая зона рейдовым подземельем
local T_IsRaidInstance = function()
    local inInstance = IsInInstance()
    T_Debug("IsInInstance() = " .. tostring(inInstance))
    
    if inInstance ~= 1 then
        T_Debug("Не в инстансе, возвращаем false")
        return false
    end
    
    -- Используем GetZoneText() для получения названия инстанса
    local zoneName = GetZoneText()
    T_Debug("GetZoneText() = " .. tostring(zoneName))
    T_Debug("GetRealZoneText() = " .. tostring(GetRealZoneText()))
    
    local isRaid = zoneName and raids[zoneName] == true
    T_Debug("T_IsRaidInstance() = " .. tostring(isRaid) .. " для зоны: " .. tostring(zoneName))
    
    if zoneName and not raids[zoneName] then
        T_Debug("Зона '" .. tostring(zoneName) .. "' не найдена в списке рейдов")
    end
    
    return isRaid
end

-- Проверка находится ли игрок в инстансе (совместимость с WoW 1.12)
local function T_IsInInstance()
    local result = IsInInstance() == 1
    T_Debug("T_IsInInstance() = " .. tostring(result))
    return result
end

-- Проверка статуса записи боя (обрабатывает nil значение)
local function T_IsCombatLoggingEnabled()
    local status = LoggingCombat()
    T_Debug("LoggingCombat() = " .. tostring(status))
    local result = status == 1
    T_Debug("T_IsCombatLoggingEnabled() = " .. tostring(result))
    return result
end

-- Включение ведения логов боя
local function T_EnableCombatLogging()
    T_Debug("T_EnableCombatLogging() вызвана")
    LoggingCombat(1)
    T_wasEnabledByAddon = true
    T_manuallyEnabled = false
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r |cFF00FF00Ведение логов боя включено|r")
    DEFAULT_CHAT_FRAME:AddMessage("Логи записываются в файл Logs\\WoWCombatLog.txt")
    T_Debug("Логи включены, T_wasEnabledByAddon = true, T_manuallyEnabled = false")
end

-- Выключение ведения логов боя
local function T_DisableCombatLogging()
    T_Debug("T_DisableCombatLogging() вызвана")
    LoggingCombat(0)
    T_wasEnabledByAddon = false
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r |cFFFF0000Ведение логов боя отключено|r")
    DEFAULT_CHAT_FRAME:AddMessage("Ведение логов боя отключено.")
    T_Debug("Логи выключены, T_wasEnabledByAddon = false")
end

-- Обработчик ручного включения/выключения логов
local function T_HandleCombatLogToggle()
    T_Debug("T_HandleCombatLogToggle() вызвана")
    local combatLoggingEnabled = T_IsCombatLoggingEnabled()
    
    -- Если логи включены вручную (не через аддон)
    if combatLoggingEnabled and not T_wasEnabledByAddon then
        T_manuallyEnabled = true
        T_Debug("Логи включены вручную, T_manuallyEnabled = true")
    end
    
    -- Если логи выключены вручную
    if not combatLoggingEnabled then
        T_wasEnabledByAddon = false
        T_manuallyEnabled = false
        T_Debug("Логи выключены вручную, T_wasEnabledByAddon = false, T_manuallyEnabled = false")
    end
end

-- Основная функция проверки условий для показа popup
local function T_CheckRaidConditions()
    T_Debug("=== T_CheckRaidConditions() ВЫЗВАНА ===")
    
    local currentInInstance = T_IsInInstance()
    local currentIsRaidInstance = T_IsRaidInstance()
    local combatLoggingEnabled = T_IsCombatLoggingEnabled()
    
    T_Debug("Состояние: currentInInstance=" .. tostring(currentInInstance) .. 
           ", currentIsRaidInstance=" .. tostring(currentIsRaidInstance) .. 
           ", combatLoggingEnabled=" .. tostring(combatLoggingEnabled) ..
           ", T_wasInRaidInstance=" .. tostring(T_wasInRaidInstance) ..
           ", T_wasEnabledByAddon=" .. tostring(T_wasEnabledByAddon) ..
           ", T_manuallyEnabled=" .. tostring(T_manuallyEnabled))
    
    -- Вход в рейд: сейчас в рейдовом инстансе И ранее не были
    if currentIsRaidInstance and not T_wasInRaidInstance then
        T_Debug("УСЛОВИЕ ВХОДА В РЕЙД: выполнено")
        -- Если логи уже включены (любым способом) - показываем информационный popup с одной кнопкой ОК
        if combatLoggingEnabled then
            T_Debug("Показываем T_COMBAT_LOGGING_INFO_ENABLED (логи уже включены)")
            StaticPopup_Show("T_COMBAT_LOGGING_INFO_ENABLED")
        -- Если логи выключены - показываем popup с предложением включить
        else
            T_Debug("Показываем T_ENABLE_COMBAT_LOGGING (логи выключены)")
            StaticPopup_Show("T_ENABLE_COMBAT_LOGGING")
        end
    else
        if not currentIsRaidInstance then
            T_Debug("УСЛОВИЕ ВХОДА В РЕЙД: не выполнено - не рейдовый инстанс")
        elseif T_wasInRaidInstance then
            T_Debug("УСЛОВИЕ ВХОДА В РЕЙД: не выполнено - уже были в рейдовом инстансе")
        end
    end
    
    -- Выход из рейда: ранее были в рейдовом инстансе И сейчас не в инстансе И логи включены
    if T_wasInRaidInstance and not currentInInstance and combatLoggingEnabled then
        T_Debug("УСЛОВИЕ ВЫХОДА ИЗ РЕЙДА: выполнено, показываем T_DISABLE_COMBAT_LOGGING")
        StaticPopup_Show("T_DISABLE_COMBAT_LOGGING")
    else
        if not T_wasInRaidInstance then
            T_Debug("УСЛОВИЕ ВЫХОДА ИЗ РЕЙДА: не выполнено - не были в рейдовом инстансе")
        elseif currentInInstance then
            T_Debug("УСЛОВИЕ ВЫХОДА ИЗ РЕЙДА: не выполнено - все еще в инстансе")
        elseif not combatLoggingEnabled then
            T_Debug("УСЛОВИЕ ВЫХОДА ИЗ РЕЙДА: не выполнено - логи не включены")
        end
    end
    
    -- Обновляем состояние для следующего вызова
    T_Debug("Обновляем T_wasInRaidInstance с " .. tostring(T_wasInRaidInstance) .. " на " .. tostring(currentIsRaidInstance))
    T_wasInRaidInstance = currentIsRaidInstance
    T_Debug("=== T_CheckRaidConditions() ЗАВЕРШЕНА ===")
end

-- Основной обработчик события входа в мир/инстанс
local function T_HandlePlayerEnteringWorld()
    T_Debug("=== T_HandlePlayerEnteringWorld() ВЫЗВАНА ===")
    
    -- Ждем немного чтобы зона успела обновиться
    T_Debug("Ждем 0.5 секунды перед проверкой условий")
    
    -- Используем простой таймер через OnUpdate (совместимость с WoW 1.12)
    local waitTime = 0.5
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function()
        -- В WoW 1.12 используется arg1 вместо параметра elapsed
        waitTime = waitTime - arg1
        if waitTime <= 0 then
            T_CheckRaidConditions()
            this:SetScript("OnUpdate", nil)
        end
    end)
    
    T_Debug("=== T_HandlePlayerEnteringWorld() ЗАВЕРШЕНА ===")
end

-- Обработчик изменения зоны
local function T_HandleZoneChanged()
    T_Debug("=== T_HandleZoneChanged() ВЫЗВАНА ===")
    T_Debug("Зона изменилась, выполняем проверку условий")
    T_CheckRaidConditions()
    T_Debug("=== T_HandleZoneChanged() ЗАВЕРШЕНА ===")
end

-- Обработчик изменения состава группы/рейда
local function T_HandleGroupUpdate()
    T_Debug("=== T_HandleGroupUpdate() ВЫЗВАНА ===")
    
    local currentInRaidGroup = T_IsInRaidGroup()
    local combatLoggingEnabled = T_IsCombatLoggingEnabled()
    
    T_Debug("Состояние группы: currentInRaidGroup=" .. tostring(currentInRaidGroup) .. 
           ", T_wasInRaidGroup=" .. tostring(T_wasInRaidGroup) ..
           ", combatLoggingEnabled=" .. tostring(combatLoggingEnabled))
    
    -- Выход из рейдовой группы: были в рейде И сейчас не в рейде И логи включены
    if T_wasInRaidGroup and not currentInRaidGroup and combatLoggingEnabled then
        T_Debug("УСЛОВИЕ ВЫХОДА ИЗ ГРУППЫ: выполнено, показываем T_DISABLE_COMBAT_LOGGING")
        StaticPopup_Show("T_DISABLE_COMBAT_LOGGING")
    else
        if not T_wasInRaidGroup then
            T_Debug("УСЛОВИЕ ВЫХОДА ИЗ ГРУППЫ: не выполнено - не были в рейдовой группе")
        elseif currentInRaidGroup then
            T_Debug("УСЛОВИЕ ВЫХОДА ИЗ ГРУППЫ: не выполнено - все еще в рейдовой группе")
        elseif not combatLoggingEnabled then
            T_Debug("УСЛОВИЕ ВЫХОДА ИЗ ГРУППЫ: не выполнено - логи не включены")
        end
    end
    
    -- Обновляем состояние для следующего вызова
    T_Debug("Обновляем T_wasInRaidGroup с " .. tostring(T_wasInRaidGroup) .. " на " .. tostring(currentInRaidGroup))
    T_wasInRaidGroup = currentInRaidGroup
    T_Debug("=== T_HandleGroupUpdate() ЗАВЕРШЕНА ===")
end

-- Функция выполняемая при загрузке аддона
local function T_OnPlayerLogin()
    T_Debug("=== T_OnPlayerLogin() ВЫЗВАНА ===")
    
    local loaded = "|cFF11A6ECT-CombatLoggingReminder|r - |cFF00FF00Успешно загружен!|r"
    local notes = "Автоматически напоминает о включении ведения логов боя при входе в рейды и предлагает выключить при выходе."
    
    -- Инициализация начального состояния
    T_wasInRaidGroup = T_IsInRaidGroup()
    T_Debug("Начальное состояние T_wasInRaidGroup = " .. tostring(T_wasInRaidGroup))
    
    -- Синхронизация состояния логов при загрузке
    if T_IsCombatLoggingEnabled() then
        T_manuallyEnabled = true
        T_Debug("Логи включены при загрузке, T_manuallyEnabled = true")
    else
        T_Debug("Логи выключены при загрузке")
    end
    
    -- Сообщения в чат о успешной загрузке
    DEFAULT_CHAT_FRAME:AddMessage(loaded)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r " .. notes)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r Используйте |cFFFFFF00/tzone|r для отладки информации о зоне.")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder:|r Режим отладки: |cFFFFFF00" .. tostring(T_DEBUG) .. "|r")
    
    T_Debug("=== T_OnPlayerLogin() ЗАВЕРШЕНА ===")
end

-- Команда для отладки информации о зоне
SLASH_TZONE1 = "/tzone"
SlashCmdList["TZONE"] = function()
    T_Debug("=== КОМАНДА /TZONE ВЫЗВАНА ===")
    
    local zoneName = GetZoneText()
    local realZoneName = GetRealZoneText()
    local inInstance = T_IsInInstance()
    local isRaidInstance = T_IsRaidInstance()
    local inRaidGroup = T_IsInRaidGroup()
    local combatLoggingEnabled = T_IsCombatLoggingEnabled()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF11A6ECT-CombatLoggingReminder Debug:|r")
    DEFAULT_CHAT_FRAME:AddMessage("Зона (GetZoneText): |cFFFFFFFF" .. (zoneName or "nil") .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("Реальная зона (GetRealZoneText): |cFFFFFFFF" .. (realZoneName or "nil") .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("В инстансе: |cFFFFFFFF" .. (inInstance and "Да" or "Нет") .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("Рейдовый инстанс: |cFFFFFFFF" .. (isRaidInstance and "Да" or "Нет") .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("В рейдовой группе: |cFFFFFFFF" .. (inRaidGroup and "Да" or "Нет") .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("Логи боя включены: |cFFFFFFFF" .. (combatLoggingEnabled and "Да" or "Нет") .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("Включено аддоном: |cFFFFFFFF" .. (T_wasEnabledByAddon and "Да" or "Нет") .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("Включено вручную: |cFFFFFFFF" .. (T_manuallyEnabled and "Да" or "Нет") .. "|r")
    
    -- Дополнительная отладочная информация
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900Доп. информация:|r")
    DEFAULT_CHAT_FRAME:AddMessage("T_wasInRaidInstance: |cFFFFFFFF" .. tostring(T_wasInRaidInstance) .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("T_wasInRaidGroup: |cFFFFFFFF" .. tostring(T_wasInRaidGroup) .. "|r")
    
    -- Проверка всех зон в списке рейдов
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900Список отслеживаемых рейдов:|r")
    for raidName, _ in pairs(raids) do
        local isCurrent = raidName == zoneName
        DEFAULT_CHAT_FRAME:AddMessage("  " .. raidName .. (isCurrent and " |cFF00FF00<-- ТЕКУЩАЯ|r" or ""))
    end
    
    T_Debug("=== КОМАНДА /TZONE ЗАВЕРШЕНА ===")
end

-- Перехват команды combatlog для отслеживания ручного управления
local original_CombatLog = SlashCmdList["COMBATLOG"]
SlashCmdList["COMBATLOG"] = function(msg)
    T_Debug("Команда /combatlog вызвана с параметром: " .. tostring(msg))
    
    -- Вызываем оригинальную функцию
    original_CombatLog(msg)
    
    -- Обрабатываем изменение состояния
    T_HandleCombatLogToggle()
end

-- Создание фрейма для обработки событий
local T_EventFrame = CreateFrame("Frame", "T_EventFrame")
T_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
T_EventFrame:RegisterEvent("PLAYER_LOGIN")
T_EventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
T_EventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
T_EventFrame:RegisterEvent("ZONE_CHANGED")  -- Добавляем событие изменения зоны
T_EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")  -- Добавляем событие изменения области

T_Debug("Фрейм событий создан, события зарегистрированы")

-- Универсальный обработчик событий (совместимый с Lua 5.0/5.1)
T_EventFrame:SetScript("OnEvent", function()
    T_Debug("Событие получено: " .. tostring(event))
    
    if event == "PLAYER_LOGIN" then
        T_Debug("Обрабатываем PLAYER_LOGIN")
        T_OnPlayerLogin()  -- Обработка загрузки аддона
    elseif event == "PLAYER_ENTERING_WORLD" then
        T_Debug("Обрабатываем PLAYER_ENTERING_WORLD")
        T_HandlePlayerEnteringWorld()  -- Обработка входа в мир/инстанс
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        T_Debug("Обрабатываем " .. event)
        T_HandleGroupUpdate()  -- Обработка изменений в группе/рейде
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        T_Debug("Обрабатываем " .. event)
        T_HandleZoneChanged()  -- Обработка изменения зоны
    end
end)

T_Debug("Обработчик событий установлен")

-- Popup диалог для включения ведения логов боя
StaticPopupDialogs["T_ENABLE_COMBAT_LOGGING"] = {
    text = "|cFF11A6ECT-CombatLoggingReminder:|r Вы вошли в рейдовое подземелье. Включить ведение логов боя?",
    button1 = "Включить",
    button2 = "Не включать",
    OnAccept = function()
        T_Debug("Popup T_ENABLE_COMBAT_LOGGING: нажата кнопка Включить")
        T_EnableCombatLogging()
    end,
    OnCancel = function()
        T_Debug("Popup T_ENABLE_COMBAT_LOGGING: нажата кнопка Не включать")
    end,
    timeout = 0,  -- Убираем таймаут, чтобы popup не исчезал автоматически
    whileDead = true,
    hideOnEscape = true
}

T_Debug("Popup T_ENABLE_COMBAT_LOGGING создан")

-- Popup диалог для выключения ведения логов боя
StaticPopupDialogs["T_DISABLE_COMBAT_LOGGING"] = {
    text = "|cFF11A6ECT-CombatLoggingReminder:|r Вы покинули рейдовое подземелье или рейдовую группу. Выключить ведение логов боя?",
    button1 = "Выключить",
    button2 = "Не выключать",
    OnAccept = function()
        T_Debug("Popup T_DISABLE_COMBAT_LOGGING: нажата кнопка Выключить")
        T_DisableCombatLogging()
    end,
    OnCancel = function()
        T_Debug("Popup T_DISABLE_COMBAT_LOGGING: нажата кнопка Не выключать")
    end,
    timeout = 0,  -- Убираем таймаут, чтобы popup не исчезал автоматически
    whileDead = true,
    hideOnEscape = true
}

T_Debug("Popup T_DISABLE_COMBAT_LOGGING создан")

-- Информационный Popup диалог (логи уже включены)
StaticPopupDialogs["T_COMBAT_LOGGING_INFO_ENABLED"] = {
    text = "|cFF11A6ECT-CombatLoggingReminder:|r Ведение логов боя уже активно.",
    button1 = "OK",
    OnAccept = function()
        T_Debug("Popup T_COMBAT_LOGGING_INFO_ENABLED: нажата кнопка OK")
    end,
    timeout = 0,  -- Убираем таймаут, чтобы popup не исчезал автоматически
    whileDead = true,
    hideOnEscape = true
}

T_Debug("Popup T_COMBAT_LOGGING_INFO_ENABLED создан")
T_Debug("Аддон T-CombatLoggingReminder полностью инициализирован")

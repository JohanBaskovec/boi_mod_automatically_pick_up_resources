local json = require("json")
local mod = RegisterMod("Pick up resources with one keypress", 1)

Controller = Controller or {}
Controller.DPAD_LEFT = 0
Controller.DPAD_RIGHT = 1
Controller.DPAD_UP = 2
Controller.DPAD_DOWN = 3
Controller.BUTTON_A = 4
Controller.BUTTON_B = 5
Controller.BUTTON_X = 6
Controller.BUTTON_Y = 7
Controller.BUMPER_LEFT = 8
Controller.TRIGGER_LEFT = 9
Controller.STICK_LEFT = 10
Controller.BUMPER_RIGHT = 11
Controller.TRIGGER_RIGHT = 12
Controller.STICK_RIGHT = 13
Controller.BUTTON_BACK = 14
Controller.BUTTON_START = 15

local defaultSettings = {
    keyboardKey = Keyboard.KEY_C,
    controllerButtons = { Controller.STICK_LEFT, -1 },
    openChests = true,
    pickUpCoins = true,
    pickUpLuckyPenny = true,
    pickUpPills = true,
    pickUpCards = true,
    pickUpBombs = true,
    pickUpKeys = true,
    pickUpRedHearts = true,
    pickUpSoulHearts = true,
    pickUpBags = true,
    pickUpGoldenKeys = true,
    pickUpGoldenBombs = true
}

local settings = defaultSettings

local function saveSettings()
    local jsonString = json.encode(settings)
    mod:SaveData(jsonString)
end

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, saveSettings)

local function loadSettings()
    local jsonString = mod:LoadData()
    settings = json.decode(jsonString)
    if settings.keyboardKey < -1 or settings.keyboardKey > 348 then
        error("Invalid keyboard key")
    end
    for i = 1, 1 do
        if settings.controllerButtons[i] == nil or settings.controllerButtons[i] < -1 or settings.controllerButtons[i] > 15 then
            error("Invalid controllerButton0")
        end
    end

    -- newly added settings are set to default value
    for k, v in pairs(defaultSettings) do
        if settings[k] == nil then
            settings[k] = defaultSettings[k]
        end
    end
end

local function initializeSettings()
    if not mod:HasData() then
        settings = defaultSettings
        return
    end

    if not pcall(loadSettings) then
        settings = defaultSettings
        Isaac.DebugString("Error: Failed to load " .. mod.Name .. " settings, reverting to default settings.")
    end
end

initializeSettings()

local optionsModName = "Pick up resources"

local function setupMyModConfigMenuSettings()
    if ModConfigMenu == nil then
        return
    end

    -- Remove menu if it exists, makes debugging easier
    ModConfigMenu.RemoveCategory(optionsModName)

    ModConfigMenu.AddSetting(
            optionsModName,
            nil,
            {
                Type = ModConfigMenu.OptionType.KEYBIND_KEYBOARD,
                CurrentSetting = function()
                    return settings.keyboardKey
                end,
                Default = Keyboard.KEY_C,
                Display = function()
                    local currentValue = settings.keyboardKey
                    local key = "None"

                    if currentValue > -1 then
                        key = "Unknown Key"

                        if InputHelper.KeyboardToString[currentValue] then
                            key = InputHelper.KeyboardToString[currentValue]
                        end
                    end
                    return "Pick up resources: " .. (key) .. ' (keyboard)'
                end,
                OnChange = function(newValue)
                    if not newValue then
                        newValue = -1
                    end
                    settings.keyboardKey = newValue
                end,
                Info = {
                    "The keyboard key to press to pick up resources in the room",
                },
                PopupGfx = ModConfigMenu.PopupGfx.WIDE_SMALL,
                PopupWidth = 280,
                Popup = function()
                    local currentValue = settings.keyboardKey

                    local goBackString = "back"
                    if ModConfigMenu.Config.LastBackPressed then
                        if InputHelper.KeyboardToString[ModConfigMenu.Config.LastBackPressed] then
                            goBackString = InputHelper.KeyboardToString[ModConfigMenu.Config.LastBackPressed]
                        elseif InputHelper.ControllerToString[ModConfigMenu.Config.LastBackPressed] then
                            goBackString = InputHelper.ControllerToString[ModConfigMenu.Config.LastBackPressed]
                        end
                    end

                    local keepSettingString = ""
                    if currentValue > -1 then
                        local currentSettingString = 'unknown'
                        if (InputHelper.KeyboardToString[currentValue]) then
                            currentSettingString = InputHelper.KeyboardToString[currentValue]
                        end

                        keepSettingString = "This setting is currently set to \"" ..
                                currentSettingString .. "\".$newlinePress this button to keep it unchanged.$newline$newline"
                    end

                    local deviceString = "keyboard"

                    return "Press a button on your " ..
                            deviceString ..
                            " to change this setting.$newline$newline" ..
                            keepSettingString .. "Press \"" .. goBackString .. "\" to go back and clear this setting."
                end
            }
    )

    for i = 1, 1 do
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.KEYBIND_CONTROLLER,
                    CurrentSetting = function()
                        return settings.controllerButtons[i]
                    end,
                    Display = function()
                        local currentValue = settings.controllerButtons[i]
                        local key = "None"

                        if currentValue > -1 then
                            key = "Unknown Button"

                            if InputHelper.ControllerToString[currentValue] then
                                key = InputHelper.ControllerToString[currentValue]
                            end
                        end

                        return "Pick up resources: " .. key .. " (controller)"
                    end,
                    OnChange = function(newValue)
                        if not newValue then
                            newValue = -1
                        end
                        settings.controllerButtons[i] = newValue
                    end,
                    Info = {
                        "The first controller button to pick up resources in the room",
                    },
                    PopupGfx = ModConfigMenu.PopupGfx.WIDE_SMALL,
                    PopupWidth = 280,
                    Popup = function()
                        local currentValue = settings.controllerButtons[i]

                        local goBackString = "back"
                        if ModConfigMenu.Config.LastBackPressed then
                            if InputHelper.KeyboardToString[ModConfigMenu.Config.LastBackPressed] then
                                goBackString = InputHelper.KeyboardToString[ModConfigMenu.Config.LastBackPressed]
                            elseif InputHelper.ControllerToString[ModConfigMenu.Config.LastBackPressed] then
                                goBackString = InputHelper.ControllerToString[ModConfigMenu.Config.LastBackPressed]
                            end
                        end

                        local keepSettingString = ""
                        if currentValue > -1 then
                            local currentSettingString = 'unknown'
                            if (InputHelper.ControllerToString[currentValue]) then
                                currentSettingString = InputHelper.ControllerToString[currentValue]
                            end

                            keepSettingString = "This setting is currently set to \"" ..
                                    currentSettingString .. "\".$newlinePress this button to keep it unchanged.$newline$newline"
                        end

                        local deviceString = "controller"

                        return "Press a button on your " ..
                                deviceString ..
                                " to change this setting.$newline$newline" ..
                                keepSettingString .. "Press \"" .. goBackString .. "\" to go back and clear this setting."
                    end
                }
        )

        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpCoins
                    end,
                    Display = function()
                        local currentValue = settings.pickUpCoins
                        return "Pick up coins? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpCoins = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpLuckyPenny
                    end,
                    Display = function()
                        local currentValue = settings.pickUpLuckyPenny
                        return "Pick up lucky pennies? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpLuckyPenny = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpKeys
                    end,
                    Display = function()
                        local currentValue = settings.pickUpKeys
                        return "Pick up keys? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpKeys = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpGoldenKeys
                    end,
                    Display = function()
                        local currentValue = settings.pickUpGoldenKeys
                        return "Pick up golden keys? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpGoldenKeys = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpBombs
                    end,
                    Display = function()
                        local currentValue = settings.pickUpBombs
                        return "Pick up bombs? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpBombs = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpGoldenBombs
                    end,
                    Display = function()
                        local currentValue = settings.pickUpGoldenBombs
                        return "Pick up golden bombs? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpGoldenBombs = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpPills
                    end,
                    Display = function()
                        local currentValue = settings.pickUpPills
                        return "Pick up pills? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpPills = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpCards
                    end,
                    Display = function()
                        local currentValue = settings.pickUpCards
                        return "Pick up cards? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpCards = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpRedHearts
                    end,
                    Display = function()
                        local currentValue = settings.pickUpRedHearts
                        return "Pick up red hearts? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpRedHearts = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpSoulHearts
                    end,
                    Display = function()
                        local currentValue = settings.pickUpSoulHearts
                        return "Pick up soul hearts? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpSoulHearts = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.pickUpBags
                    end,
                    Display = function()
                        local currentValue = settings.pickUpBags
                        return "Pick up bags? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.pickUpBags = newValue
                    end,
                }
        )
        ModConfigMenu.AddSetting(
                optionsModName,
                nil,
                {
                    Type = ModConfigMenu.OptionType.BOOLEAN,
                    CurrentSetting = function()
                        return settings.openChests
                    end,
                    Display = function()
                        local currentValue = settings.openChests
                        return "Open unlocked chests? " .. tostring(currentValue)
                    end,
                    OnChange = function(newValue)
                        settings.openChests = newValue
                    end,
                }
        )
    end
end

setupMyModConfigMenuSettings()

local buttonsPressedLast = false
local buttonsPressed = false

local function pickUpResources(player)
    local controllerIndex = player.ControllerIndex

    -- Player must release the buttons and press them again to do the action
    local keyboardButtonPressed = Input.IsButtonPressed(settings.keyboardKey, controllerIndex)

    local controllerButtonsPressed = true
    for i = 1, 1 do
        local controllerButtonPressed = settings.controllerButtons[i] == -1 or Input.IsButtonPressed(settings.controllerButtons[i], controllerIndex)
        if not controllerButtonPressed then
            controllerButtonsPressed = false
        end
    end
    buttonsPressed = keyboardButtonPressed or controllerButtonsPressed

    if not buttonsPressed then
        buttonsPressedLast = false
        return
    end
    if buttonsPressedLast then
        return
    end
    buttonsPressedLast = buttonsPressed

    local room = Game():GetRoom()

    -- Only allow in empty room to prevent accidentally triggering picking up an item and playing the pickup animation
    -- and to prevent "cheating" (for example teleporting a heart from the other side on the room that could save your life)
    if room:IsClear() then
        -- We spawn a temporary NPC in order to use its PathFinder, and remove it when we don't need it anymore
        -- We use the PathFinder to check if the player can reach the item.
        local entityType = EntityType.ENTITY_MAGGOT
        local temporaryEntity = Game():Spawn(
                entityType, -- Type
                0, -- Variant
                player.Position, -- Position
                Vector(0, 0), -- Velocity
                nil, -- Parent
                0, -- SubType
                Game():GetRoom():GetSpawnSeed() -- Seed (the "GetSpawnSeed()" function gets a reproducible seed based on the room, e.g. "2496979501")
        )                       :ToNPC()

        local nCoins = player:GetNumCoins()
        local maxCoins = 99
        if player:HasCollectible(CollectibleType.COLLECTIBLE_DEEP_POCKETS) then
            maxCoins = 999
        end
        local nBombs = player:GetNumBombs()
        local nKeys = player:GetNumKeys()
        local nHearts = player:GetHearts()
        local maxHearts = player:GetEffectiveMaxHearts()
        local nSoulHearts = player:GetSoulHearts()
        local heartLimit = player:GetHeartLimit()

        for i, entity in ipairs(Isaac.GetRoomEntities()) do
            local pickUpEntity = entity:ToPickup()
            temporaryEntity.Position = Vector(entity.Position.X, entity.Position.Y)
            if pickUpEntity ~= nil and (not pickUpEntity:IsShopItem()) and (temporaryEntity.Pathfinder:HasPathToPos(player.Position, true) or player.CanFly) then
                local teleport = false
                if entity.Variant == PickupVariant.PICKUP_COIN then
                    if settings.pickUpCoins then
                        if entity.SubType == CoinSubType.COIN_PENNY or entity.SubType == CoinSubType.COIN_GOLDEN and nCoins < maxCoins then
                            nCoins = nCoins + 1
                            teleport = true
                        elseif entity.SubType == CoinSubType.COIN_DOUBLEPACK and nCoins < maxCoins - 1 then
                            nCoins = nCoins + 2
                            teleport = true
                        elseif entity.SubType == CoinSubType.COIN_NICKEL and nCoins < maxCoins - 4 then
                            nCoins = nCoins + 5
                            teleport = true
                        elseif entity.SubType == CoinSubType.COIN_DIME and nCoins < maxCoins - 9 then
                            nCoins = nCoins + 10
                            teleport = true
                        end
                    end
                    if settings.pickUpLuckyPenny and entity.SubType == CoinSubType.COIN_LUCKYPENNY and nCoins < maxCoins then
                        nCoins = nCoins + 1
                        teleport = true
                    end
                elseif entity.Variant == PickupVariant.PICKUP_BOMB then
                    if settings.pickUpBombs then
                        if entity.SubType == BombSubType.BOMB_NORMAL and nBombs < 99 then
                            nBombs = nBombs + 1
                            teleport = true
                        elseif entity.SubType == BombSubType.BOMB_DOUBLEPACK and nBombs < 98 then
                            nBombs = nBombs + 2
                            teleport = true
                        end
                    end
                    if entity.SubType == BombSubType.BOMB_GOLDEN and settings.pickUpGoldenBombs then
                        teleport = true
                    end
                elseif entity.Variant == PickupVariant.PICKUP_KEY then
                    if settings.pickUpKeys then
                        -- ignore charged keys
                        if entity.SubType == KeySubType.KEY_NORMAL and nKeys < 99 then
                            entity.Position = Vector(player.Position.X, player.Position.Y)
                            nKeys = nKeys + 1
                            teleport = true
                        elseif entity.SubType == KeySubType.KEY_DOUBLEPACK and nKeys < 98 then
                            nKeys = nKeys + 2
                            teleport = true
                        end
                    end
                    if settings.pickUpGoldenKeys and entity.SubType == KeySubType.KEY_GOLDEN then
                        teleport = true
                    end
                elseif entity.Variant == PickupVariant.PICKUP_GRAB_BAG and settings.pickUpBags then
                    teleport = true
                elseif entity.Variant == PickupVariant.PICKUP_PILL and settings.pickUpPills then
                    teleport = true
                elseif entity.Variant == PickupVariant.PICKUP_TAROTCARD and settings.pickUpCards then
                    teleport = true
                elseif entity.Variant == PickupVariant.PICKUP_HEART then
                    if entity.SubType == HeartSubType.HEART_FULL and settings.pickUpRedHearts then
                        if nHearts + 2 <= maxHearts then
                            nHearts = nHearts + 2
                            teleport = true
                        end
                    end
                    if entity.SubType == HeartSubType.HEART_HALF and settings.pickUpRedHearts then
                        if nHearts + 1 <= maxHearts then
                            nHearts = nHearts + 1
                            teleport = true
                        end
                    end
                    if entity.SubType == HeartSubType.HEART_DOUBLEPACK and settings.pickUpRedHearts then
                        if nHearts + 4 <= maxHearts then
                            nHearts = nHearts + 4
                            teleport = true
                        end
                    end
                    if entity.SubType == HeartSubType.HEART_SOUL and settings.pickUpSoulHearts then
                        if nSoulHearts + 2 <= (heartLimit - maxHearts) then
                            nSoulHearts = nSoulHearts + 2
                            teleport = true
                        end
                    end
                    if entity.SubType == HeartSubType.HEART_HALF_SOUL and settings.pickUpSoulHearts then
                        if nSoulHearts + 1 <= (heartLimit - maxHearts) then
                            nSoulHearts = nSoulHearts + 1
                            teleport = true
                        end
                    end
                    if entity.SubType == HeartSubType.HEART_BLACK and settings.pickUpSoulHearts then
                        if nSoulHearts + 2 <= (heartLimit - maxHearts) then
                            nSoulHearts = nSoulHearts + 2
                            teleport = true
                        end
                    end
                elseif entity.Variant == PickupVariant.PICKUP_CHEST and entity.SubType == ChestSubType.CHEST_CLOSED and settings.openChests then
                    pickUpEntity:TryOpenChest()
                end

                if teleport then
                    entity.Position = Vector(player.Position.X, player.Position.Y)
                end
            end
        end
        temporaryEntity:Remove()
    end
end

local function onPostUpdate()
    local nPlayers = Game():GetNumPlayers()
    for i = 0, nPlayers do
        local player = Game():GetPlayer(i)
        pickUpResources(player)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, onPostUpdate)

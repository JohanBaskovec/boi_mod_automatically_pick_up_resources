local json = require("json")
local mod = RegisterMod("Pick up resources with one keypress", 1)

defaultSettings = {
    keyboardKey = Keyboard.KEY_C
}

settings = defaultSettings

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

local function setupMyModConfigMenuSettings()
    if ModConfigMenu == nil then
        return
    end

    ModConfigMenu.AddSetting(
            mod.Name,
            nil,
            {
                Type = ModConfigMenu.OptionType.KEYBIND_KEYBOARD,
                CurrentSetting = function()
                    return settings.keyboardKey
                end,
                Default = Keyboard.KEY_C,
                Display = function()
                    currentValue = settings.keyboardKey
                    key = "None"

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
                    "The keyboard key tp pick up resources in the room",
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
end

setupMyModConfigMenuSettings()

buttonsPressedLast = false
buttonsPressed = false
BUTTON_STICK_LEFT = 10

local function pickUpResources(player)
    controllerIndex = player.ControllerIndex

    -- Player must release the buttons and press them again to do the action
    buttonsPressed = Input.IsButtonPressed(settings.keyboardKey, controllerIndex) or
            (Input.IsActionPressed(ButtonAction.ACTION_DROP, controllerIndex) and Input.IsButtonPressed(BUTTON_STICK_LEFT, controllerIndex))
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
        entityType = EntityType.ENTITY_MAGGOT
        temporaryEntity = Game():Spawn(
                entityType, -- Type
                0, -- Variant
                player.Position, -- Position
                Vector(0, 0), -- Velocity
                nil, -- Parent
                0, -- SubType
                Game():GetRoom():GetSpawnSeed() -- Seed (the "GetSpawnSeed()" function gets a reproducible seed based on the room, e.g. "2496979501")
        )                       :ToNPC()

        entities = room:GetEntities()
        nCoins = player:GetNumCoins()
        nBombs = player:GetNumBombs()
        nKeys = player:GetNumKeys()
        for i, entity in ipairs(Isaac.GetRoomEntities()) do
            pickUpEntity = entity:ToPickup()
            temporaryEntity.Position = Vector(entity.Position.X, entity.Position.Y)
            if pickUpEntity ~= nil and (not pickUpEntity:IsShopItem()) and (temporaryEntity.Pathfinder:HasPathToPos(player.Position, true) or player.CanFly) then
                teleport = false
                if entity.Variant == PickupVariant.PICKUP_COIN then
                    if entity.SubType == CoinSubType.COIN_PENNY or entity.SubType == CoinSubType.COIN_LUCKYPENNY or entity.SubType == CoinSubType.COIN_GOLDEN then
                        if nCoins < 99 then
                            nCoins = nCoins + 1
                            teleport = true
                        end
                    elseif entity.SubType == CoinSubType.COIN_DOUBLEPACK then
                        if nCoins < 98 then
                            nCoins = nCoins + 2
                            teleport = true
                        end
                    elseif entity.SubType == CoinSubType.COIN_NICKEL then
                        if nCoins < 95 then
                            nCoins = nCoins + 5
                            teleport = true
                        end
                    elseif entity.SubType == CoinSubType.COIN_DIME then
                        if nCoins < 90 then
                            nCoins = nCoins + 10
                            teleport = true
                        end
                    end
                elseif entity.Variant == PickupVariant.PICKUP_BOMB then
                    if entity.SubType == BombSubType.BOMB_NORMAL then
                        if nBombs < 99 then
                            nBombs = nBombs + 1
                            teleport = true
                        end
                    elseif entity.SubType == BombSubType.BOMB_DOUBLEPACK then
                        if nBombs < 98 then
                            nBombs = nBombs + 2
                            teleport = true
                        end
                    elseif entity.SubType == BombSubType.BOMB_GOLDEN then
                        teleport = true
                    end
                elseif entity.Variant == PickupVariant.PICKUP_KEY then
                    -- ignore charged keys
                    if entity.SubType == KeySubType.KEY_NORMAL then
                        if nKeys < 99 then
                            entity.Position = Vector(player.Position.X, player.Position.Y)
                            nKeys = nKeys + 1
                            teleport = true
                        end
                    elseif entity.SubType == KeySubType.KEY_DOUBLEPACK then
                        if nKeys < 98 then
                            nKeys = nKeys + 2
                            teleport = true
                        end
                    elseif entity.SubType == KeySubType.KEY_GOLDEN then
                        teleport = true
                    end
                elseif entity.Variant == PickupVariant.PICKUP_GRAB_BAG or entity.Variant == PickupVariant.PICKUP_PILL or entity.Variant == PickupVariant.PICKUP_TAROTCARD then
                    teleport = true
                elseif entity.Variant == PickupVariant.PICKUP_HEART then
                    if entity.SubType == HeartSubType.HEART_FULL or entity.SubType == HeartSubType.HEART_HALF or entity.SubType == HeartSubType.HEART_SOUL or entity.SubType == HeartSubType.HEART_DOUBLEPACK or entity.SubType == HeartSubType.HEART_BLACK then
                        teleport = true
                    end
                elseif entity.Variant == PickupVariant.PICKUP_CHEST and entity.SubType == ChestSubType.CHEST_CLOSED then
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
    nPlayers = Game():GetNumPlayers()
    for i = 0, nPlayers do
        player = Game():GetPlayer(i)
        pickUpResources(player)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, onPostUpdate)

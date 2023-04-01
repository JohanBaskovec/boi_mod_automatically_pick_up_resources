-- Teleport resources in the room to the player and open chests when pressing the Shoot left and Drop buttons.
-- Teleport these items: all normal coins (penny, nickel, dime), normal bombs and keys (until limit of 99),
-- golden bombs and keys, all cards, all pills, all bags, normal hearts (halfs, full, double), soul hearts, black hearts
-- Open all normal chests, ignore others
-- Items that are not teleported: everything else (batteries, charged keys, eternal, bone and rotten hearts...)
local mod = RegisterMod("Pick up resources with one keypress", 1)

lastPickUpResourcesAction = 0
buttonsPressedLast = false
buttonsPressed = false

local function pickUpResources(player)
    controllerIndex = player.ControllerIndex

    -- Player must release the buttons and press them again to do the action
    buttonsPressed = Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, controllerIndex) and Input.IsActionPressed(ButtonAction.ACTION_DROP, controllerIndex)
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
    for i=0, nPlayers do
        player = Game():GetPlayer(i)
        pickUpResources(player)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, onPostUpdate)

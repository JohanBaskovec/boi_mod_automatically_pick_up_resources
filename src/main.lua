-- Teleport resources in the room to the player when pressing the Shoot left and Drop buttons.
-- Items teleported are: all hearts, all coins, bombs and keys (until limit of 99), all cards, all pills, and all bags
-- Open all normal chests
-- Items that are not teleported: batteries, charged keys, eternal hearts
local mod = RegisterMod("Automatically pick up resources", 1)

lastPickUpResourcesAction = 0
buttonsPressedLast = false
buttonsPressed = false

local function pickUpResources()
    -- Player must release the buttons and press them again to do the action
    buttonsPressed = Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, 0) and Input.IsActionPressed(ButtonAction.ACTION_DROP, 0)
    if not buttonsPressed then
        buttonsPressedLast = false
        return
    end
    if buttonsPressedLast then
        return
    end
    buttonsPressedLast = buttonsPressed

    local room = Game():GetRoom()

    player = Game():GetPlayer(0)
    -- Only allow in empty room to prevent accidentally triggering picking up an item and playing the pickup animation
    -- and to prevent "cheating" (for example teleporting a heart from the other side on the room that could save your life)
    if room:IsClear() then
        -- We spawn a temporary NPC in order to use its PathFinder, and remove it when we don't need it anymore
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
                    if entity.SubType == CoinSubType.COIN_PENNY or entity.SubType == CoinSubType.COIN_LUCKYPENNY then
                        if nCoins < 99 then
                            nCoins = nCoins + 1
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
                    if entity.SubType ~= HeartSubType.HEART_ETERNAL then
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

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, pickUpResources)

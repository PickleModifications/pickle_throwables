local ThrowingPower = 1
local Throwables = {}
local canInteract = true
local attemptingCatch = false
local holdingBall = nil

function GetClosestPlayer(coords, radius)
    local closest
    local coords = coords or GetEntityCoords(PlayerPedId())
    local radius = radius or 2.0
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if PlayerPedId() ~= ped then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(coords - pedCoords)
            if distance < radius and (not closest or closest.distance > distance) then
                closest = {player = player, distance = distance}
            end
        end
    end
    return closest?.player, closest?.distance
end

function GetDirectionFromRotation(rotation)
    local dm = (math.pi / 180)
    return vector3(-math.sin(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.cos(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.sin(dm * rotation.x))
end

function PerformPhysics(throwType, entity, action)
    local cfg = Config.Throwables[throwType]
    local power = (ThrowingPower / 10) * cfg.maxThrowingPower
    FreezeEntityPosition(entity, false)
    local rot = GetGameplayCamRot(2)
    local dir = GetDirectionFromRotation(rot)
    SetEntityHeading(entity, rot.z + 90.0)
    if not action or action == "throw" then 
        SetEntityVelocity(entity, dir.x * power, dir.y * power, dir.z * power)
    else
        SetEntityVelocity(entity, dir.x * power, dir.y * power, (dir.z * 1.75) * power)
    end
end

function CreateThrowable(throwType, attach)
    local cfg = Config.Throwables[throwType]
    local ped = PlayerPedId()
    local model = cfg.model
    local heading = GetEntityHeading(ped)
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.5)
    local prop
    if cfg.entityType == "object" then 
        prop = CreateProp(model, coords.x, coords.y, coords.z, true, true, true)
    elseif cfg.entityType == "vehicle" then 
        prop = CreateVeh(model, coords.x, coords.y, coords.z, true, true, true)
    elseif cfg.entityType == "ped" then 
        prop = CreateNPC(model, coords.x, coords.y, coords.z, true, true, true)
    end
    if not prop then return end
    if attach then 
        local off, rot = vector3(0.05, 0.0, -0.085), vector3(90.0, 90.0, 0.0)
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), off.x, off.y, off.z, rot.x, rot.y, rot.z, false, false, false, true, 2, true)
    else 
        local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, -0.9)
        SetEntityCoords(prop, coords.x, coords.y, coords.z)
    end
    return prop
end

function HoldThrowable(throwType)
    local ped = PlayerPedId()
    if holdingBall then return end
    local prop = CreateThrowable(throwType, true)
    holdingBall = prop
    CreateThread(function()
        while holdingBall do 
            local player, dist = GetClosestPlayer()
            if player then 
                ShowInteractText(_L("throwable_list", ThrowingPower .. "/" .. 10))
            else
                ShowInteractText(_L("throwable_list_alt", ThrowingPower .. "/" .. 10))
            end
            if IsControlJustPressed(1, 51) then 
                CreateThread(function()
                    PlayAnim(ped, "melee@thrown@streamed_core", "plyr_takedown_front", -8.0, 8.0, -1, 49)
                    Wait(600)
                    ClearPedTasks(ped)
                end)
                Wait(550)
                DetachEntity(prop, false, true)
                SetEntityCollision(prop, true, true)
                SetEntityRecordsCollisions(prop, true)
                TriggerServerEvent("pickle_throwables:throwObject", {throwType = throwType, net_id = ObjToNet(prop)})
                local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 1.0)
                SetEntityCoords(prop, coords.x, coords.y, coords.z)
                SetEntityHeading(prop, GetEntityHeading(ped) + 90.0)
                PerformPhysics(throwType, prop)   
                holdingBall = nil
            elseif IsControlJustPressed(1, 47) then 
                PlayAnim(ped, "pickup_object", "pickup_low", -8.0, 8.0, -1, 49, 1.0)
                Wait(800)
                DetachEntity(prop, true, true)
                SetEntityCollision(prop, true, true)
                SetEntityRecordsCollisions(prop, true)
                ActivatePhysics(prop)
                TriggerServerEvent("pickle_throwables:throwObject", {throwType = throwType, net_id = ObjToNet(prop)})
                Wait(800)
                ClearPedTasks(ped)
                holdingBall = nil
            elseif IsControlJustPressed(1, 74) then 
                if player then 
                    ServerCallback("pickle_throwables:giveObject", function(result)
                        if not result then return end
                        DeleteEntity(prop)
                        holdingBall = nil
                        PlayAnim(PlayerPedId(), "mp_common", "givetake1_b", -8.0, 8.0, -1, 49, 1.0)
                        Wait(1600)
                        ClearPedTasks(ped)
                    end, GetPlayerServerId(player))
                else
                    ServerCallback("pickle_throwables:storeObject", function(result)
                        if not result then return end
                        PlayAnim(PlayerPedId(), "pickup_object", "putdown_low", -8.0, 8.0, -1, 49, 1.0)
                        Wait(1600)
                        ClearPedTasks(ped)
                        DeleteEntity(prop)
                        holdingBall = nil
                    end)
                end
            end
            PowerControls()
            Wait(0)
        end
    end)
end

function CatchObject(index, cb)
    if attemptingCatch then return end
    attemptingCatch = true
    local data = Throwables[index]
    local entity = NetToObj(data.net_id)
    SetEntityCollision(entity, false, false)
    DeleteEntity(entity)
    ServerCallback("pickle_throwables:catchObject", cb, index)
    Wait(100)
    attemptingCatch = false
end

function PowerControls()
    if IsControlJustPressed(1, 181) then 
        ThrowingPower = (ThrowingPower + 1 > 10 and 10 or ThrowingPower + 1)
    elseif IsControlJustPressed(1, 180) then 
        ThrowingPower = (ThrowingPower - 1 < 1 and 1 or ThrowingPower - 1)
    end
end

CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        for k,v in pairs(Throwables) do 
            if NetworkDoesNetworkIdExist(v.net_id) then 
                local entity = NetToObj(v.net_id)
                local dist = #(GetEntityCoords(ped) - GetEntityCoords(entity))
                if dist < Config.RenderDistance then
                    wait = 0
                    if not holdingBall and canInteract and dist < Config.CatchRadius and not ShowInteractText(_L("throwable_interact", ThrowingPower .. "/" .. 10)) then 
                        if IsControlJustPressed(1, 51) then 
                            CatchObject(k, function(result) 
                                if not result then return end
                                HoldThrowable(v.throwType)
                            end)
                        elseif IsControlJustPressed(1, 47) then 
                            CatchObject(k, function(result) 
                                if not result then return end
                                canInteract = false
                                local prop = CreateThrowable(v.throwType, false)
                                TriggerServerEvent("pickle_throwables:throwObject", {throwType = v.throwType, net_id = ObjToNet(prop)})
                                --FreezeEntityPosition(ped, true)
                                --PlayAnim(ped, "melee@unarmed@streamed_core", "ground_attack_0", -8.0, 8.0, -1, 33, 1.0)
                                --Wait(1000)
                                PerformPhysics(v.throwType, prop, "kick")   
                                --Wait(600)
                                --ClearPedTasks(ped)
                                --FreezeEntityPosition(ped, false)
                                canInteract = true
                            end)
                        end
                        PowerControls()
                    end
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent("pickle_throwables:giveObject", function(data)
    HoldThrowable(data.throwType)
end)

RegisterNetEvent("pickle_throwables:setObjectData", function(throwID, data)
    Throwables[throwID] = data
end)

AddEventHandler("onResourceStop", function(name) 
    if (GetCurrentResourceName() ~= name) then return end
    for k,v in pairs(Throwables) do 
        DeleteEntity(NetToObj(v.net_id))
    end
end)
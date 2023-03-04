local Throwables = {}
local Carrying = {}

function GiveObject(source, data, timeout)
    Carrying[source] = data
    if timeout then 
        SetTimeout(1600, function()
            TriggerClientEvent("pickle_throwables:giveObject", source, data)
        end)
    else
        TriggerClientEvent("pickle_throwables:giveObject", source, data)
    end
end

RegisterNetEvent("pickle_throwables:throwObject", function(data)
    local source = source
    if not Carrying[source] then return end
    Carrying[source] = nil
    local throwID = nil
    repeat
        throwID = os.time() .. "_" .. math.random(1000, 9999)
    until not Throwables[throwID] 
    Throwables[throwID] = data
    TriggerClientEvent("pickle_throwables:setObjectData", -1, throwID, data)
end)

RegisterCallback("pickle_throwables:catchObject", function(source, cb, throwID) 
    if Carrying[source] then return cb(false) end
    if not Throwables[throwID] then return cb(false) end
    local entity = NetworkGetEntityFromNetworkId(Throwables[throwID].net_id)
    Carrying[source] = {throwType = Throwables[throwID].throwType}
    DeleteEntity(entity)
    Throwables[throwID] = nil
    TriggerClientEvent("pickle_throwables:setObjectData", -1, throwID, nil)
    cb(true)
end)

RegisterCallback("pickle_throwables:storeObject", function(source, cb) 
    if not Carrying[source] then return cb(false) end
    local data = Carrying[source]
    local cfg = Config.Throwables[data.throwType]
    Carrying[source] = nil
    if cfg.item and not Config.CommandSpawning then 
        AddItem(source, cfg.item, 1)
    end
    cb(true)
end)

RegisterCallback("pickle_throwables:giveObject", function(source, cb, target)
    if not Carrying[source] or Carrying[target] then return cb(false) end
    local data = Carrying[source]
    GiveObject(target, {throwType = data.throwType}, true)
    Carrying[source] = nil
    cb(true)
end)

if Config.CommandSpawning then 
    RegisterCommand("spawnthrowable", function(source, args, raw)
        if not args[1] or not Config.Throwables[args[1]] then return end
        if not Config.CommandSpawnCheck(source, args[1]) then return end
        GiveObject(source, {throwType = args[1]})
    end)
else
    for k,v in pairs(Config.Throwables) do 
        if v.item then 
            RegisterUsableItem(v.item, function(source)
                if Carrying[source] then return end
                RemoveItem(source, v.item, 1)
                GiveObject(source, {throwType = k})
            end)
        end
    end
end
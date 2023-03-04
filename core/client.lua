function ModelRequest(modelHash)
    if not IsModelInCdimage(modelHash) then return end
    RequestModel(modelHash)
    local loaded
    for i=1, 100 do 
        if HasModelLoaded(modelHash) then
            loaded = true 
            break
        end
        Wait(100)
    end
    return loaded
end

function CreateVeh(modelHash, ...)
    if not ModelRequest(modelHash) then 
        print("Couldn't load model: " .. modelHash)
        return 
    end
    local veh = CreateVehicle(modelHash, ...)
    SetModelAsNoLongerNeeded(modelHash)
    return veh
end

function CreateNPC(modelHash, ...)
    if not ModelRequest(modelHash) then 
        print("Couldn't load model: " .. modelHash)
        return 
    end
    local ped = CreatePed(26, modelHash, ...)
    SetModelAsNoLongerNeeded(modelHash)
    return ped
end

function CreateProp(modelHash, ...)
    if not ModelRequest(modelHash) then 
        print("Couldn't load model: " .. modelHash)
        return 
    end
    local obj = CreateObject(modelHash, ...)
    SetModelAsNoLongerNeeded(modelHash)
    return obj
end

function PlayAnim(ped, dict, ...)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(ped, dict, ...)
end

local interactTick = 0
local interactThread = false
local interactText = nil

function ShowInteractText(text)
    interactTick = GetGameTimer()
    lib.showTextUI(text)
    if interactThread then return end
    interactThread = true
    CreateThread(function()
        while interactThread do
            if GetGameTimer() - interactTick > 20 then 
                interactThread = false
                break
            end 
            Citizen.Wait(150)
        end
        lib.hideTextUI()
    end)
end
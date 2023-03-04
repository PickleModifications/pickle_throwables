Config = {}

Config.Debug = true

Config.Language = "en"

Config.RenderDistance = 20.0
Config.CatchRadius = 2.5

Config.CommandSpawning = false -- Set this to true if you want to be able to get throwables without using items.

Config.CommandSpawnCheck = function()
    return true
end

Config.Throwables = {
    ["football"] = {
        item = "football",
        entityType = "object", -- "object", "vehicle", "ped"
        model = `p_ld_am_ball_01`,
        maxThrowingPower = 200
    },
    ["basketball"] = {
        item = "basketball",
        entityType = "object", -- "object", "vehicle", "ped"
        model = `prop_bskball_01`,
        maxThrowingPower = 200
    },
    ["baseball"] = {
        item = "baseball",
        entityType = "object", -- "object", "vehicle", "ped"
        model = `w_am_baseball`,
        maxThrowingPower = 200
    },
    ["soccer"] = {
        item = "soccer",
        entityType = "object", -- "object", "vehicle", "ped"
        model = `p_ld_soc_ball_01`,
        maxThrowingPower = 200
    },
}
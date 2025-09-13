---Changes that depend on other mods
local rebalance_lib = require("__space-anal-justice__.rebalance-lib")


--#region General/Quality

--Module/beacon scaling is way too much. Halve it
for _, entry in pairs(data.raw.beacon) do
    if entry.distribution_effectivity_bonus_per_quality_level then 
        entry.distribution_effectivity_bonus_per_quality_level = 0.5 * entry.distribution_effectivity_bonus_per_quality_level
    end
end

--Set the given recipe prototype's max prod to that value, while respecting any limits from before.
local function set_max_prod(recipe_name, value)
    local recipe = data.raw.recipe[recipe_name]
    if not recipe then return end
    local old_max = recipe.maximum_productivity or 999999
    recipe.maximum_productivity = math.min(old_max, value)
end
--Make LDS shuffle and blue circuits cap out to avoid infinite free quality stuff
local NEW_MAX_PROD = 2.75
set_max_prod("low-density-structure", NEW_MAX_PROD)
set_max_prod("casting-low-density-structure", NEW_MAX_PROD)
set_max_prod("processing-unit", NEW_MAX_PROD)


--#endregion
--#region Fulgora

--In order to scale things better on Fulgora, it needs to be easier to void things. 
rebalance_lib.recipe_time_cost_magnifier("low-density-structure-recycling", 0.5)
rebalance_lib.recipe_time_cost_magnifier("advanced-circuit-recycling", 0.5)
rebalance_lib.recipe_time_cost_magnifier("processing-unit-recycling", 0.5)
rebalance_lib.recipe_time_cost_magnifier("copper-plate-recycling", 0.5)
rebalance_lib.recipe_time_cost_magnifier("iron-plate-recycling", 0.5)

--#endregion
--#region Gleba

--Gleba: Bioflux needs a paired self-recycle recipe.
log(serpent.block(data.raw.recipe["bioflux-recycling"]))

--Add back in the normal bioflux-recyucling recipe, but lock it so it is NOT locked to gleba.

--Bioflux to mash is locked to gleba for quality grinding
local new_recycling = data.raw.recipe["bioflux-recycling"]
new_recycling.surface_conditions = {{property = "pressure", min = 2000, max = 2000}}
new_recycling.results =
    {
      {type = "item", name = "yumako-mash", amount = 3, extra_count_fraction = 0.75, ignored_by_stats = 4},
      {type = "item", name = "jelly", amount = 3, ignored_by_stats = 3,}
    }
--Bioflux to itself is allowed everywhere else
data:extend({
{
    name = "bioflux-recycling-original",
    surface_conditions = {{property = "pressure", max = 1999}},
    category = "recycling",
    type = "recipe",
    crafting_machine_tint = {
        primary = { a = 1, b = 0.8, g = 0.9, r = 0.3},
        secondary = {a = 1, b = 0.3, g = 0.5, r = 0.8}
    },
    enabled = true,
    energy_required = 0.375,
    hidden = true,
    icons = {{icon = "__quality__/graphics/icons/recycling.png"},
        {icon = "__space-age__/graphics/icons/bioflux.png", scale = 0.4},
        {icon = "__quality__/graphics/icons/recycling-top.png"}
    },
    ingredients = {
        { amount = 1, ignored_by_stats = 1, name = "bioflux", type = "item"}
    },
    localised_name = {"recipe-name.recycling", {"item-name.bioflux" }},
    results = {
        {amount = 1, ignored_by_stats = 1, name = "bioflux", probability = 0.25, type = "item"}
    },
    subgroup = "agriculture-products",
    unlock_results = false,
}
})

--Give gleba a way to void iron ore
local ore_void = data.raw.recipe["iron-ore-recycling"]
if ore_void then
    rebalance_lib.add_recipe_category("iron-ore-recycling", "organic")
    ore_void.allow_productivity = false
    ore_void.hidden = false
    ore_void.hidden_in_factoriopedia = false
    ore_void.subgroup = "agriculture-processes"
    ore_void.order = "b[agriculture]-d[bacteria]-a[iron-bacteria]-b"
end

--The enemies are really the worst-balanced part of Gleba. We need to nerf them, because it's really bullshit that you need foreign weaponry to defend yourself once they evolve.
--Make rocket turrets more capable of shooting them down normally
local rocket_turret = data.raw["ammo-turret"]["rocket-turret"]
if rocket_turret then
    rocket_turret.attack_parameters.range = 50 --Default 36
end
--Make rockets faster to compensate
local ROCKET_START_SPEED_MULT = 3
local ROCKET_ACCEL_MULT = 3
local projectiles = {}
for _, entry in pairs(data.raw.ammo) do
    if entry.ammo_category == "rocket" and entry.ammo_type then
        --Actions are either an array or one action. Consolidate to array.
        local to_consider = {}
        if entry.ammo_type.action then table.insert(to_consider, entry.ammo_type.action)
        else to_consider = entry.ammo_type end

        for _, action in pairs(to_consider or {}) do
            if action.action_delivery and action.action_delivery.starting_speed then
                action.action_delivery.starting_speed = ROCKET_START_SPEED_MULT * action.action_delivery.starting_speed
            end
            --Go get its projectile to speed it up
            if action.action_delivery and action.action_delivery.type == "projectile"
                and action.action_delivery.projectile then
                table.insert(projectiles, action.action_delivery.projectile)
            end
        end
    end
end
--Make the projectiles themselves also faster
for _, entry in pairs(projectiles) do
    local projectile = data.raw["projectile"][entry]
    if projectile then
        if projectile.acceleration then projectile.acceleration = projectile.acceleration * ROCKET_ACCEL_MULT end
        if projectile.turn_speed then projectile.turn_speed = projectile.turn_speed * ROCKET_ACCEL_MULT end
    end
end
--[[
for name, entry in pairs(data.raw["spider-unit"]) do
    if string.find(name, "stomper-pentapod",1,true)
        or string.find(name, "strafer-pentapod",1,true) then 
        entry.attack_parameters.range = 6.5-- * scale
    end
end]]

--#endregion
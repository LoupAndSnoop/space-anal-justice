

local rebalance_lib = require("__anal-justice__.rebalance-lib")


--#region Nauvis

--Nauvis needs a better niche.


--#endregion

--#region Vulcanus

---Vulcanus' main weakness is supposed to be petrochemistry, but it is waaay to easy to scale, 
---so many people just make their bases here with no drawback. Start by nerfing Vulcan methods for oil.
local edits = {
    {
        recipe_name = "simple-coal-liquefaction",
        time_multiplier = 2,
        cost_multiplier = 2,
        yield_multiplier = 0.5
    },
    {
        recipe_name = "coal-liquefaction",
        time_multiplier = 2,
        cost_multiplier = 2,
        yield_multiplier = 0.5
    },
    {
        recipe_name = "steam-condensation",
        time_multiplier = 3,
        yield_multiplier = 0.5
    },
}

for _, entry in pairs(edits) do
    rebalance_lib.recipe_edit(entry)
end

--Vulcanus orange sci really doesn't make sense for vulcanus. Vulcanus is all about high throughput, bigass scale,
--and leveraging big-time casting! Totally change the recipe.
--Big electric pole is a really good candidate because: 1) assembling the pole is trivial, 
--2) the recipe forces you to just cast a shitload of steel, iron stick, and copper cable.
--Tungsten carbide can stay, since 1) plates are already needed for green belts, 2) it ties together vulcan petrochem.
--Carbide costs can go down tho, since I still want to hurt people scaling up petrochem.
--Molten copper is no longer needed.
--Instead, let's go for refined concrete to further hammer in on Vulcanus's core strength, since that needs you to cast a bunch of crap, and use all that stone.
local orange_sci = data.raw.recipe["metallurgic-science-pack"]
if orange_sci then
    orange_sci.ingredients =
        {
        {type = "item", name = "big-electric-pole", amount = 5},
        {type = "item", name = "tungsten-carbide", amount = 2},
        {type = "item", name = "refined-concrete", amount = 5},
        }
    orange_sci.energy_required = 10 * 2
end

--To do refined concrete, we need to buff its water cost (less cost), since vulc is now the only place that wants to scale it.
rebalance_lib.recipe_cost_magnifier("refined-concrete", 0.6, "water")

--#endregion


--#region Fulgora
---If you didn't see this coming, you're a dumbass.
rebalance_lib.recipe_yield_magnifier("holmium-solution", 3)

--I always thought this was a missed opportunity. Scrap now needs lube (which is trivial to make) to mine
local scrap = data.raw.resource.scrap
if scrap and scrap.minable then
    scrap.minable.required_fluid = "lubricant"
end

--Fulgora needs help voiding things more efficiently. It's stupidly hard to scale ANYTHING. I'm going to fix this with some unique scrap recipes.
--TODO




--#endregion


--#region Gleba -----------------------

--Gleba is perfect. But it can be even more perfect if the biochamber wasn't so terrible outside gleba. This is going to need
--a multiple pronged approach. First, it needs to be more powerful when it is used for a recipe, and it also needs more recipes 
--where it is good.
local biochamber = data.raw["assembling-machine"]["biochamber"]
if biochamber then
    biochamber.module_slots = 6 --Needs more modules because the power consumption is a real drawback to work around.
    biochamber.effect_receiver.base_effect.productivity = 1 --It really needs some prod to sweeten the deal
    biochamber.quality_affects_energy_usage = true

    --Energy usage goes down with higher quality
    local energy_quality = {}
    for name, entry in pairs(data.raw.quality) do
        energy_quality[name] = math.max((1.1 - (entry.level or 1) * 0.1), 0.2)
    end
    biochamber.energy_usage_quality_multiplier = energy_quality
end

--Fixing the lack of good recipes
rebalance_lib.add_recipe_category("holmium-solution", "organic")
rebalance_lib.add_recipe_category("utility-science-pack", "organic")
rebalance_lib.add_recipe_category("production-science-pack", "organic")
--rebalance_lib.add_recipe_category("promethium-science-pack", "organic")

--The enemies are really the worst-balanced part of Gleba. We need to nerf them, because it's really bullshit that you need foreign weaponry to defend yourself once they evolve.
---TODO


--Fix the poor endgame scaling of Gleba with respect to quality grinding.
--Being able to properly recycle bioflux 
local bioflux = data.raw.recipe.bioflux
if bioflux then bioflux.auto_recycle = true end
local bioflux_item = data.raw.item.bioflux
if bioflux_item then bioflux_item.auto_recycle = true end


--Many people don't automate bacteria on gleba. That is extremely lame. Let's fix the science a bit.
--This recipe is actually easier, but does require you to actually play the damn planet.
local agri_sci = data.raw.recipe["metallurgic-science-pack"]
if agri_sci then
    agri_sci.ingredients = {
      {type = "item", name = "iron-bacteria", amount = 1},
      {type = "item", name = "pentapod-egg", amount = 1}
    }
end


--#endregion

--#region Space

--Productivity should have never applied to 
local reprocessing_recipes = {"metallic-asteroid-reprocessing", "carbonic-asteroid-reprocessing", "oxide-asteroid-reprocessing"}
local processing_recipes = {"metallic-asteroid-crushing", "carbonic-asteroid-crushing", "oxide-asteroid-crushing",
    "advanced-metallic-asteroid-crushing", "advanced-carbonic-asteroid-crushing", "advanced-oxide-asteroid-crushing"}
local asteroid_names = {["metallic-asteroid"] = true, ["carbonic-asteroid-chunk"] = true, ["oxide-asteroid-chunk"]=true}
for _, entry in pairs(processing_recipes) do
    local recipe = data.raw.recipe[entry]
    assert(recipe, "Did not find: " .. entry)
    for _, product in pairs(recipe.results or {}) do
        if asteroid_names[product.name or ""] then
            product.ignored_by_productivity = 1000
        end
    end
end


--Reign in casinos a little. Casinos are still allowed, but they are getting a nerf.
local crusher = data.raw["assembling-machine"].crusher
if crusher then
    crusher.effect_receiver = crusher.effect_receiver or {}
    crusher.effect_receiver.base_effect = crusher.effect_receiver.base_effect or {}
    crusher.effect_receiver.base_effect.quality = -0.02
end

--#endregion


--#region Aquilo

--Aquilo is mostly fine. The cryo plant is just a bit limitted in its utility.
rebalance_lib.add_recipe_category("chemical-science-pack", "cryogenics")



--#endregion
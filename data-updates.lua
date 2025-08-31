

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
--This is a library of functions to rebalance things.
local rebalance_lib = {}
local DEBUG_MODE = true

---Get the current average of how much material is actualy consumed/produced on average.
---@param material data.ProductPrototype | data.IngredientPrototype Prototype of a specific product.
local function average_amount(material)
    local probability = material.probability or 1
    local amount = material.amount or ((material.amount_max + material.amount_min) * 0.5)
    if material.extra_count_fraction then amount = material.extra_count_fraction * probability end
    return amount * probability
end


---Multiply the amount of how much a recipe produces/consumes on this specific prototype by a specific number.
---Do NOT propagate to a possible catalyst.
---@param product data.ProductPrototype | data.IngredientPrototype Prototype of a specific product or ingredient.
---@param multiplier number Multiplier for the cost of each item of a recipe.
local function material_amount_magnify(product, multiplier)
    local multiply_discrete = function(x, mul)
        if product[x] then product[x] = math.max(1, product[x] * (mul or multiplier)) end
    end
    local multiply_continuous = function(x, mul)
        if product[x] then product[x] = product[x] * (mul or multiplier) end
    end
    local multiply_contextual = (product.type == "fluid") and multiply_continuous or multiply_discrete

    local previous_yield = average_amount(product)

    multiply_contextual("amount")
    multiply_contextual("amount_min")
    multiply_contextual("amount_max")
    if product.amount_max and product.amount_min then
        product.amount_max = math.max( product.amount_max, product.amount_min)
    end
    multiply_continuous("probability")

    --Multiply the extra count fraction, but if we go over into a whole number, then move it into the actual amount.
    if product.extra_count_fraction then
        product.extra_count_fraction = product.extra_count_fraction * multiplier
        local wholes = product.extra_count_fraction - (product.extra_count_fraction % 1)
        if product.amount then product.amount = product.amount + wholes
        else product.amount_min = product.amount_min + wholes
            product.amount_max = product.amount_max + wholes
        end
        product.extra_count_fraction = product.extra_count_fraction - wholes
    end

    --Handle ignored by prod
    local actual_multiplier = average_amount(product) / previous_yield
    multiply_contextual("ignored_by_productivity", actual_multiplier)
    multiply_contextual("ignored_by_stats", actual_multiplier)
end

---Multiply the cost of a specific item of a recipe by the given multiplier. Also change the associated product IF it is catalytic.
---@param recipe data.RecipePrototype
---@param ingredient data.IngredientPrototype Prototype of a specific product or ingredient.
---@param multiplier number Multiplier for the cost of each item of a recipe.
local function ingredient_amount_magnify(recipe, ingredient, multiplier)
    local old_input_avg = average_amount(ingredient)
    material_amount_magnify(ingredient, multiplier)
    local actual_multiplier = average_amount(ingredient) / old_input_avg

    --Take care of catalysis
    for _, entry in pairs(recipe.results or {}) do
        if entry.name == ingredient.name then
            material_amount_magnify(entry, actual_multiplier)
        end --Do not break, because some recipes have the same item in multiple entries
    end
end

---Multiply the cost of each item of a recipe by the given multiplier. Make sure it can't go less than 1. Manage catalysis
---@param recipe_name string name of the recipe prototype
---@param multiplier number Multiplier for the cost of each item of a recipe.
---@param item_name string? If string is set for a specific item, then only apply this to a specific item name
function rebalance_lib.recipe_cost_magnifier(recipe_name, multiplier, item_name)
    local recipe = data.raw.recipe[recipe_name]
    assert(recipe or not DEBUG_MODE, "Did not find: " .. recipe_name)
    if not recipe then return end --Nothing

    for _, entry in pairs(recipe.ingredients or {}) do
        if not (item_name and entry.name ~= item_name) then
            ingredient_amount_magnify(recipe, entry, multiplier)
        end
    end
end

---Multiply the cost of each item of a recipe by the given multiplier. Make sure it can't go less than 1. Manage catalysis
---@param recipe_name string name of the recipe prototype
---@param multiplier number Multiplier for the cost of each item of a recipe.
---@param item_name string? If string is set for a specific item, then only apply this to a specific item name
function rebalance_lib.recipe_yield_magnifier(recipe_name, multiplier, item_name)
    local recipe = data.raw.recipe[recipe_name]
    assert(recipe or not DEBUG_MODE, "Did not find: " .. recipe_name)
    if not recipe then return end --Nothing

    --Make table to identify catalysts
    local all_ingredients = {}
    for _, entry in pairs(recipe.ingredients or {}) do
        all_ingredients[entry.name] = entry
    end

    local do_not_repeat = {} --In case something is put multiple times, don't do it twice if it is on this list

    --Magnify product. If we encounter a catalyst, then use the cost magnifier, because it will propagate.
    for _, entry in pairs(recipe.results or {}) do
        if not (item_name and entry.name ~= item_name) --Relevant item to the search
            and not do_not_repeat[entry.name] then --Not something we need to actively avoid repeating.
            local current_ingredient = all_ingredients[entry.name]
            if current_ingredient then --It is a catalyst
                ingredient_amount_magnify(recipe, current_ingredient, multiplier)
                do_not_repeat[current_ingredient.name] = true
            else --Not a catalyst
                material_amount_magnify(entry, multiplier)
            end
        end
    end
end

---Multiply the energy cost of a given recipe by this value, assuming we can find it!
---@param recipe_name string name of the recipe prototype
---@param multiplier number Multiplier for the cost of each item of a recipe.
function rebalance_lib.recipe_time_cost_magnifier(recipe_name, multiplier)
    local recipe = data.raw.recipe[recipe_name]
    assert(recipe or not DEBUG_MODE, "Did not find: " .. recipe_name)
    if not recipe then return end --Nothing
    if recipe.energy_required then recipe.energy_required = recipe.energy_required * multiplier
    end
end


---Add the given recipe category to this recipe
---@param recipe_name string name of the recipe prototype
---@param new_recipe_category_name string Name of the recipe category to add
function rebalance_lib.add_recipe_category(recipe_name, new_recipe_category_name)
    local recipe = data.raw.recipe[recipe_name]
    assert(recipe or not DEBUG_MODE, "Did not find: " .. recipe_name)
    if not recipe then return end --Nothing

    if recipe.additional_categories then table.insert(recipe.additional_categories, new_recipe_category_name)
    else recipe.additional_categories = {new_recipe_category_name} end
end


---@class RecipeEditParameters
---@field recipe_name string
---@field time_multiplier number?
---@field cost_multiplier number?
---@field yield_multiplier number?
---@field new_recipe_category string?

---One function for many edits.
---@param recipe_edit_params RecipeEditParameters
function rebalance_lib.recipe_edit(recipe_edit_params)
    local name = recipe_edit_params.recipe_name
    if recipe_edit_params.time_multiplier then
        rebalance_lib.recipe_time_cost_magnifier(name, recipe_edit_params.time_multiplier)
    end
    if recipe_edit_params.cost_multiplier then
        rebalance_lib.recipe_cost_magnifier(name, recipe_edit_params.cost_multiplier)
    end
    if recipe_edit_params.yield_multiplier then
        rebalance_lib.recipe_yield_magnifier(name, recipe_edit_params.yield_multiplier)
    end

    if recipe_edit_params.new_recipe_category then
        rebalance_lib.add_recipe_category(name, recipe_edit_params.new_recipe_category)
    end
end





return rebalance_lib
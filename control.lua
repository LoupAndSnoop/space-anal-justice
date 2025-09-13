

--#region Gleba

--Evolution now scales with science production.

--Combine the total amount of ag science produced, with quality-scaling included.
local function get_total_science_produced()
    local ag_sci = 0
    for _, force in pairs(game.forces) do
        local flow_stats = force.get_item_production_statistics("gleba")
        for quality_name, quality in pairs(prototypes.quality) do
            ag_sci = ag_sci + (1 + quality.level) * flow_stats.get_input_count{name = "agricultural-science-pack", quality = quality_name}
        end
    end
    return ag_sci
end

--Calculate the evolution factor for the given amount of science produced.
local function sci_to_evolution(sci)
    --Want evolution of 0 at 0 produced (log1 = 0)
    --Want evolution at 0.4 at around 2000 sci produced. (log = 3.3)
    --Want evolution at 0.7 at around 10000 sci produced. (log = 4)
    --Want evolution at 0.95 at around 20000 sci produced (log = 4.3)
    --Could be linear vs log(x) in each regime. The constants below are calculated to make these numbers connect in individual logs
    local evolution
    local log_sci = math.log(math.max(sci, 1), 10)
    if sci < 2000 then evolution = 0.1212 * log_sci
    elseif sci < 10000 then evolution = 0.42 * log_sci - 0.98
    else evolution = 0.8333 * log_sci - 2.6332
    end

    return math.min(math.max(evolution,0),1) --Clamp to valid bounds
end

--Set Gleba evolution factor based on science produced
script.on_nth_tick(30, function()
    local gleba = game.surfaces["gleba"]
    if not gleba then return end

    local sci = get_total_science_produced()
    local evolution = sci_to_evolution(sci)

    --for _, force in pairs(game.forces) do force.set_evolution_factor(evolution) end
    local enemy = game.forces["enemy"]
    if enemy then enemy.set_evolution_factor(evolution, gleba) end

    --[[ For testing
    local TEST_OLD_EVO = enemy.get_evolution_factor("gleba")
    enemy.set_evolution_factor(evolution, gleba)
    game.print("Previous evo = " .. tostring(TEST_OLD_EVO) 
        .. ", New evo = " .. tostring(evolution) 
        .. ", Total sci = " .. tostring(sci) 
        .. ", Actual new evo = " .. tostring(enemy.get_evolution_factor("gleba")))
    ]]
end)


--#endregion
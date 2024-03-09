

function conversion_action_calc(
    outcome_space::Vector{Tuple{KickoffState, Float64}}
)

    action_value = 0
    # prob_calculated = 0
    for (state, prob) in outcome_space
        outcome_value = state_value_calc(state, false)[1]
        action_value += prob * outcome_value
    end
    
    return action_value
end

function conversion_decision(
    state::ConversionState
)
    global conversion_decision_calc_calls
    conversion_decision_calc_calls += 1
    
    # Check if state is cached
    if haskey(conversion_state_values, state)
        return conversion_state_values[state]
    end

    optimal_action = ""
    optimal_action_value = -Inf

    # Calculate actions
    for action in CONVERSION_ACTIONS
        # Generate outcome space
        outcome_space = GENERATE_CONVERSION_OUTCOME_SPACE[action](state)

        conversion_action_value = conversion_action_calc(outcome_space)
        
        if conversion_action_value > optimal_action_value
            optimal_action = action
            optimal_action_value = conversion_action_value
        end
    end

    conversion_state_values[state] = (optimal_action_value, optimal_action)

    return optimal_action_value, optimal_action
end
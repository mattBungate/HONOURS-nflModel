

function kickoff_action_calc(
    outcome_space::Vector{Tuple{Union{PlayState, ConversionState}, Float64}}
)
    action_value = 0
    # prob_calculated
    for (state, prob) in outcome_space
        outcome_value = state_value_calc(state, false)[1]
        action_value -= prob * outcome_value    # Other team always receives ball
    end

    return action_value
end

function kickoff_decision(
    state::KickoffState
)
    global kickoff_decision_calc_calls
    kickoff_decision_calc_calls += 1

    # Check if state is cached 
    if haskey(kickoff_state_values, state)
        return kickoff_state_values[state]
    end

    optimal_action = ""
    optimal_action_value = -Inf

    # Calculate actions
    for action in KICKOFF_ACTIONS
        # Generate outcome space 
        outcome_space = GENERATE_KICKOFF_OUTCOME_SPACE[action](state)

        kickoff_action_val = kickoff_action_calc(outcome_space)

        if kickoff_action_val > optimal_action_value
            optimal_action = action 
            optimal_action_value = kickoff_action_val
        end
    end

    kickoff_state_values[state] = (optimal_action_value, optimal_action)

    return optimal_action_value, optimal_action
end
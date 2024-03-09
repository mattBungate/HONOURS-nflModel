function play_action_calc(
    outcome_space::Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}}
)::Float64
    action_value = 0
    # prob_calculated = 0
    for (state, prob, change_possession) in outcome_space
        
        next_state_val = state_value_calc(state, false)[1]
        #action_value += prob
        if change_possession
            action_value -= prob * next_state_val
        else
            action_value += prob * next_state_val
        end
    end

    return action_value
end

function play_decision(
    state::PlayState,
    is_root::Bool
)
    global play_decision_calc_calls
    play_decision_calc_calls += 1

    # Check if state is cached
    if haskey(play_state_values, state)
        return play_state_values[state]
    end

    # Interpolate 
    if !is_root
        interpolated_output = interpolate_state_calc(state)
        if interpolated_output !== nothing
            return interpolated_output
        end
    end
    # Check for symmetric state in cache
    sym_state = PlayState(
        state.seconds_remaining,
        -state.score_diff,
        reverse(state.timeouts_remaining),
        state.ball_section,
        state.down,
        state.first_down_dist,
        state.clock_ticking
    )
    if haskey(
        play_state_values,
        sym_state
    )
        sym_val = play_state_values[sym_state]
        return (-sym_val[1], sym_val[2])
    end

    optimal_action = ""
    optimal_action_value = -Inf
    # Calculate Actions
    for action in PLAY_ACTIONS
        # Generate outcome space 
        outcome_space = GENERATE_PLAY_OUTCOME_SPACE[action](state)

        play_action_value = play_action_calc(outcome_space)

        if play_action_value > optimal_action_value
            optimal_action = action
            optimal_action_value = play_action_value 
        end
    end

    play_state_values[state] = (optimal_action_value, optimal_action)

    return optimal_action_value, optimal_action 
end
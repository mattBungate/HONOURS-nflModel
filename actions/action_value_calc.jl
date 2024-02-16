function action_value_calc(
    outcome_space::Vector{Tuple{StateFH, Float64, Int, Bool}},
    is_root::Bool,
    stop_signal::Atomic{Bool}
)::Float64
    action_value = 0
    for (state, prob, reward, change_possession) in outcome_space
        next_state_val = state_value_calc(state, false, "", stop_signal)[1]
        action_value += prob * reward
        if change_possession
            action_value -= prob * next_state_val
        else
            action_value += prob * next_state_val
        end
    end

    return action_value
end
function action_value_calc(
    outcome_space::Vector{Tuple{State, Float64, Bool}},
    is_root::Bool,
    stop_signal::Atomic{Bool}
)::Float64
    
    action_value = 0
    for (state, prob, change_possession) in outcome_space
        next_state_val = state_value_calc(state, false, "", stop_signal)[1]
        if is_root
            if next_state_val > 1
                throw(ArgumentError("Valued state over 1"))
            end
        end
        if change_possession
            action_value -= prob * next_state_val
        else
            action_value += prob * next_state_val
        end
    end

    return action_value
end
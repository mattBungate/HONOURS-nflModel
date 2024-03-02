"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
state: State space currently occupied.
"""
function state_value_calc(
    state::State,
    is_root::Bool,
    best_move::String,
    stop_signal::Atomic{Bool}
)
    if stop_signal[]
        return -1, "Timed out" 
    end
    global state_value_calc_calls
    state_value_calc_calls += 1
    # Base cases
    if state.seconds_remaining <= 0
        return evaluate_game(state)
    end

    # Check if state is cached
    if haskey(state_values, state)
        return state_values[state]
    end

    # Interpolate 
    if !is_root
        interpolated_output = interpolate_state_calc(state, stop_signal)
        if interpolated_output !== nothing
            return interpolated_output
        end
    end

    # Initialise arrays to store action space and associated values
    action_values = Dict{String,Float64}()

    action_space_ordered = order_actions(state, best_move)
    """
    if is_root
        println("Actions to explore: (action_space_ordered)\n")
    end
    """

    # Iterate through each action in action_space
    for action in action_space_ordered
        """
        if is_root
            println("Action: (action)")
        end
        """
        if stop_signal[]
            return -1, "Timed out"
        end
        # Generate outcome space
        outcome_space = generate_outcome_space[action](state)
        prob_sum = 0
        for (_, prob, _) in outcome_space
            prob_sum += prob
        end
        # Value action
        action_value = action_value_calc(outcome_space, is_root, stop_signal)
        """
        if is_root
            println("ction_value ((prob_sum))\n")
        end
        """
        action_values[action] = action_value
    end

    """
    if is_root
        println("State: (state)")
        println("Action values: action_values")
    end
    """

    # Get optimal action & value
    optimal_action = ""
    optimal_val = -Inf
    for action in action_space_ordered
        if action_values[action] > optimal_val
            optimal_action = action
            optimal_val = action_values[action]
        end
    end

    if optimal_action == "" 
        println("\n\n")
        println(state)
        println(action_space_ordered)
        println(action_values)
        throw(ArgumentError("Optimal action not found for state"))
    end

    # STore in cached
    state_values[state] = (optimal_val, optimal_action)

    return optimal_val, optimal_action
end

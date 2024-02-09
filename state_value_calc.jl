"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
state: State space currently occupied.
"""
function state_value_calc(
    state::State,
    is_root::Bool,
    best_move::String
)
    yield() 
    global state_value_calc_calls
    state_value_calc_calls += 1
    # Base cases
    if state.seconds_remaining <= 0
        return evaluate_game(state)
    end

    # Return if score differential bound is hit
    if IS_FIRST_HALF
        if abs(starting_score_diff - state.score_diff) > SCORE_BOUND
            return state.score_diff, "Score bound hit"
        end
    else
        if state.score_diff > SCORE_BOUND
            return 1
        elseif state.score_diff < -SCORE_BOUND
            return -1
        end
    end

    """
    if !is_root
        interpolated_output = interpolate_state_calc(state, 0)
        if interpolated_output !== nothing
            return interpolated_output
        end
    end
    """

    # Check if state is cached
    if haskey(state_values, state)
        return state_values[state]
    end

    # Initialise arrays to store action space and associated values
    action_values = Dict{String,Float64}()

    action_space_ordered = order_actions(state, best_move)

    optimal_value::Union{Nothing,Float64} = nothing

    # Iterate through each action in action_space
    for action in action_space_ordered
        # Calculate action value
        action_value = action_functions[action](
            state,
            nothing, 
            0
        )
        global state_value_calc_calls
        # Store action value if value returned        
        if action_value !== nothing
            action_values[action] = action_value
            if optimal_value === nothing || optimal_value < action_value
                optimal_value = action_value
            end
        else
            action_values[action] = -2 # Place holder value so that findmax() on dict works. TODO: handle this better
        end
    end

    # Find optimal action
    optimal_action = findmax(action_values)

    # Store all states
    state_values[state] = optimal_action

    return optimal_action
end

function calculate_action_value(
    state::State,
    action::String
)
    outcome_space = generate_outcome_space[action](state) 
    println("Outcome space size: $(outcome_space)")

    action_val = 0
    for (outcome_state, outcome_prob, outcome_change_possession) in outcome_space
        state_value = state_value_calc(outcome_state, false, "")
        println("Value $(state_value) for state $(outcome_state)")
        if outcome_change_possession
            action_val -= outcome_prob * state_value[1]
        else
            action_val += outcome_prob * state_value[1]
        end
    end
    return action_val
end
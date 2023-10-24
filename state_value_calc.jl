"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
state: State space currently occupied.
"""
function state_value_calc(
    state::State
)
    global state_value_calc_calls
    state_value_calc_calls += 1
    if mod(state_value_calc_calls, FUNCTION_CALL_PRINT_INTERVAL) == 0
        println("Function called $(state_value_calc_calls/1000000)M times")
    end
    # Base cases
    if state.seconds_remaining <= 0
        # 1st half: maximise points
        if state.is_first_half
            return state.score_diff, "End 1st half"
        end
        # 2nd half: maximise winning
        if state.score_diff > 0
            return 1, "End Game"
        elseif state.score_diff == 0
            return 0, "End Game"
        else
            return -1, "End Game"
        end
    end

    # Check if state is cached
    if haskey(state_values, state)
        return state_values[state]
    end

    # Initialise arrays to store action space and associated values
    action_values = Dict{String,Float64}()

    # Order the actions TODO: order in a more efficient
    if state.score_diff > 0
        action_space_ordered = action_space
    else
        action_space_ordered = reverse(action_space)
    end

    optimal_value::Union{Nothing,Float64} = nothing

    # Iterate through each action in action_space
    for action in action_space_ordered
        # Calculate action value
        if isempty(action_values)
            action_value = action_functions[action](state, nothing)
        else
            action_value = action_functions[action](state, findmax(action_values))
        end
        # Store action value if value returned        
        if action_value !== nothing
            action_values[action] = action_value
            if optimal_value === nothing || optimal_value < action_value
                optimal_value = action_value
            end
        else
            action_values[action] = -2
        end
    end

    # Find optimal action
    optimal_action = findmax(action_values)

    # Store all states
    state_values[state] = optimal_action

    return (optimal_action[1], optimal_action[2], action_values)
end


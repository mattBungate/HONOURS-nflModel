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

    # Interpolated points in first down dimension only
    if !in(state.first_down_dist, calculated_first_down) && in(state.ball_section, calculated_sections)
        # Get time neighbours
        lower_neigh_first_down, upper_neigh_first_down = first_down_neighbours[state.first_down_dist]
        lower_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            lower_neigh_first_down, # TODO: Look at changing this (to cut down on outcome space)
            state.timeout_called,
            state.clock_ticking,
            state.is_first_half
        )
        upper_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            upper_neigh_first_down, # TODO: Look at changing this (to cut down on outcome space)
            state.timeout_called,
            state.clock_ticking,
            state.is_first_half
        )
        # Retrieve value of lower state
        lower_value = state_value_calc(lower_state)

        # Retrieve value of upper state
        upper_value = state_value_calc(upper_state)

        # Calculate weight of upper/lower state
        lower_weight = (state.first_down_dist - lower_neigh_first_down) / (upper_neigh_first_down - lower_neigh_first_down)
        upper_weight = (upper_neigh_first_down - state.first_down_dist) / (upper_neigh_first_down - lower_neigh_first_down)

        # Return interpolation
        interpolated_val = lower_weight * lower_value[1] + upper_weight * upper_value[1]
        global interpolated_value_calls
        interpolated_value_calls += 1
        #println("($(state.seconds_remaining),$(state.ball_section)) | State Interpolated")
        return interpolated_val, upper_value[2] # TODO: Look at how interpolating with different actions should be handled
    end

    # Interpolated points in ball section dimension only
    if in(state.seconds_remaining, calculated_first_down) && !in(state.first_down_dist, calculated_first_down)
        # Get field position neighbours
        lower_neigh_ball_pos, upper_neigh_ball_pos = ball_pos_neighbours[state.ball_section]
        # Get states of neighbours (with known/calculated state values)
        lower_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            lower_neigh_ball_pos,
            state.down,
            state.first_down_dist, # TODO: Look at changing this (to reduce state space)
            state.timeout_called,
            state.clock_ticking,
            state.is_first_half
        )
        upper_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            upper_neigh_ball_pos,
            state.down,
            state.first_down_dist, # TODO: Look at changing this (to reduce state space)
            state.timeout_called,
            state.clock_ticking,
            state.is_first_half,
        )
        # Check cache for value and retrieve/calculate state values
        if haskey(state_values, lower_state)
            lower_value = state_values[lower_state]
        else
            lower_value = state_value_calc(lower_state)
        end

        if haskey(state_values, upper_state)
            upper_value = state_values[upper_state]
        else
            upper_value = state_value_calc(upper_state)
        end
        # Calculate weightings
        lower_weight = (state.ball_section - lower_neigh_ball_pos) / (upper_neigh_ball_pos - lower_neigh_ball_pos)
        upper_weight = (upper_neigh_ball_pos - state.ball_section) / (upper_neigh_ball_pos - lower_neigh_ball_pos)

        # Interpolate
        interpolated_value = lower_weight * lower_value[1] + upper_weight * upper_value[1]
        global interpolated_value_calls
        interpolated_value_calls += 1
        #println("($(state.seconds_remaining),$(state.ball_section)) | State Interpolated")
        return interpolated_value, lower_value[2] # TODO: Look at how to handle interpolating different actions
    end

    # Interpolate in both dimensions
    if !in(state.first_down_dist, calculated_first_down) && !in(state.ball_section, calculated_sections)
        # Get time and ball position neighbours
        lower_first_down_neigh, upper_first_down_neigh = first_down_neighbours[state.first_down_dist]
        lower_ball_pos_neigh, upper_ball_pos_neigh = ball_pos_neighbours[state.ball_section]

        # Get 4 states for interpolation
        lower_pos_lower_first_down_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            lower_ball_pos_neigh,
            state.down,
            lower_first_down_neigh,
            state.timeout_called,
            state.clock_ticking,
            state.is_first_half
        )
        lower_pos_upper_first_down_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            lower_ball_pos_neigh,
            state.down,
            upper_first_down_neigh,
            state.timeout_called,
            state.clock_ticking,
            state.is_first_half
        )
        upper_pos_lower_first_down_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            upper_ball_pos_neigh,
            state.down,
            upper_ball_pos_neigh + lower_first_down_neigh,
            state.timeout_called,
            state.clock_ticking,
            state.is_first_half
        )
        upper_pos_upper_first_down_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            upper_ball_pos_neigh,
            state.down,
            upper_ball_pos_neigh + upper_first_down_neigh,
            state.timeout_called,
            state.clock_ticking,
            state.is_first_half
        )
        # Get the values
        lower_pos_lower_first_down_value = state_value_calc(lower_pos_lower_first_down_state)
        lower_pos_upper_first_down_value = state_value_calc(lower_pos_upper_first_down_state)
        upper_pos_lower_first_down_value = state_value_calc(upper_pos_lower_first_down_state)
        upper_pos_upper_first_down_value = state_value_calc(upper_pos_upper_first_down_state)

        # Get weights
        upper_pos_weight = (upper_ball_pos_neigh - state.ball_section) / (upper_ball_pos_neigh - lower_ball_poss_neigh)
        lower_pos_weight = 1 - upper_pos_weight

        upper_first_down_weight = (upper_first_down_neigh - state.first_down_dist) / (upper_first_down_neigh - lower_first_down_neigh)
        lower_first_down_weight = 1 - upper_first_down_weight

        interpolated_val = lower_time_weight * lower_pos_weight * lower_pos_lower_first_down_value[1] + \
        upper_first_down_weight * lower_pos_weight * lower_pos_upper_first_down_value[1] + \
        lower_first_down_weight * upper_pos_weight * upper_pos_lower_first_down_value[1] + \
        upper_first_down_weight * upper_pos_weight * upper_pos_upper_first_down_value[1]

        global interpolated_value_calls
        interpolated_value_calls += 1
        #println("($(state.seconds_remaining),$(state.ball_section)) | State Interpolated")
        return interpolated_val, lower_pos_lower_first_down_value[2] # TODO: Look at how to interpolate different actions
    end

    # Check if state is cached
    if haskey(state_values, state)
        #println("($(state.seconds_remaining),$(state.ball_section)) | State cached")
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
        #println("Action: $(action)")
        # Calculate action value
        if isempty(action_values)
            action_value = action_functions[action](
                state,
                nothing
            )
        else
            action_value = action_functions[action](
                state,
                findmax(action_values)
            )
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


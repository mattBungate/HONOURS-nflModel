"""
Function for interpolating values to speed up solve
"""

function interpolate_state_calc(
    state::StateFH
)::Union{Nothing,Tuple{Float64,String}}
    #println("Checking interpolation for $(state)")
    # Interpolated first down 
    if !in(state.first_down_dist, calculated_first_down) && INTERPOLATE_FIRST_DOWN
        #println("First down interpolation")
        # Get time neighbours
        lower_neigh_first_down, upper_neigh_first_down = first_down_neighbours[state.first_down_dist]
        lower_state = StateFH(
            state.seconds_remaining,
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            lower_neigh_first_down,
            state.clock_ticking
        )
        upper_state = StateFH(
            state.seconds_remaining,
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            upper_neigh_first_down,
            state.clock_ticking
        )
        # Retrieve values of states
        lower_value = state_value_calc(lower_state, false, "", Atomic{Bool}(false))
        upper_value = state_value_calc(upper_state, false, "", Atomic{Bool}(false))

        # Calculate weight of upper/lower state
        lower_weight = (state.first_down_dist - lower_neigh_first_down) / (upper_neigh_first_down - lower_neigh_first_down)
        upper_weight = (upper_neigh_first_down - state.first_down_dist) / (upper_neigh_first_down - lower_neigh_first_down)

        # Return interpolation
        interpolated_val = lower_weight * lower_value[1] + upper_weight * upper_value[1]
        global interpolated_value_calls
        interpolated_value_calls += 1
        return interpolated_val, upper_value[2] # TODO: Look at how interpolating with different actions should be handled
    end

    # Interpolated ball section
    if !in(state.ball_section, calculated_sections) && INTERPOLATE_POSITION
        #println("Field position interpolation")
        # Get field position neighbours
        lower_neigh_ball_pos, upper_neigh_ball_pos = ball_pos_neighbours[state.ball_section]
        # Get states of neighbours (with known/calculated state values)
        lower_state = StateFH(
            state.seconds_remaining,
            state.timeouts_remaining,
            lower_neigh_ball_pos,
            state.down,
            state.first_down_dist,
            state.clock_ticking
        )
        upper_state = StateFH(
            state.seconds_remaining,
            state.timeouts_remaining,
            upper_neigh_ball_pos,
            state.down,
            state.first_down_dist,
            state.clock_ticking
        )
        # Retrieve values of states
        lower_value = state_value_calc(lower_state, false, "", Atomic{Bool}(false))
        upper_value = state_value_calc(upper_state, false, "", Atomic{Bool}(false))

        # Calculate weightings
        lower_weight = (state.ball_section - lower_neigh_ball_pos) / (upper_neigh_ball_pos - lower_neigh_ball_pos)
        upper_weight = (upper_neigh_ball_pos - state.ball_section) / (upper_neigh_ball_pos - lower_neigh_ball_pos)

        # Interpolate
        interpolated_value = lower_weight * lower_value[1] + upper_weight * upper_value[1]
        global interpolated_value_calls
        interpolated_value_calls += 1
        return interpolated_value, lower_value[2] # TODO: Look at how to handle interpolating different actions
    end

    # Extrapolate time dimension
    if !in(state.seconds_remaining, seconds_calculated)
        #println("Time interpolation")
        #println("Time neighbours: $(time_neighbours[state.seconds_remaining])")
        #println("Upper time: $(time_neighbours[state.seconds_remaining][2])")
        #println("Lower time: $(time_neighbours[state.seconds_remaining][1])")
        upper_state = StateFH(
            time_neighbours[state.seconds_remaining][2],
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            state.first_down_dist,
            state.clock_ticking
        )
        lower_state = StateFH(
            time_neighbours[state.seconds_remaining][1],
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            state.first_down_dist,
            state.clock_ticking
        )
        upper_value = state_value_calc(upper_state, false, "", Atomic{Bool}(false))
        lower_value = state_value_calc(lower_state, false, "", Atomic{Bool}(false))
        # Interpolate
        interpolated_value = (upper_value[1] + lower_value[1]) / 2
        global interpolated_value_calls
        interpolated_value_calls += 1
        return interpolated_value, lower_value[2]
    end

    return nothing
end
"""
Function for interpolating values to speed up solve
"""

function interpolate_state_calc(
    state::State,
    stop_signal::Atomic{Bool}
)::Union{Nothing,Tuple{Float64,String}}

    # Interpolated first down 
    if !in(state.first_down_dist, calculated_first_down)
        # Get time neighbours
        lower_neigh_first_down, upper_neigh_first_down = first_down_neighbours[state.first_down_dist]
        lower_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            lower_neigh_first_down,
            state.clock_ticking
        )
        upper_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            upper_neigh_first_down,
            state.clock_ticking
        )
        # Retrieve values of states
        lower_value = state_value_calc(lower_state, false, "", stop_signal)
        upper_value = state_value_calc(upper_state, false, "", stop_signal)

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
    if !in(state.ball_section, calculated_sections)
        # Get field position neighbours
        lower_neigh_ball_pos, upper_neigh_ball_pos = ball_pos_neighbours[state.ball_section]
        # Get states of neighbours (with known/calculated state values)
        lower_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            lower_neigh_ball_pos,
            state.down,
            state.first_down_dist,
            state.clock_ticking
        )
        upper_state = State(
            state.seconds_remaining,
            state.score_diff,
            state.timeouts_remaining,
            upper_neigh_ball_pos,
            state.down,
            state.first_down_dist,
            state.clock_ticking
        )
        # Retrieve values of states
        lower_value = state_value_calc(lower_state, false, "", stop_signal)
        upper_value = state_value_calc(upper_state, false, "", stop_signal)

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
        upper_state = State(
            state.seconds_remaining + 1,
            state.score_diff,
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            state.first_down_dist,
            state.clock_ticking
        )
        lower_state = State(
            state.seconds_remaining - 1,
            state.score_diff,
            state.timeouts_remaining,
            state.ball_section,
            state.down,
            state.first_down_dist,
            state.clock_ticking
        )
        upper_value = state_value_calc(upper_state, false, "", stop_signal)
        lower_value = state_value_calc(lower_state, false, "", stop_signal)
        # Interpolate
        interpolated_value =  (upper_value[1] - lower_value[1]) / 2
        global interpolated_value_calls
        interpolated_value_calls += 1
        return interpolated_value, upper_value[2]
    end

    return nothing
end
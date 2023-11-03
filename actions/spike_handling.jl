"""
Handle action Spike
"""
function spike_value_calc(
    current_state::State,
    optimal_value::Union{Tuple{Float64,String},Nothing}, #Union{Nothing,Float64}
)
    if current_state.down == 4 # Will not spike on 4th down
        return nothing
    else
        next_state = State(
            current_state.seconds_remaining - 1,
            current_state.score_diff,
            current_state.timeouts_remaining,
            current_state.ball_section,
            current_state.down + 1,
            current_state.first_down_dist,
            false,
            false,
            current_state.is_first_half
        )
        return state_value_calc(next_state)[1]
    end
end
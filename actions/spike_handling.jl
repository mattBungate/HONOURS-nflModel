"""
Handle action Spike
"""
function spike_value_calc(
    current_state::State,
    optimal_value::Union{Tuple{Float64,String},Nothing} #Union{Nothing,Float64}
)
    if current_state.down == 4
        next_state = State(
            current_state.seconds_remaining - 1,
            -current_state.score_diff,
            reverse(current_state.timeouts_remaining),
            flip_field(current_state.ball_section),
            FIRST_DOWN,
            flip_field(current_state.ball_section) + FIRST_DOWN_TO_GO,
            false,
            false,
            current_state.is_first_half
        )
        return -state_value_calc(next_state)[1]
    else
        next_state = State(
            current_state.seconds_remaining - 1,
            current_state.score_diff,
            current_state.timeouts_remaining,
            current_state.ball_section,
            FIRST_DOWN,
            current_state.ball_section,
            false,
            false,
            current_state.is_first_half
        )
        return state_value_calc(next_state)[1]
    end
end
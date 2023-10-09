"""
Calculate the value of the Kneel action
"""

function kneel_value_calc(
    current_state::State
)::Union{Nothing,Float64}
    if current_state.down == 4
        next_state = State(
            current_state.seconds_remaining - 1, # Assume clock stops during turnonver
            -score_diff,
            reverse(timeouts_remaining),
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
            current_state.seconds_remaining - KNEEL_DURATION,
            current_state.score_diff,
            current_state.timeouts_remaining,
            current_state.ball_section,
            current_state.down + 1,
            current_state.first_down_section,
            false,
            true,
            current_state.is_first_half
        )
        return state_value_calc(next_state)[1]
    end
end

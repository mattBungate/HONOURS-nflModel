"""
Calculates the value of kneeling
"""
function kneel_calc(
    current_state::State,
    optimal_value::Union{Nothing,Float64}
)
    if current_state.down == 4
        next_state = State(
            current_state.plays_remaining - 1,
            current_state.score_diff,
            current_state.timeouts_remaining,
            TOUCHDOWN_SECTION - current_state.ball_section,
            FIRST_DOWN,
            TOUCHDOWN_SECTION - current_state.ball_section + FIRST_DOWN_TO_GO,
            1 - current_state.offense_has_ball,
            current_state.is_first_half
        )
    else
        next_state = State(
            current_state.plays_remaining - 1,
            current_state.score_diff,
            current_state.timeouts_remaining,
            current_state.ball_section,
            current_state.down + 1,
            current_state.first_down_section,
            current_state.offense_has_ball,
            current_state.is_first_half
        )
    end
    return state_value(next_state)[1]
end
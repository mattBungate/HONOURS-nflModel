"""
Calculates the value of kneeling
"""
function kneel_calc(
    current_state:: State
)
    if down == 4
        next_state = State(
            current_state.plays_remaining - 1,
            current_state.score_diff,
            current_state.timeouts_remaining,
            100 - current_state.ball_section,
            FIRST_DOWN,
            100 - current_state.ball_section + 10,
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
"""
Calculate the value of the Kneel action
"""

function kneel_children(
    current_state::State,
)::Vector{State}
    if current_state.down == 4
        return []
    else
        return [
            State(
                max(current_state.seconds_remaining - MAX_PLAY_CLOCK_DURATION, 0),
                current_state.score_diff,
                current_state.timeouts_remaining,
                current_state.ball_section,
                current_state.down + 1,
                current_state.first_down_dist,
                false
            )
        ]
    end
end

function select_kneel_child(
    current_state::State
)::State
    return State(
        max(current_state.seconds_remaining - MAX_PLAY_CLOCK_DURATION, 0),
        current_state.score_diff,
        current_state.timeouts_remaining,
        current_state.ball_section,
        current_state.down + 1,
        current_state.first_down_dist,
        false
    )
end

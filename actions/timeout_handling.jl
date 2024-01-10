"""
Generates child states given a timeout is taken
"""

function delayed_timeout_children(
    current_state::State,
)::Vector{State}
    # Check if delayed timeout can be taken
    if current_state.timeouts_remaining[1] == 0 || !current_state.clock_ticking || current_state.seconds_remaining == 1
        return []
    else
        return [
            State(
                max(current_state.seconds_remaining - MAX_PLAY_CLOCK_DURATION, 1),
                current_state.score_diff,
                (current_state.timeouts_remaining[1] - 1, current_state.timeouts_remaining[2]),
                current_state.ball_section,
                current_state.down,
                current_state.first_down_dist,
                false
            )
        ]
    end
end

function immediate_timeout_children(
    current_state::State,
)::Vector{State}
    # Check if immediate timeout is feasible
    if current_state.timeouts_remaining[1] == 0 || !current_state.clock_ticking
        return []
    else
        return [
            State(
                current_state.seconds_remaining,
                current_state.score_diff,
                (current_state.timeouts_remaining[1] - 1, current_state.timeouts_remaining[2]),
                current_state.ball_section,
                current_state.down,
                current_state.first_down_dist,
                false
            )
        ]
    end
end
"""
Return all children states given spike action is taken
"""
function spike_children(
    current_state::State,
)::Vector{State}
    # Check if spike is feasible
    if current_state.down == 4 || !current_state.clock_ticking
        return []
    else
        # TODO: Better stats for time runoff when playing a spike. Cannot spike instantly
        return [
            State(
                current_state.seconds_remaining,
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

function select_spike_child(
    current_state::State,
)::Union{State, Nothing}
    if current_state.down == 4 || !current_state.clock_ticking
        return nothing
    else
        return State(
            current_state.seconds_remaining,
            current_state.score_diff,
            current_state.timeouts_remaining,
            current_state.ball_section,
            current_state.down + 1,
            current_state.first_down_dist,
            false
        )
    end
end
"""
Handle action Spike
"""
function spike_value_calc(
    current_state::State,
    optimal_value::Union{Nothing,Float64},
    seconds_cutoff::Int
)
    if current_state.down == 4 || !current_state.clock_ticking # Will not spike on 4th down or stopped clock
        return nothing
    else
        next_state = State(
            current_state.seconds_remaining - 1,
            current_state.score_diff,
            current_state.timeouts_remaining,
            current_state.ball_section,
            current_state.down + 1,
            current_state.first_down_dist,
            false
        )
        return state_value_calc(next_state, false, "")[1]
    end
end

function spike_outcome_space(
    state::State
)::Vector{Tuple{State, Float64, Bool}} # State, prob, change possession
    # Invalid action
    
    # Domain knowledge cutoff
    if !state.clock_ticking || state.down == 4
        return []
    end
    # Outcome space
    return [
        (
            State(
                state.seconds_remaining, # TODO: assumes instant spike. Include time to spike
                state.score_diff,
                state.timeouts_remaining,
                state.ball_section,
                state.down + 1,
                state.first_down_dist,
                false
            )
        )
    ]
end
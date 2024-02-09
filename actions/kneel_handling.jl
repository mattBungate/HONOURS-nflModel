"""
Calculate the value of the Kneel action
"""

function kneel_value_calc(
    current_state::State,
    optimal_value::Union{Float64,Nothing},
    seconds_cutoff::Int
)::Union{Nothing,Float64}
    if current_state.down == 4 # Will not kneel on 4th down
        return nothing
    else
        next_state = State(
            max(current_state.seconds_remaining - MAX_PLAY_CLOCK_DURATION, 0),
            current_state.score_diff,
            current_state.timeouts_remaining,
            current_state.ball_section,
            current_state.down + 1,
            current_state.first_down_dist,
            true
        )
        return state_value_calc(next_state, false, "")[1]
    end
end

function kneel_outcome_space(
    state::State
)::Vector{Tuple{State, Float64, Bool}} # State, prob, change possession
    # Invalid action times
    if !state.clock_ticking
        return []
    end
    # Domain knowledge cutoff
    if state.down == 4
        return []
    end
    # State
    return [
        (
            State(
                state.seconds_remaining - MAX_PLAY_CLOCK_DURATION,
                state.score_diff,
                state.timeouts_remaining,
                state.ball_section,
                state.down + 1,
                state.first_down_dist,
                true
            ),
            1,
            false 
        )
    ]
end
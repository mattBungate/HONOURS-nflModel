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
        return state_value_calc_LDFS(next_state, seconds_cutoff, false)[1]
    end
end

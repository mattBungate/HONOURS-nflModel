"""
Calculate the value of the Kneel action
"""

function kneel_value_calc(
    current_state::State,
    optimal_value::Union{Tuple{Float64,String},Nothing}, # Union{Nothing, Float64}
)::Union{Nothing,Float64}
    if current_state.down == 4 # Will not kneel on 4th down
        return nothing
    else
        next_state = State(
            max(current_state.seconds_remaining - KNEEL_DURATION, 0),
            current_state.score_diff,
            current_state.timeouts_remaining,
            current_state.ball_section,
            current_state.down + 1,
            current_state.first_down_dist,
            false,
            true,
            current_state.is_first_half
        )
        return state_value_calc(next_state)[1]
    end
end

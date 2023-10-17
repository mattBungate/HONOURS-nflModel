"""
Calculates the value of calling a timeout
"""

function timeout_value_calc(
    current_state::State,
    delayed::Bool,
    optimal_value::Union{Float64,Nothing}
)::Union{Float64,Nothing}

    if current_state.timeouts_remaining[1] == 0 || !current_state.clock_ticking || current_state.timeout_called
        return nothing
    end

    if delayed
        next_state = State(
            max(current_state.seconds_remaining - 40, 1),
            score_diff,
            (current_state.timeouts_remaining[1] - 1, current_state.timeouts_remaining[2]),
            current_state.ball_section,
            current_state.down,
            current_state.first_down_section,
            true,
            false,
            current_state.is_first_half
        )
        return state_value_calc(next_state)[1]
    else
        next_state = State(
            current_state.seconds_remaining, # Assumes instantly call timeout
            current_state.score_diff,
            (current_state.timeouts_remaining[1] - 1, current_state.timeouts_remaining[2]),
            current_state.ball_section,
            current_state.down,
            current_state.first_down_section,
            true,
            false,
            current_state.is_first_half
        )
        return state_value_calc(next_state)[1]
    end
end
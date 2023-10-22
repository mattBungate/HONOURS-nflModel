"""
Calculates the value of calling a timeout
"""

function delayed_timeout_value_calc(
    current_state::State,
    optimal_value::Union{Tuple{Float64,String},Nothing}
)::Union{Float64,Nothing}
    # Check timeouts remaining and clock ticking
    if current_state.timeouts_remaining[1] == 0 || !current_state.clock_ticking || current_state.timeout_called
        return nothing
    end
    # Check if delayed timeout is an option
    if current_state.seconds_remaining == 1
        return nothing
    end
    next_state = State(
        max(current_state.seconds_remaining - 40, 1),
        current_state.score_diff,
        (current_state.timeouts_remaining[1] - 1, current_state.timeouts_remaining[2]),
        current_state.ball_section,
        current_state.down,
        current_state.first_down_section,
        true,
        false,
        current_state.is_first_half
    )
    delayed_timeout_val = state_value_calc(next_state)[1]
    return delayed_timeout_val
end

function immediate_timeout_value_calc(
    current_state::State,
    optimal_value::Union{Tuple{Float64,String},Nothing}
)::Union{Float64,Nothing}
    # Check if timeouts remaining & clock ticking
    if current_state.timeouts_remaining[1] == 0 || !current_state.clock_ticking || current_state.timeout_called
        return nothing
    end
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
    timeout_val = state_value_calc(next_state)[1]
    return timeout_val
end
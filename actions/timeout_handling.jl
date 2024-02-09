"""
Calculates the value of calling a timeout
"""

function delayed_timeout_value_calc(
    current_state::State,
    optimal_value::Union{Float64,Nothing},
    seconds_cutoff::Int
)::Union{Float64,Nothing}
    # Check timeouts remaining and clock ticking
    if current_state.timeouts_remaining[1] == 0 || !current_state.clock_ticking
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
        current_state.first_down_dist,
        false
    )
    delayed_timeout_val = state_value_calc(next_state, false, "")[1]
    return delayed_timeout_val
end

function immediate_timeout_value_calc(
    current_state::State,
    optimal_value::Union{Float64,Nothing},
    seconds_cutoff::Int
)::Union{Float64,Nothing}
    # Check if timeouts remaining & clock ticking
    if current_state.timeouts_remaining[1] == 0 || !current_state.clock_ticking
        return nothing
    end
    next_state = State(
        current_state.seconds_remaining, # Assumes instantly call timeout
        current_state.score_diff,
        (current_state.timeouts_remaining[1] - 1, current_state.timeouts_remaining[2]),
        current_state.ball_section,
        current_state.down,
        current_state.first_down_dist,
        false
    )
    timeout_val = state_value_calc(next_state, false, "")[1]
    return timeout_val
end

function delayed_timeout_outcome_space(
    state::State
)::Vector{Tuple{State, Float64, Bool}} # State, prob, change possession
    # Invalid action
    if state.timeouts_remaining[1] == 0 || !state.clock_ticking || state.seconds_remaining == 1
        return []
    end
    # Domain knowledge cutoff

    # Outcome state(s)
    return [
        (
            State(
                max(1, state.seconds_remaining - MAX_PLAY_CLOCK_DURATION),
                state.score_diff,
                (state.timeouts_remaining[1] - 1, state.timeouts_remaining[2]),
                state.ball_section,
                state.down,
                state.first_down_dist,
                false
            ),
            1,
            false
        )
    ]
end

function immediate_timeout_outcome_space(
    state::State
)::Vector{Tuple{State, Float64, Bool}} # State, prob, change possession
    # Invalid action
    if state.timeouts_remaining[1] == 0 || !state.clock_ticking
        return []
    end
    # Domain knowledge cutoff

    # Outcome state(s) w/ info
    return [
        (
            State(
                state.seconds_remaining,
                state.score_diff,
                (state.timeouts_remaining[1] - 1, state.timeouts_remaining[2]),
                state.ball_section,
                state.down,
                state.first_down_dist,
                false
            ),
            1,
            false
        )
    ]
end
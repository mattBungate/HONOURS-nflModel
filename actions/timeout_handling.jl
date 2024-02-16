
function delayed_timeout_outcome_space(
    state::StateFH
)::Vector{Tuple{StateFH, Float64, Int, Bool}} # State, prob, reward, change possession
    # Invalid action
    if state.timeouts_remaining[1] == 0 || !state.clock_ticking || state.seconds_remaining == 1
        return []
    end
    # Domain knowledge cutoff

    # Outcome state(s)
    return [
        (
            StateFH(
                max(1, state.seconds_remaining - MAX_PLAY_CLOCK_DURATION),
                (state.timeouts_remaining[1] - 1, state.timeouts_remaining[2]),
                state.ball_section,
                state.down,
                state.first_down_dist,
                false
            ),
            1,
            0,
            false
        )
    ]
end

function immediate_timeout_outcome_space(
    state::StateFH
)::Vector{Tuple{StateFH, Float64, Int, Bool}} # State, prob, reward, change possession
    # Invalid action
    if state.timeouts_remaining[1] == 0 || !state.clock_ticking
        return []
    end
    # Domain knowledge cutoff

    # Outcome state(s) w/ info
    return [
        (
            StateFH(
                state.seconds_remaining,
                (state.timeouts_remaining[1] - 1, state.timeouts_remaining[2]),
                state.ball_section,
                state.down,
                state.first_down_dist,
                false
            ),
            1,
            0,
            false
        )
    ]
end
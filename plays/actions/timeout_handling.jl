"""
Calculates the value of calling a timeout
"""

function delayed_timeout_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}} # State, prob, change possession
    # Invalid action
    if state.timeouts_remaining[1] == 0 || !state.clock_ticking || state.seconds_remaining == 1
        return []
    end
    # Domain knowledge cutoff

    # Outcome state(s)
    return Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}}(
        [
            (
                PlayState(
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
    )
end

function immediate_timeout_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}} # State, prob, change possession
    # Invalid action
    if state.timeouts_remaining[1] == 0 || !state.clock_ticking
        return []
    end
    # Domain knowledge cutoff

    # Outcome state(s) w/ info
    return Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}}(
        [
            (
                PlayState(
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
    )
end
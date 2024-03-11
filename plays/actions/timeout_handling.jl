
function delayed_timeout_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{PlayState,KickoffState,ConversionState}, Float64, Int, Bool}} # State, prob, reward, change possession
    # Invalid action
    if state.timeouts_remaining[1] == 0 || !state.clock_ticking || state.seconds_remaining == 1
        return []
    end
    # Domain knowledge cutoff

    # Outcome state(s)
    return Vector{Tuple{Union{PlayState,KickoffState,ConversionState}, Float64, Int, Bool}}(
        [
            (
                PlayState(
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
    )
end

function immediate_timeout_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{ConversionState,KickoffState,PlayState}, Float64, Int, Bool}} # State, prob, reward, change possession
    # Invalid action
    if state.timeouts_remaining[1] == 0 || !state.clock_ticking
        return Vector{Tuple{Union{ConversionState,KickoffState,PlayState}, Float64, Int, Bool}}()
    end
    # Domain knowledge cutoff

    # Outcome state(s) w/ info
    return Vector{Tuple{Union{ConversionState,KickoffState,PlayState}, Float64, Int, Bool}}(
        [
            (
                PlayState(
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
    )
end
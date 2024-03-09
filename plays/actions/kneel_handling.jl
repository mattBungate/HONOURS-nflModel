"""
Generate the outcome states and probabilities for kneeling
"""
function kneel_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}} # State, prob, change possession
    # Invalid action times

    # Domain knowledge cutoff
    if state.down == 4
        return []
    end

    clock_runoff = 0
    if state.clock_ticking
        clock_runoff = MAX_PLAY_CLOCK_DURATION
    end
    # State
    return Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}}(
        [
            (
                PlayState(
                    state.seconds_remaining - clock_runoff,
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
    )
end
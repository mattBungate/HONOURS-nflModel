"""
Handle action Spike
"""

function spike_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}} # State, prob, change possession
    # Invalid action
    
    # Domain knowledge cutoff
    if !state.clock_ticking || state.down == 4
        return []
    end
    # Outcome space
    return Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}}(
        [
            (
                PlayState(
                    state.seconds_remaining, # TODO: assumes instant spike. Include time to spike
                    state.score_diff,
                    state.timeouts_remaining,
                    state.ball_section,
                    state.down + 1,
                    state.first_down_dist,
                    false
                ),
                1,
                false
            )
        ]
    )
end
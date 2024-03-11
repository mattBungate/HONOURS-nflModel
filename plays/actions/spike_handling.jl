
function spike_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{ConversionState,KickoffState,PlayState}, Float64, Int, Bool}} # State, prob, reward, change possession
    # Invalid action
    
    # Domain knowledge cutoff
    if !state.clock_ticking || state.down == 4
        return []
    end
    # Outcome space
    return Vector{Tuple{Union{ConversionState,KickoffState,PlayState}, Float64, Int, Bool}}(
        [
            (
                PlayState(
                    state.seconds_remaining, # TODO: assumes instant spike. Include time to spike
                    state.timeouts_remaining,
                    state.ball_section,
                    state.down + 1,
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
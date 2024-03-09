

function forced_toucback_outcome_space(
    state::KickoffState
)::Vector{Tuple{Union{PlayState,ConversionState}, Float64}} # State, prob, change possession
    return Vector{Tuple{Union{PlayState, ConversionState}, Float64}}(
        [
            (
                PlayState(
                    state.seconds_remaining,
                    state.score_diff,
                    state.timeouts_remaining,
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    false
                ),
                1.0
            )
        ]
    )
end
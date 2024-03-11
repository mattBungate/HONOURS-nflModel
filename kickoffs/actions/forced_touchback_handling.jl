
function forced_touchback_outcome_space(
    state::KickoffState
)::Vector{Tuple{Union{PlayState, ConversionState}, Float64, Int, Bool}} # State, prob, reward
    return Vector{Tuple{Union{PlayState, ConversionState}, Float64, Int, Bool}}(
        [
            (
                PlayState(
                    state.seconds_remaining,
                    state.timeouts_remaining,
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    false
                ),
                1.0,
                1,
                true
            )
        ]
    )
end


function two_point_outcome_space(
    state::ConversionState
)::Vector{Tuple{KickoffState, Float64, Int}} # State, prob
    outcome_space = Vector{Tuple{KickoffState, Float64, Int}}()
    # Made the conversion 
    push!(
        outcome_space,
        (
            KickoffState(
                state.seconds_remaining,
                state.timeouts_remaining
            ),
            TWO_POINT_MADE_PROB,
            TWO_POINT_VALUE
        )
    )
    # No score
    push!(
        outcome_space,
        (
            KickoffState(
                state.seconds_remaining,
                state.timeouts_remaining
            ),
            TWO_POINT_NO_SCORE,
            NO_SCORE
        )
    )
    # Other team returns
    push!(
        outcome_space,
        (
            KickoffState(
                state.seconds_remaining,
                state.timeouts_remaining
            ),
            TWO_POINT_NO_SCORE,
            RETURNED_CONVERSION_VALUE
        )
    )

    return outcome_space
end
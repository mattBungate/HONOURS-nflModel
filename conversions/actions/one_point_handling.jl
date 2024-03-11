

function one_point_outcome_space(
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
            EXTRA_POINT_MADE_PROB,
            EXTRA_POINT_VALUE
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
            EXTRA_POINT_NO_SCORE_PROB,
            0
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
            EXTRA_POINT_RETURNED_PROB,
            RETURNED_CONVERSION_VALUE
        )
    )

    return outcome_space
end
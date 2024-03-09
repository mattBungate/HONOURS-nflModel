

function one_point_outcome_space(
    state::ConversionState
)::Vector{Tuple{KickoffState, Float64}} # State, prob
    outcome_space = Vector{Tuple{KickoffState, Float64}}()
    # Made the conversion 
    push!(
        outcome_space,
        (
            KickoffState(
                state.seconds_remaining,
                state.score_diff + 1,
                state.timeouts_remaining
            ),
            EXTRA_POINT_MADE_PROB
        )
    )
    # No score
    push!(
        outcome_space,
        (
            KickoffState(
                state.seconds_remaining,
                state.score_diff,
                state.timeouts_remaining
            ),
            EXTRA_POINT_NO_SCORE_PROB
        )
    )
    # Other team returns
    push!(
        outcome_space,
        (
            KickoffState(
                state.seconds_remaining,
                state.score_diff - 2,
                state.timeouts_remaining
            ),
            EXTRA_POINT_RETURNED_PROB
        )
    )

    return outcome_space
end
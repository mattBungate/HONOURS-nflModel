

function returnable_kick_outcome_space(
    state::KickoffState
)::Vector{Tuple{Union{PlayState,ConversionState}, Float64}} # State, prob, change possession
    outcome_space = Vector{Tuple{Union{PlayState, ConversionState}, Float64}}()
    # Fair catch state
    for (fair_catch_pos, pos_prob) in FAIR_CATCH_POS
        push!(
            outcome_space,
            (
                PlayState(
                    state.seconds_remaining,
                    -state.score_diff,
                    reverse(state.timeouts_remaining),
                    fair_catch_pos,
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    false
                ),
                pos_prob * FAIR_CATCH_PROB
            )
        )
    end
    for (return_duration, time_prob) in RETURN_DURATIONS
        # Return for TD
        push!(
            outcome_space,
            (
                ConversionState(
                    state.seconds_remaining - return_duration,
                    -state.score_diff + TOUCHDOWN_SCORE,
                    reverse(state.timeouts_remaining)   
                ),
                time_prob * KICKOFF_RETURN_TOUCHDOWN_PROB
            )
        )
        for (return_pos, pos_prob) in RETURN_FIELD_POSITIONS
            # Return w clock Stopped
            push!(
                outcome_space,
                (
                    PlayState(
                        state.seconds_remaining - return_duration,
                        -state.score_diff,
                        reverse(state.timeouts_remaining),
                        return_pos,
                        FIRST_DOWN,
                        FIRST_DOWN_TO_GO,
                        false
                    ),
                    time_prob * pos_prob * (1 - FAIR_CATCH_PROB) * RETURN_CLOCK_TICKING * (1 - KICKOFF_RETURN_TOUCHDOWN_PROB),
                )
            )
            # Return w clock ticking 
            push!(
                outcome_space,
                (
                    PlayState(
                        state.seconds_remaining,
                        -state.score_diff,
                        reverse(state.timeouts_remaining),
                        return_pos,
                        FIRST_DOWN,
                        FIRST_DOWN_TO_GO,
                        true
                    ),
                    time_prob * pos_prob * (1 - FAIR_CATCH_PROB) * (1 - RETURN_CLOCK_TICKING) * (1 - KICKOFF_RETURN_TOUCHDOWN_PROB),
                )
            )
        end
    end

    return outcome_space
end
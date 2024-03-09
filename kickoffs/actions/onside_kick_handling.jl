

function onside_kick_outcome_space(
    state::KickoffState
)::Vector{Tuple{Union{PlayState, ConversionState}, Float64}} # State, prob, change possession # TODO - include outcomes of scoring
    outcome_space = Vector{Tuple{Union{PlayState, ConversionState}, Float64}}()  
    for (onside_duration, time_prob) in ONSIDE_TIME_TAKEN
        for (field_pos, field_pos_prob) in ONSIDE_RECOVERED_FIELD_CHANCE
            # Ball recovered 
            push!(
                outcome_space,
                (
                    PlayState(
                        state.seconds_remaining - onside_duration,
                        state.score_diff,
                        state.timeouts_remaining,
                        field_pos,
                        FIRST_DOWN,
                        FIRST_DOWN_TO_GO,
                        false
                    ),
                    ONSIDE_RECOVERY_CHANCE * time_prob * field_pos_prob
                )
            )
            # Ball not recovered
            push!(
                outcome_space,
                (
                    PlayState(
                        state.seconds_remaining - onside_duration,
                        state.score_diff,
                        reverse(state.timeouts_remaining),
                        flip_field(field_pos),
                        FIRST_DOWN,
                        FIRST_DOWN_TO_GO,
                        false
                    ),
                    (1 - ONSIDE_RECOVERY_CHANCE) * time_prob * field_pos_prob
                )
            )
        end
    end

    return outcome_space
end
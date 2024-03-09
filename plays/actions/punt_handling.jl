

function punt_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}}
    """ Invalid action """
    # Action infeasible
    
    # Domain knowledge cutoff
    # Only punt on 4th down and if out of field goal range
    if state.down != 4 || state.ball_section < FIELD_GOAL_CUTOFF
        return []
    end

    """ Outcome Space """
    outcome_space = Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}}()
    punt_probs = filter(row ->
            (row[:"Punt Section"] == state.ball_section),
        punt_df
    )
    # Returned for TD
    return_td_end_of_game_prob = 1
    punt_return_td_prob = punt_probs[1, Symbol("Def Endzone")]
    for punt_duration in MIN_PUNT_DURATION:MAX_PUNT_DURATION
        play_length = punt_duration

        if play_length >= state.seconds_remaining
            return_td_time_prob = return_td_end_of_game_prob
        else
            return_td_time_prob = PUNT_TIME_PROBS[punt_duration]
            return_td_end_of_game_prob -= return_td_time_prob
        end

        state_prob = punt_return_td_prob * return_td_time_prob

        push!(
            outcome_space,
            (
                ConversionState(
                    state.seconds_remaining - play_length,
                    -state.score_diff + TOUCHDOWN_SCORE,
                    reverse(state.timeouts_remaining),
                ),
                state_prob,
                false
            )
        )

        if punt_duration >= state.seconds_remaining
            break 
        end
    end
    # Non-scoring return
    for field_position in NON_SCORING_FIELD_SECTIONS
        end_of_game_prob = 1
        pos_prob = punt_probs[1, Symbol("T-$(field_position)")]
        if pos_prob == 1
            continue # TODO: Founda n error (9 yard has a prob of 1?)
        end

        for punt_duration in MIN_PUNT_DURATION:MAX_PUNT_DURATION 
            play_length = punt_duration
            
            if play_length >= state.seconds_remaining
                time_prob = end_of_game_prob
            else
                time_prob = PUNT_TIME_PROBS[punt_duration]
                end_of_game_prob -= time_prob
            end

            state_prob = pos_prob * time_prob

            push!(
                outcome_space,
                (
                    PlayState(
                        state.seconds_remaining - play_length,
                        -state.score_diff,
                        reverse(state.timeouts_remaining),
                        flip_field(field_position),
                        FIRST_DOWN,
                        FIRST_DOWN_TO_GO,
                        false
                    ),
                    state_prob,
                    true
                )
            )
            if play_length >= state.seconds_remaining
                break 
            end
        end
    end
    return outcome_space
end
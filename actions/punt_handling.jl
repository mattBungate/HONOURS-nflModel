"""
Calculates the expected value of punting

Parameters:
- State space

Very simple implementation. Doesn't account for any state factors.
Finds transition probs by creating a normal distrubtion fitted to all punts. 
"""
function punt_value_calc(
    current_state::State
)
    punt_val = 0
    # Get Punt probabilities
    probabilities = filter(row ->
            (row[:"Punt Section"] == current_state.ball_section),
        punt_df
    )

    for end_section in FIELD_SECTIONS
        # Skip scoring of punt
        if end_section == TOUCHDOWN_SECTION
            continue
            time_probs = filter(row ->
                    (row[:"Yards Gained"] == end_section - current_state.ball_section),
                time_punt_df
            )
            # Handle return TD
            if end_section == TOUCHDOWN_CONCEEDED_SECTION
                end_section_prob = probabilities[1, Symbol("Def Endzone")]
                if end_section_prob > PROB_TOL
                    for seconds in MIN_PUNT_DURATION:MAX_PUNT_DURATION
                        # Get time prob
                        time_prob = time_probs[1, Symbol("$(seconds) secs")]
                        if time_prob > TIME_PROB_TOL || seconds == current_state.seconds_remaining
                            next_state = State(
                                current_state.seconds_remaining - seconds, # Change to seconds. Need data
                                current_state.score_diff - TOUCHDOWN_SCORE,
                                current_state.timeouts_remaining, # Figure out timeout handling
                                TOUCHBACK_SECTION,
                                FIRST_DOWN,
                                TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
                                false,
                                false, # Clock ticking handling. Need data
                                current_state.is_first_half
                            )
                            punt_time_value = state_value_calc(next_state)[1]
                            punt_val += end_section_prob * time_prob * punt_time_value
                        end
                    end
                end
                # Handle all other return
            else
                # Get the probability
                col_name = Symbol("T-$(end_section)")
                end_section_prob = probabilities[1, col_name]

                if end_section_prob > PROB_TOL
                    for seconds in MIN_PUNT_DURATION:MAX_PUNT_DURATION
                        # Get time prob
                        time_prob = time_probs[1, Symbol("$(seconds) secs")]
                        if time_prob > TIME_PROB_TOL || seconds == current_state.seconds_remaining
                            next_state = State(
                                current_state.seconds_remaining - seconds, # Change to seconds. Need data
                                -current_state.score_diff,
                                current_state.timeouts_remaining, # Timeout handling
                                end_section,
                                FIRST_DOWN,
                                end_section + FIRST_DOWN_TO_GO,
                                false,
                                false, # Clock ticking handling. Need data
                                current_state.is_first_half
                            )
                            punt_time_val = -state_value_calc(next_state)[1]
                            punt_val += end_section_prob * time_prob * punt_time_val
                        end
                    end
                end
            end
        end
    end

    return punt_val
end
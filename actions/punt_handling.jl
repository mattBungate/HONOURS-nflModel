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
            # Handle return TD
        elseif end_section == TOUCHDOWN_CONCEEDED_SECTION
            end_section_prob = probabilities[1, :"Def Endzone"]
            if end_section_prob > PROB_TOL
                next_state = State(
                    current_state.plays_remaining - 1, # Change to seconds. Need data
                    current_state.score_diff - TOUCHDOWN_SCORE,
                    current_state.timeouts_remaining, # Figure out timeout handling
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
                    false,
                    false, # Clock ticking handling. Need data
                    current_state.is_first_half
                )
                punt_val += end_section_prob * state_value_calc(
                    next_state
                )[1]
            end
            # Handle all other return
        else
            # Get the probability
            col_name = Symbol("T-$(end_section)")
            end_section_prob = probabilities[1, col_name]

            if end_section_prob > PROB_TOL
                next_state = State(
                    current_state.plays_remaining - 1, # Change to seconds. Need data
                    -current_state.score_diff,
                    current_state.timeouts_remaining, # Timeout handling
                    end_section,
                    FIRST_DOWN,
                    end_section + FIRST_DOWN_TO_GO,
                    false,
                    false, # Clock ticking handling. Need data
                    current_state.is_first_half
                )
                punt_val += end_section_prob * -state_value_calc(
                    next_state
                )[1]
            end
        end
    end
    return punt_val
end
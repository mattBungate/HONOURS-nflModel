"""
Calculates the expected value of punting

Parameters:
- State space

Very simple implementation. Doesn't account for any state factors.
Finds transition probs by creating a normal distrubtion fitted to all punts. 
"""
function punt_value(
    current_state::State,
    optimal_value::Union{Nothing,Float64}
)
    punt_val = 0
    prob_remaining = 1

    probabilities = filter(row ->
            (row[:"Punt Section"] == current_state.down),
        punt_df
    )

    for end_section in FIELD_SECTIONS
        if (!Bool(current_state.is_first_half) &&
            optimal_value !== nothing &&
            punt_val + prob_remaining < optimal_value)

            return nothing
        end

        if end_section == TOUCHDOWN_SECTION
            continue
        end

        col_name = Symbol("T-$end_section")
        end_section_prob = probabilities[1, col_name]

        prob_remaining -= end_section_prob

        if end_section_prob > PROB_TOL
            if end_section == TOUCHDOWN_CONCEEDED_SECTION
                # If other team scores off punt return
                next_state = State(
                    current_state.plays_remaining - 1,
                    Bool(current_state.offense_has_ball) ? current_state.score_diff - TOUCHDOWN_SCORE : current_state.score_diff + TOUCHDOWN_SCORE,
                    current_state.timeouts_remaining,
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
                    current_state.offense_has_ball,
                    current_state.is_first_half
                )
                punt_val += end_section_prob * state_value(
                    next_state
                )[1]
            else
                next_state = State(
                    current_state.plays_remaining - 1,
                    current_state.score_diff,
                    current_state.timeouts_remaining,
                    end_section,
                    FIRST_DOWN,
                    end_section + FIRST_DOWN_TO_GO,
                    1 - current_state.offense_has_ball,
                    current_state.is_first_half
                )
                punt_val += end_section_prob * state_value(
                    next_state
                )[1]
            end
        end
    end
    return punt_val
end
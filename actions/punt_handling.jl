"""
Calculates the expected value of punting

Parameters:
- State space

Very simple implementation. Doesn't account for any state factors.
Finds transition probs by creating a normal distrubtion fitted to all punts. 
"""
function punt_value(
    current_state:: State
)
    punt_val = 0

    section_probs = []
    for end_section in FIELD_SECTIONS
        if end_section == 0
            push!(section_probs, cdf(punt_dist, -current_state.ball_section*SECTION_WIDTH + SECTION_WIDTH/2))
        elseif end_section == 11
            section_probs[(11-TOUCHBACK_SECTION)+1] += 1 - cdf(punt_dist, SECTION_WIDTH*(11-current_state.ball_section)-SECTION_WIDTH/2) # If punt goes into end zone its an auto touchback
        else
            push!(section_probs, 
                cdf(punt_dist, SECTION_WIDTH*(end_section-current_state.ball_section) + SECTION_WIDTH/2) \
                - cdf(punt_dist, SECTION_WIDTH*(end_section-current_state.ball_section) - SECTION_WIDTH/2)
            )
        end
    end

    for end_section in FIELD_SECTIONS
        if end_section == TOUCHDOWN_SECTION
            continue
        end
        if section_probs[end_section + 1] > PROB_TOL
            if end_section == TOUCHDOWN_CONCEEDED_SECTION
                # If other team scores off punt return
                next_state = State(
                    current_state.plays_remaining - 1,
                    Bool(current_state.offense_has_ball) ? current_state.score_diff - TOUCHDOWN_SCORE : current_state.score_diff + TOUCHDOWN_SCORE,
                    current_state.timeouts_remaining,
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    current_state.offense_has_ball,
                    current_state.is_first_half
                )
                punt_val += section_probs[1] * state_value(
                    next_state
                )[1]
            else
                next_state = State(
                    current_state.plays_remaining - 1,
                    current_state.score_diff,
                    current_state.timeouts_remaining,
                    end_section,
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    1 - current_state.offense_has_ball,
                    current_state.is_first_half
                )
                punt_val += section_probs[end_section + 1] * state_value(
                    next_state
                )[1]
            end
        end
    end
    return punt_val
end
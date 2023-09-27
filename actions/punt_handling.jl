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
    for end_section in field_sections
        if end_section == 0
            push!(section_probs, cdf(punt_dist, -current_state.ball_section*10 + 5))
        elseif end_section == 11
            section_probs[8+1] += 1 - cdf(punt_dist, 10*(11-current_state.ball_section)-5) # If punt goes into end zone its an auto touchback
        else
            push!(section_probs, 
                cdf(punt_dist, 10*(end_section-current_state.ball_section) + 5) \
                - cdf(punt_dist, 10*(end_section-current_state.ball_section)-5)
            )
        end
    end

    for end_section in 0:10
        if section_probs[end_section + 1] > PROB_TOL
            if end_section == 0 
                # If other team scores off punt return
                next_state = State(
                    current_state.plays_remaining - 1,
                    Bool(current_state.offense_has_ball) ? current_state.score_diff - 7 : current_state.score_diff + 7,
                    current_state.timeouts_remaining,
                    3,
                    1,
                    10,
                    current_state.offense_has_ball,
                    current_state.is_first_half
                )
                punt_val += section_probs[1] * run_play(
                    next_state
                )[1]
            else
                next_state = State(
                    current_state.plays_remaining - 1,
                    current_state.score_diff,
                    current_state.timeouts_remaining,
                    end_section,
                    1,
                    10,
                    1 - current_state.offense_has_ball,
                    current_state.is_first_half
                )
                punt_val += section_probs[end_section + 1] * run_play(
                    next_state
                )[1]
            end
        end
    end
    return punt_val
end
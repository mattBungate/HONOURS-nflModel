"""
Calculates the expected value of punting

Parameters:
- State space

Very simple implementation. Doesn't account for any state factors.
Finds transition probs by creating a normal distrubtion fitted to all punts. 
"""
function punt_value(
    time_remaining::Int,
    score_diff::Int,
    timeouts_remaining::Int,
    ball_position::Int,
    down::Int,
    first_down_position::Int,
    offense_has_ball::Bool,
    is_first_half::Bool
)
    punt_val = 0

    ball_section = Int(ceil(ball_position/10))

    section_probs = []
    for end_section in field_sections
        if end_section == 0
            push!(section_probs, cdf(punt_dist, -ball_section*10 + 5))
        elseif end_section == 11
            section_probs[8+1] += 1 - cdf(punt_dist, 10*(11-ball_section)-5) # If punt goes into end zone its an auto touchback
        else
            push!(section_probs, cdf(punt_dist, 10*(end_section-ball_section) + 5) - cdf(punt_dist, 10*(end_section-ball_section)-5))
        end
    end

    for end_section in 0:10
        if section_probs[end_section + 1] > PROB_TOL
            if end_section == 0 # If other team scores off punt return
                punt_val += section_probs[1] * run_play(
                    Int(time_remaining - 1),
                    offense_has_ball ? Int(score_diff - 7) : Int(score_diff + 7),
                    timeouts_remaining,
                    25, # Assumes touchback from kickoff
                    1,
                    10,
                    offense_has_ball,
                    is_first_half
                )[1]
            else
                punt_val += section_probs[end_section + 1] * run_play(
                    Int(time_remaining - 1),
                    score_diff,
                    timeouts_remaining,
                    end_section,
                    1,
                    10,
                    !offense_has_ball,
                    is_first_half
                )[1]
            end
        end
    end
    return punt_val
end
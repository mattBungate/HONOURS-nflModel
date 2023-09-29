"""
Calculates the expected value after the play is executed

Parameters:
State values: Used for transitioning to next State
probabilities: Probability of transition (dependent on the play type)

The type of play will be handled before this function is called.
Type of play only impacts probabilities. Everything else can be calculated/infered
"""
function play_value(
    current_state:: State,
    probabilities:: DataFrame,
    timeout_called:: Bool
)
    play_value = 0

    # States between ball and first down
    for section in current_state.ball_section:current_state.first_down_section
        if section > 99 
            continue
        end
        col_name = Symbol("T-$section")
        transition_prob = probabilities[1, col_name]
        if current_state.down < 4
            if section >= current_state.first_down_section
                next_first_down = section + FIRST_DOWN_TO_GO
                next_down = FIRST_DOWN
            else
                next_first_down = current_state.first_down_section
                next_down = current_state.down + 1
            end
            next_state = State(
                current_state.plays_remaining - 1,
                current_state.score_diff,
                timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
                section,
                next_down,
                next_first_down,
                current_state.offense_has_ball,
                current_state.is_first_half
            )
        else
            # 4th down handling
            if section >= current_state.first_down_section
                # Made it
                next_state = State(
                    current_state.plays_remaining - 1,
                    current_state.score_diff,
                    timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
                    section,
                    FIRST_DOWN,
                    section + FIRST_DOWN_TO_GO,
                    current_state.offense_has_ball,
                    current_state.is_first_half
                )
            else
                # Short of 1st down
                next_state = State(
                    current_state.plays_remaining - 1,
                    current_state.score_diff,
                    timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
                    100 - section,
                    FIRST_DOWN,
                    100 - section + FIRST_DOWN_TO_GO,
                    1 - current_state.offense_has_ball,
                    current_state.is_first_half
                )
            end
        end
        play_value += transition_prob * state_value(
            next_state
        )[1]
    end
    
    # Group and calculate sections past first down, starting at end zone
    #grouped_sections = 0
    if current_state.first_down_section < TOUCHDOWN_SECTION
        group_far_section = TOUCHDOWN_SECTION - 1
        group_prob = 0

        for section in TOUCHDOWN_SECTION-1:-1:current_state.first_down_section + 1
            col_name = Symbol("T-$section")
            section_prob = probabilities[1, col_name]
            group_prob += section_prob
            if group_prob > GROUP_PROB_TOL
                new_ball_section = Int(ceil((group_far_section + section)/2))
                # Calculate group
                next_state = State(
                    current_state.plays_remaining - 1,
                    current_state.score_diff,
                    timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
                    new_ball_section,
                    FIRST_DOWN,
                    new_ball_section + FIRST_DOWN_TO_GO,
                    current_state.offense_has_ball,
                    current_state.is_first_half
                )
                play_value = state_value(
                    next_state
                )[1]
                group_far_section = section - 1
                group_prob = 0
                #grouped_sections += 1
            end
        end
        # Do the final group that might not have been done 
        if group_prob > 0
            new_ball_section = Int(ceil((group_far_section + current_state.first_down_section + 1)/2))
            next_state = State(
                current_state.plays_remaining - 1,
                current_state.score_diff,
                timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
                new_ball_section,
                FIRST_DOWN,
                new_ball_section + FIRST_DOWN_TO_GO,
                current_state.offense_has_ball,
                current_state.is_first_half
            )
            play_value = state_value(
                next_state
            )[1]
            #grouped_sections += 1
        end
    end
    #sections_available = 100 - current_state.first_down_section
    #println("play_value() # grouped sections past first down ($grouped_sections/$sections_available)")
    # Grouping & calculation of sections behind ball
    
    group_far_section = TOUCHDOWN_CONCEEDED_SECTION + 1
    group_prob = 0
    for section in TOUCHDOWN_CONCEEDED_SECTION+1:current_state.ball_section - 1
        col_name = Symbol("T-$section")
        section_prob = probabilities[1, col_name]
        group_prob += section_prob
        if group_prob > GROUP_PROB_TOL
            new_ball_section = Int(ceil((group_far_section + section)/2))
            # Calculate group
            next_state = State(
                current_state.plays_remaining - 1,
                current_state.score_diff,
                timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
                current_state.down == 4 ? 100 - new_ball_section : new_ball_section,
                current_state.down == 4 ? FIRST_DOWN : current_state.down + 1,
                current_state.down == 4 ? 100 - new_ball_section - FIRST_DOWN_TO_GO : new_ball_section + FIRST_DOWN_TO_GO,
                current_state.offense_has_ball,
                current_state.is_first_half
            )
            play_value = state_value(
                next_state
            )[1]
            group_far_section = section - 1
            group_prob = 0
        end
    end

    # Pick six scenario
    pick_six_prob = probabilities[1,:"Def Endzone"]
    if pick_six_prob > PROB_TOL
        next_state = State(
            current_state.plays_remaining - 1,
            Bool(current_state.offense_has_ball) ? current_state.score_diff - TOUCHDOWN_SCORE : current_state.score_diff + TOUCHDOWN_SCORE,
            timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
            current_state.offense_has_ball,
            current_state.is_first_half
        )
        play_value += pick_six_prob * state_value(
            next_state
        )[1]
    end
    # Touchdown scenario
    td_prob = probabilities[1,"Off Endzone"]
    if td_prob > PROB_TOL
        next_state = State(
            current_state.plays_remaining - 1,
            Bool(current_state.offense_has_ball) ? current_state.score_diff + TOUCHDOWN_SCORE : current_state.score_diff - TOUCHDOWN_SCORE,
            timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
            1 - current_state.offense_has_ball,
            current_state.is_first_half
        )
        play_value += td_prob * state_value(
            next_state
        )[1]
    end
    return play_value
end
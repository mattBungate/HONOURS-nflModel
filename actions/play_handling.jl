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

    for section in NON_SCORING_FIELD_SECTIONS
        col_name = Symbol("T-$section")
        transition_prob = probabilities[1, col_name]
        # Transitions
        if transition_prob > 0
            # Non 4th down handling
            if current_state.down < 4
                if section >= current_state.first_down_section
                    next_first_down = section + 1
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
                    next_down == 1 ? section + 1 : current_state.first_down_section,
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
                        section + 1,
                        current_state.offense_has_ball,
                        current_state.is_first_half
                    )
                else
                    # Short of 1st down
                    next_state = State(
                        current_state.plays_remaining - 1,
                        current_state.score_diff,
                        timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
                        11 - section,
                        FIRST_DOWN,
                        11 - section + 1,
                        1 - current_state.offense_has_ball,
                        current_state.is_first_half
                    )
                end
            end
            play_value += transition_prob * state_value(
                next_state
            )[1]
        end
    end
    # Pick six scenario
    pick_six_prob = probabilities[1,:"T-0"]
    if pick_six_prob > 0
        next_state = State(
            current_state.plays_remaining - 1,
            Bool(current_state.offense_has_ball) ? current_state.score_diff - TOUCHDOWN_SCORE : current_state.score_diff + TOUCHDOWN_SCORE,
            timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            TOUCHBACK_SECTION + 1,
            current_state.offense_has_ball,
            current_state.is_first_half
        )
        play_value += pick_six_prob * state_value(
            next_state
        )[1]
    end
    # Touchdown scenario
    td_prob = probabilities[1,"T-11"]
    if td_prob > 0
        next_state = State(
            current_state.plays_remaining - 1,
            Bool(current_state.offense_has_ball) ? current_state.score_diff + TOUCHDOWN_SCORE : current_state.score_diff - TOUCHDOWN_SCORE,
            timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            TOUCHBACK_SECTION + 1,
            1 - current_state.offense_has_ball,
            current_state.is_first_half
        )
        play_value += td_prob * state_value(
            next_state
        )[1]
    end
    return play_value
end
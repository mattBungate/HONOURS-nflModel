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
    timeout_called:: Bool
):: Union{Float64, Nothing}

    probabilities = filter(row ->
        (row[:"Down"] == current_state.down) &
        (row[:"Position"] == current_state.ball_section) &
        (row[:"Timeout Used"] == Int(timeout_called)),
        transition_df
    )
    play_value = 0

    for section in NON_SCORING_FIELD_SECTIONS
        col_name = Symbol("T-$section")
        transition_prob = probabilities[1, col_name]
        # Transitions
        if transition_prob > PROB_TOL
            # Non 4th down handling
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
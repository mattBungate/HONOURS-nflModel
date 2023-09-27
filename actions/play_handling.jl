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
    
    first_down_section = Int(ceil((current_state.first_down_dist + current_state.ball_section)/10) + 1)

    for section in 1:10
        col_name = Symbol("T-$section")
        transition_prob = probabilities[1, col_name]
        # Calculate what down it is and where the next down is
        if section >= first_down_section
            next_first_down = section + 1
            next_down = 1
        else
            next_first_down = first_down_section
            next_down = down + 1
        end
        if transition_prob > 0
            next_state = State(
                current_state.plays_remaining - 1,
                current_state.score_diff,
                timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
                section,
                next_down,
                10,
                current_state.offense_has_ball,
                current_state.is_first_half
            )
            play_value += transition_prob * run_play(
                next_state
            )[1]
        end
    end
    # Pick six scenario
    pick_six_prob = probabilities[1,:"T-0"]
    if pick_six_prob > 0
        next_state = State(
            current_state.plays_remaining - 1,
            Bool(current_state.offense_has_ball) ? current_state.score_diff - 7 : current_state.score_diff + 7,
            timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
            3,
            1,
            10,
            current_state.offense_has_ball,
            current_state.is_first_half
        )
        play_value += pick_six_prob * run_play(
            next_state
        )[1]
    end
    # Touchdown scenario
    td_prob = probabilities[1,"T-11"]
    if td_prob > 0
        next_state = State(
            current_state.plays_remaining - 1,
            Bool(current_state.offense_has_ball) ? current_state.score_diff + 7 : current_state.score_diff - 7,
            timeout_called ? current_state.timeouts_remaining - 1 : current_state.timeouts_remaining,
            3,
            1,
            10,
            1 - current_state.offense_has_ball,
            current_state.is_first_half
        )
        play_value += td_prob * run_play(
            next_state
        )[1]
    end
    return play_value
end
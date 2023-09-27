"""
Calculates the expected value after the play is executed

Parameters:
State values: Used for transitioning to next State
probabilities: Probability of transition (dependent on the play type)

The type of play will be handled before this function is called.
Type of play only impacts probabilities. Everything else can be calculated/infered
"""
function play_value(
    time_remaining::Int,
    score_diff::Int,
    timeouts_remaining::Int,
    ball_position::Int,
    down::Int,
    first_down_position::Int,
    offense_has_ball::Bool,
    is_first_half::Bool,

    probabilities::DataFrame,
)
    play_value = 0

    ball_section = Int(ceil(ball_position/10))
    first_down_section = Int(ceil((first_down_position+ball_section)/10) + 1)

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
            play_value += transition_prob * run_play(
                Int(time_remaining-1),
                score_diff,
                Int(timeouts_remaining-1),
                Int(10*section - 5),
                Int(next_down),
                10,
                down == 4 ? !offense_has_ball : offense_has_ball,
                is_first_half
            )[1]
        end
    end
    # Pick six scenario
    pick_six_prob = probabilities[1,:"T-0"]
    if pick_six_prob > 0
        play_value += pick_six_prob * run_play(
            Int(time_remaining-1),
            offense_has_ball ? Int(score_diff-7) : Int(score_diff+7),
            Int(timeouts_remaining-1),
            25,
            1,
            10,
            down == 4 ? !offense_has_ball : offense_has_ball,
            is_first_half
        )[1]
    end
    # Touchdown scenario
    td_prob = probabilities[1,"T-11"]
    if td_prob > 0
        play_value += td_prob * run_play(
            Int(time_remaining-1),
            Int(score_diff+7),
            Int(timeouts_remaining-1),
            25,
            1,
            10,
            down == 4 ? !offense_has_ball : offense_has_ball,
            is_first_half
        )[1]
    end
    return play_value
end
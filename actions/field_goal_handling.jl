"""
Calcultes the expected value of a field goal attempt

Parameters:
- State space
- Probability of field goal

Probability could be calculated be calculated in function with state space
Model already retrieves probability from DataFrame and stores in variable. No use retrieving again
"""
function field_goal_attempt(
    time_remaining::Int,
    score_diff::Int,
    timeouts_remaining::Int,
    ball_position::Int,
    down::Int,
    first_down_position::Int,
    offense_has_ball::Bool,
    is_first_half::Bool,

    field_goal_prob::Float64
)
    field_goal_value = 0

    ball_section = Int(ceil(ball_position/10))
    # Kick field goal outcome
    field_goal_made_val = field_goal_prob * run_play(
        Int(time_remaining-1),
        Int(score_diff + 3),
        timeouts_remaining,
        25,
        1,
        10,
        !offense_has_ball,
        is_first_half
    )[1]
    # Missed field goal outcome
    if ball_section < 10
        field_goal_missed_val = (1-field_goal_prob) * run_play(
            Int(time_remaining-1),
            score_diff,
            timeouts_remaining,
            Int(100 - 10*ball_section-5),
            1,
            10,
            !offense_has_ball,
            is_first_half
        )[1]
    else
        field_goal_missed_val = (1-field_goal_prob)*run_play(
            Int(time_remaining-1),
            score_diff,
            timeouts_remaining,
            20,
            1,
            10,
            !offense_has_ball,
            is_first_half
        )[1]
    end
    field_goal_value = field_goal_missed_val + field_goal_made_val
    return field_goal_value
end
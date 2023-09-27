"""
Calcultes the expected value of a field goal attempt

Parameters:
- State space
- Probability of field goal

Probability could be calculated be calculated in function with state space
Model already retrieves probability from DataFrame and stores in variable. No use retrieving again
"""
function field_goal_attempt(
    current_state:: State,
    field_goal_prob::Float64
)
    # Kick field goal outcome
    next_state = State(
        current_state.plays_remaining - 1,
        Bool(current_state.offense_has_ball) ? current_state.score_diff + FIELD_GOAL_SCORE : current_state.score_diff - FIELD_GOAL_SCORE,
        current_state.timeouts_remaining,
        TOUCHBACK_SECTION,
        FIRST_DOWN, 
        TOUCHBACK_SECTION + 1,
        1 - current_state.offense_has_ball,
        current_state.is_first_half
    )
    field_goal_made_val = field_goal_prob * state_value(
        next_state
    )[1]
    # Missed field goal outcome
    if current_state.ball_section < FIELD_GOAL_MERCY_SECTION
        next_state = State(
            current_state.plays_remaining - 1,
            current_state.score_diff,
            current_state.timeouts_remaining,
            11 - current_state.ball_section,
            FIRST_DOWN,
            (11 - current_state.ball_section) + 1,
            1 - current_state.offense_has_ball,
            current_state.is_first_half
        )
        field_goal_missed_val = (1-field_goal_prob) * state_value(
            next_state
        )[1]
    else
        next_state = State(
            current_state.plays_remaining - 1,
            current_state.score_diff,
            current_state.timeouts_remaining,
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            TOUCHBACK_SECTION + 1,
            1 - current_state.offense_has_ball,
            current_state.is_first_half
        )
        field_goal_missed_val = (1-field_goal_prob)*state_value(
            next_state
        )[1]
    end
    field_goal_value = field_goal_missed_val + field_goal_made_val
    return field_goal_value
end
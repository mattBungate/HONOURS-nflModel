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
    optimal_value:: Union{Nothing, Float64}
):: Union{Float64, Nothing}

    # Get the field goal prob
    field_goal_section = Int(ceil(current_state.ball_section/10))
    col_name = Symbol("T-$field_goal_section")
    field_goal_prob = field_goal_df[1, col_name]

    # Missed field goal outcome
    if current_state.ball_section < FIELD_GOAL_MERCY_SECTION
        next_state = State(
            current_state.plays_remaining - 1,
            current_state.score_diff,
            current_state.timeouts_remaining,
            100 - current_state.ball_section,
            FIRST_DOWN,
            (100 - current_state.ball_section) + FIRST_DOWN_TO_GO,
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
            TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
            1 - current_state.offense_has_ball,
            current_state.is_first_half
        )
        field_goal_missed_val = (1-field_goal_prob)*state_value(
            next_state
        )[1]
    end
    # If second half & cannot reach optimal value no need to continue
    if (!Bool(current_state.is_first_half) && 
        optimal_value !== nothing && 
        field_goal_missed_val + field_goal_prob < optimal_value)
        return nothing
    end

    
    # Don't calculate if there field goal cannot be kicked
    if field_goal_prob < PROB_TOL
        return nothing
    end
    # Kick field goal outcome
    next_state = State(
        current_state.plays_remaining - 1,
        Bool(current_state.offense_has_ball) ? current_state.score_diff + FIELD_GOAL_SCORE : current_state.score_diff - FIELD_GOAL_SCORE,
        current_state.timeouts_remaining,
        TOUCHBACK_SECTION,
        FIRST_DOWN, 
        TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
        1 - current_state.offense_has_ball,
        current_state.is_first_half
    )
    field_goal_made_val = field_goal_prob * state_value(
        next_state
    )[1]
    field_goal_value = field_goal_missed_val + field_goal_made_val
    return field_goal_value
end
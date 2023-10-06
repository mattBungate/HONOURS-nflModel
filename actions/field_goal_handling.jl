"""
Calcultes the expected value of a field goal attempt

Parameters:
- State space
- Probability of field goal

Probability could be calculated be calculated in function with state space
Model already retrieves probability from DataFrame and stores in variable. No use retrieving again
"""
function field_goal_value_calc(
    current_state::State
)::Union{Nothing,Float64}

    # Check field goal is a valid decision
    if current_state.ball_section < FIELD_GOAL_CUTOFF
        return nothing
    end

    # Get Probability
    ball_section_10_yard = Int(ceil(current_state.ball_section / 10))
    col_name = Symbol("T-$(ball_section_10_yard)")
    field_goal_prob = field_goal_df[1, col_name]

    # Missed field goal outcome
    if current_state.ball_section < FIELD_GOAL_MERCY_SECTION
        # Time of play stuff
        next_state = State(
            current_state.seconds_remaining - 1, # Need to change this to seconds. Need data
            -current_state.score_diff,
            reverse(current_state.timeouts_remaining),
            TOUCHDOWN_SECTION - current_state.ball_section,
            FIRST_DOWN,
            TOUCHDOWN_SECTION - current_state.ball_section + FIRST_DOWN_TO_GO,
            false,
            false,
            current_state.is_first_half
        )
        field_goal_missed_val = (1 - field_goal_prob) * -state_value_calc(
            next_state
        )[1]
    else
        next_state = State(
            current_state.plays_remaining - 1, # Need to change this to seconds. Need data
            -current_state.score_diff,
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
            false,
            false,
            current_state.is_first_half
        )
        field_goal_missed_val = (1 - field_goal_prob) * -state_value_calc(
            next_state
        )[1]
    end

    # Kick field goal outcome
    next_state = State(
        current_state.plays_remaining - 1, # Need to change this to seconds. Need data
        -(current_state.score_diff + FIELD_GOAL_SCORE),
        reverse(current_state.timeouts_remaining),
        TOUCHBACK_SECTION,
        FIRST_DOWN,
        TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
        false,
        false,
        current_state.is_first_half
    )
    field_goal_made_val = field_goal_prob * -state_value_calc(
        next_state
    )[1]

    field_goal_value = field_goal_missed_val + field_goal_made_val
    return field_goal_value
end
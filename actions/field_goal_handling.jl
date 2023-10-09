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

    field_goal_value = 0

    # Check field goal is a valid decision
    if current_state.ball_section < FIELD_GOAL_CUTOFF
        return nothing
    end

    # Get Probability
    ball_section_10_yard = Int(ceil(current_state.ball_section / 10))
    col_name = Symbol("T-$(ball_section_10_yard)")
    field_goal_prob = field_goal_df[1, col_name]

    time_probs = filter(row ->
            (row[:"Field Section"] == current_state.down),
        time_field_goal_df
    )

    for seconds in MIN_FIELD_GOAL_DURATION:MAX_FIELD_GOAL_DURATION
        time_prob = time_probs[1, Symbol("$(seconds) secs")]

        if time_prob > TIME_PROB_TOL
            # Missed field goal outcome
            if current_state.ball_section < FIELD_GOAL_MERCY_SECTION
                # Time of play stuff
                next_state = State(
                    current_state.seconds_remaining - 1, # Need to change this to seconds. Need data
                    -current_state.score_diff,
                    reverse(current_state.timeouts_remaining),
                    flip_field(current_state.ball_section),
                    FIRST_DOWN,
                    flip_field(current_state.ball_section) + FIRST_DOWN_TO_GO,
                    false,
                    false,
                    current_state.is_first_half
                )
                field_goal_value += (1 - field_goal_prob) * time_prob * -state_value_calc(
                                        next_state
                                    )[1]
            else
                next_state = State(
                    current_state.seconds_remaining - 1, # Need to change this to seconds. Need data
                    -current_state.score_diff,
                    reverse(current_state.timeouts_remaining),
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
                    false,
                    false,
                    current_state.is_first_half
                )
                field_goal_value += (1 - field_goal_prob) * time_prob * -state_value_calc(
                                        next_state
                                    )[1]
            end

            # Kick field goal outcome
            next_state = State(
                current_state.seconds_remaining - 1, # Need to change this to seconds. Need data
                -(current_state.score_diff + FIELD_GOAL_SCORE),
                reverse(current_state.timeouts_remaining),
                TOUCHBACK_SECTION,
                FIRST_DOWN,
                TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
                false,
                false,
                current_state.is_first_half
            )
            field_goal_value += field_goal_prob * time_prob * -state_value_calc(
                                    next_state
                                )[1]
        end
    end

    return field_goal_value
end
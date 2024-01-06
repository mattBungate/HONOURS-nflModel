"""
Calcultes the expected value of a field goal attempt

Parameters:
- State space
- Probability of field goal

Probability could be calculated be calculated in function with state space
Model already retrieves probability from DataFrame and stores in variable. No use retrieving again
"""
function field_goal_value_calc(
    current_state::State,
    optimal_value::Union{Nothing,Float64},
    seconds_cutoff::Int
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
            (row[:"Field Section"] == ball_section_10_yard),
        time_field_goal_df
    )

    if current_state.seconds_remaining <= MAX_FIELD_GOAL_DURATION
        game_end_time_prob = 1
    end

    made_field_goal_value = 0

    # Kick field goal outcome
    for seconds in MIN_FIELD_GOAL_DURATION:MAX_FIELD_GOAL_DURATION
        # Get time probability
        time_prob = time_probs[1, Symbol("$(seconds) secs")]
        #if time_prob > TIME_PROB_TOL || current_state.seconds_remaining == seconds
        next_state = State(
            current_state.seconds_remaining - seconds,
            -(current_state.score_diff + FIELD_GOAL_SCORE),
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        )
        field_goal_time_value_made = -state_value_calc_LDFS(next_state, seconds_cutoff, false)[1]
        if seconds == current_state.seconds_remaining
            made_field_goal_value += game_end_time_prob * field_goal_time_value_made
            break
        else
            made_field_goal_value += time_prob * field_goal_time_value_made
        end
        #end
        if current_state.seconds_remaining <= MAX_FIELD_GOAL_DURATION
            game_end_time_prob -= time_prob
        end
    end
    # Define upper bound on each outcome state value
    best_case_value = made_field_goal_value
    # Update field goal value
    field_goal_value += field_goal_prob * made_field_goal_value

    prob_remaining = (1 - field_goal_prob)

    if current_state.seconds_remaining <= MAX_FIELD_GOAL_DURATION
        game_end_time_prob = 1
    end

    # Miss field goal upper bounds
    for seconds in MIN_FIELD_GOAL_DURATION:MAX_FIELD_GOAL_DURATION # TODO: Look at reversing this possibly for better performance
        # Get time probability
        time_prob = time_probs[1, Symbol("$(seconds) secs")]

        #if time_prob > TIME_PROB_TOL || seconds == current_state.seconds_remaining
        # Missed field goal outcome
        if current_state.ball_section < FIELD_GOAL_MERCY_SECTION
            next_state = State(
                current_state.seconds_remaining - seconds,
                -current_state.score_diff,
                reverse(current_state.timeouts_remaining),
                flip_field(current_state.ball_section),
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false
            )
            field_goal_time_value = -state_value_calc_LDFS(next_state, seconds_cutoff, false)[1]
            if seconds == current_state.seconds_remaining
                field_goal_value += (1 - field_goal_prob) * game_end_time_prob * field_goal_time_value
                break
            else
                field_goal_value += (1 - field_goal_prob) * time_prob * field_goal_time_value
            end
        else
            next_state = State(
                current_state.seconds_remaining - seconds,
                -current_state.score_diff,
                reverse(current_state.timeouts_remaining),
                TOUCHBACK_SECTION,
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false
            )
            field_goal_time_value = -state_value_calc_LDFS(next_state, seconds_cutoff, false)[1]
            if seconds == current_state.seconds_remaining
                field_goal_value += (1 - field_goal_prob) * game_end_time_prob * field_goal_time_value
                break
            else
                field_goal_value += (1 - field_goal_prob) * time_prob * field_goal_time_value
            end
        end
        if optimal_value !== nothing && field_goal_value + prob_remaining * best_case_value < optimal_value
            return nothing
        end
        #end
        if current_state.seconds_remaining < MAX_FIELD_GOAL_DURATION
            game_end_time_prob -= time_prob
        end
        prob_remaining -= time_prob * (1 - field_goal_prob)
    end

    return field_goal_value
end
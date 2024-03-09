"""
Generates the outcome space with corresponding probabilities for field goal action
"""
function field_goal_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}} # State, Probability, change possession
    
    if state.ball_section < FIELD_GOAL_CUTOFF
        return []
    end

    field_goal_outcome_space = Vector{Tuple{Union{PlayState, KickoffState, ConversionState}, Float64, Bool}}()

    # Get Probability
    ball_section_10_yard = Int(ceil(state.ball_section / 10))
    col_name = Symbol("T-$(ball_section_10_yard)")
    field_goal_prob = field_goal_df[1, col_name]

    # Set up this way instead of 1 for loop for order of states in output
    # This puts all made field goal states at the front and missed field goals behind

    # Made Field Goal
    remaining_made_time_prob = 1
    for seconds in MIN_FIELD_GOAL_DURATION:MAX_FIELD_GOAL_DURATION
        # Adjust probability for end of game field goals
        if seconds >= state.seconds_remaining
            time_prob = remaining_made_time_prob
        else
            time_prob = FG_TIME_PROBS[seconds]
            remaining_made_time_prob -= time_prob
        end
        made_state_prob = field_goal_prob * time_prob

        if made_state_prob > PROB_TOL
            push!(
                field_goal_outcome_space, 
                (
                    KickoffState(
                        state.seconds_remaining - seconds,
                        state.score_diff + FIELD_GOAL_SCORE,
                        state.timeouts_remaining,
                    ),
                    made_state_prob,
                    true
                )
            )
        end
        # Check if this was end of game play
        if seconds >= state.seconds_remaining
            break
        end
    end

    # Missed field goal
    remaining_missed_time_prob = 1
    for seconds in MIN_FIELD_GOAL_DURATION:MAX_FIELD_GOAL_DURATION
        # Adjust probability for end of game field goals
        if seconds >= state.seconds_remaining
            time_prob = remaining_missed_time_prob
        else
            time_prob = FG_TIME_PROBS[seconds]
            remaining_missed_time_prob -= time_prob
        end
        missed_state_prob = (1 - field_goal_prob) * time_prob

        if missed_state_prob > PROB_TOL
            # In mercy section
            if state.ball_section > flip_field(FIELD_GOAL_MERCY_SECTION)
                push!(
                    field_goal_outcome_space,
                    (
                        PlayState(
                            state.seconds_remaining - seconds,
                            -state.score_diff,
                            reverse(state.timeouts_remaining),
                            FIELD_GOAL_MERCY_SECTION,
                            FIRST_DOWN,
                            FIRST_DOWN_TO_GO,
                            false
                        ),
                        missed_state_prob,
                        true
                    )
                )
            # Outside mercy section
            else
                push!(
                    field_goal_outcome_space,
                    (
                        PlayState(
                            state.seconds_remaining - seconds,
                            -state.score_diff,
                            reverse(state.timeouts_remaining),
                            flip_field(state.ball_section),
                            FIRST_DOWN,
                            FIRST_DOWN_TO_GO,
                            false
                        ),
                        missed_state_prob,
                        true
                    )
                )
            end
        end
        # Check if this was an end of game play
        if seconds >= state.seconds_remaining
            break
        end
    end
    
    return field_goal_outcome_space
end


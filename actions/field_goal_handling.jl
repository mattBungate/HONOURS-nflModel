"""
Returns all the children if a field goal is attempted given a state
"""
function field_goal_children(
    current_state::State,
)::Vector{State}
    field_goal_child_states = []
    # Check if the field goal is feasible
    if 100 - current_state.ball_section > FIELD_GOAL_CUTOFF
        return []
    end

    # States for if field goal made 
    for seconds in MIN_FIELD_GOAL_DURATION:MAX_FIELD_GOAL_DURATION
        if seconds > current_state.seconds_remaining
            break
        end
        child_state = State(
            current_state.seconds_remaining - seconds,
            -(current_state.score_diff + FIELD_GOAL_SCORE),
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        )
        push!(field_goal_child_states, child_state)
    end
    # States for if field goal missed
    for seconds in MIN_FIELD_GOAL_DURATION:MAX_FIELD_GOAL_DURATION
        if seconds > current_state.seconds_remaining
            break
        end
        if current_state.ball_section < FIELD_GOAL_MERCY_SECTION
            child_state = State(
                current_state.seconds_remaining - seconds,
                -current_state.score_diff,
                reverse(current_state.timeouts_remaining),
                flip_field(current_state.ball_section),
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false
            )
            println("Missed field goal state: $child_state")
            push!(field_goal_child_states, child_state)
        else
            child_state = State(
                current_state.seconds_remaining - seconds,
                -current_state.score_diff,
                reverse(current_state.timeouts_remaining),
                TOUCHBACK_SECTION,
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false
            )
            println("Missed field goal ")
            push!(field_goal_child_states, child_state)
        end
    end
    # Create "end of game state" if not covered by above
    if current_state.seconds_remaining < MIN_FIELD_GOAL_DURATION
        # field goal made
        made_child_state = State(
            0,
            -(current_state.seconds_remaining + FIELD_GOAL_SCORE),
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        )
        push!(field_goal_child_states, made_child_state)
        # field goal missed
        missed_child_state = State(
            0, 
            -current_state.seconds_remaining,
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        )
        push!(field_goal_child_states, missed_child_state)
    end
    return field_goal_child_states
end

function select_field_goal_child(
    current_state::State
)::Tuple{State, Bool}
    """ Field goal random variables """
    # --- TIME ---
    # TODO: factor out these as constants
    FIELD_GOAL_TIME_DIST = Normal(6, 1.5) # TODO: play with these constants
    
    field_goal_duration = round(rand(FIELD_GOAL_TIME_DIST))
    if field_goal_duration < 3
        field_goal_duration = 3 # TODO: factor out this constant
    elseif field_goal_duration > 9
        field_goal_duration = 9 # TODO: factor out this constant
    end

    # --- Making Field Goal ---
    field_goal_made_rand_val = rand() # Number between 0  and 1
    # Get field goal prob
    ball_section_10_yard = Int(ceil(current_state.ball_section / 10))
    col_name = Symbol("T-$(ball_section_10_yard)")
    field_goal_prob = field_goal_df[1, col_name]

    """ Return outcome state """ 
    if field_goal_made_rand_val < field_goal_prob
        # Made the field goal
        return (State(
            current_state.seconds_remaining - field_goal_duration,
            -(current_state.score_diff + FIELD_GOAL_SCORE),
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        ),
        true)
    else
        # Missed field goal
        if current_state.ball_section < FIELD_GOAL_MERCY_SECTION
            # Behind the mercy section
            return (State(
                current_state.seconds_remaining - field_goal_duration,
                -current_state.score_diff,
                reverse(current_state.timeouts_remaining),
                flip_field(current_state.ball_section),
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false
            ),
            true)
        else
            # In front of the mercy section
            return (State(
                current_state.seconds_remaining - field_goal_duration,
                -current_state.score_diff,
                reverse(current_state.timeouts_remaining),
                TOUCHBACK_SECTION,
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false
            ),
            true)
        end
    end
end
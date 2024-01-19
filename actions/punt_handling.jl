"""
Return children for punting action given state
"""
function punt_children(
    current_state::State,
)::Vector{State}
    # Check feasiblity of punting
    if current_state.down != 4 || current_state.ball_section > 100 - TOUCHBACK_SECTION
        return []
    else
        punt_children_states = []
        for seconds in MIN_PUNT_DURATION:MAX_PUNT_DURATION
            # Returned for TD
            if seconds > current_state.seconds_remaining
                break
            end
            push!(
                punt_children_states,
                State(
                    current_state.seconds_remaining - seconds,
                    current_state.score_diff - TOUCHDOWN_SCORE,
                    current_state.timeouts_remaining,
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    false
                )
            )
            # All other returns
            for section in NON_SCORING_FIELD_SECTIONS
                push!(
                    punt_children_states,
                    State(
                        current_state.seconds_remaining - seconds,
                        current_state.score_diff,
                        reverse(current_state.timeouts_remaining),
                        section,
                        FIRST_DOWN,
                        FIRST_DOWN_TO_GO,
                        false
                    )
                )
            end
        end
        return punt_children_states
    end
end

function select_punt_child(
    current_state::State
)::Tuple{State, Bool}
    """ Random variables """
    # Time
    PUNT_DURATION_DIST = Normal(13, 2.5) # TODO: Change μ & σ. Just did play duration with μ+5
    punt_duration = round(rand(PUNT_DURATION_DIST))
    if punt_duration < 6
        punt_duration = 6
    elseif punt_duration > 16
        punt_duration = 16
    end
    time_remaining = max(current_state.seconds_remaining - punt_duration, 0)
    # Ball Position
    PUNT_BALL_POSITION_DIST = Normal(45-13, 10) # TODO: Change μ & σ. μ found from average punt - average return
    punt_return_position = round(rand(PUNT_BALL_POSITION_DIST))
    # Clock ticking
    clock_ticking_random_var = (rand() > 0.5) # 50/50 clock ticking or stopped

    """ Selection """
    if punt_return_position <= TOUCHDOWN_CONCEEDED_SECTION
        # Punt returned for touchdown
        return (State(
            time_remaining,
            current_state.score_diff - TOUCHDOWN_SCORE,
            current_state.timeouts_remaining,
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        ), false)
    elseif punt_return_position >= TOUCHDOWN_SECTION
        # Punted into endzone. Other team gets a touchback
        return (State(
            time_remaining,
            -current_state.score_diff,
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        ), true)
    else
        # Non-scoring return
        return (State(
            time_remaining,
            -current_state.score_diff,
            reverse(current_state.timeouts_remaining),
            punt_return_position,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            clock_ticking_random_var
        ), true)
    end
end
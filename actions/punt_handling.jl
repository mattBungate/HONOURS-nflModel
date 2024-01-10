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
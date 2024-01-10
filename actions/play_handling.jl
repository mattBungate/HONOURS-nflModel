"""
Return children states given a play was run. 
Either delayed or hurried 
(the same its just wether you let the 40 second game glock run off)
"""
function delayed_play_children(
    current_state::State
)::Vector{State}
    if current_state.seconds_remaining < MIN_PLAY_LENGTH
        return []
    else
        return play_children(current_state, 1)
    end
end

function hurried_play_children(
    current_state::State,
)::Vector{State}
    return play_children(current_state, 0)
end

function play_children(
    current_state::State,
    delayed::Int
)::Vector{State}
    play_children_states = []
    for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
        play_seconds = delayed * MAX_PLAY_CLOCK_DURATION - seconds
        # Cover the case where delaying play until last second
        if current_state.seconds_remaining < delayed * MAX_PLAY_CLOCK_DURATION + MIN_PLAY_LENGTH
            play_seconds = current_state.seconds_remaining
        elseif play_seconds > current_state.seconds_remaining
            break
        end
        # Scoring play
        push!(
            play_children_states,
            State(
                current_state.seconds_remaining - play_seconds,
                -(current_state.score_diff + TOUCHDOWN_SCORE),
                reverse(current_state.timeouts_remaining),
                TOUCHBACK_SECTION,
                FIRST_DOWN, 
                FIRST_DOWN_TO_GO,
                false
            )
        )
        # Pick-six play
        push!(
            play_children_states,
            State(
                current_state.seconds_remaining - play_seconds,
                current_state.score_diff - TOUCHDOWN_SCORE,
                current_state.timeouts_remaining,
                TOUCHBACK_SECTION,
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false
            )
        )
        # Non-scoring play
        for section in NON_SCORING_FIELD_SECTIONS
            # 4th down play
            if current_state.down == 4
                # Made 4th down
                if current_state.ball_section + current_state.first_down_dist <= section
                    # Clock stops after paly
                    push!(
                        play_children_states,
                        State(
                            current_state.seconds_remaining - play_seconds,
                            current_state.score_diff,
                            current_state.timeouts_remaining,
                            section,
                            FIRST_DOWN,
                            min(FIRST_DOWN_TO_GO, TOUCHDOWN_SECTION - section),
                            false
                        )
                    )
                    # Clock ticks after play
                    push!(
                        play_children_states,
                        State(
                            current_state.seconds_remaining - play_seconds,
                            current_state.score_diff,
                            current_state.timeouts_remaining,
                            section,
                            FIRST_DOWN,
                            min(FIRST_DOWN_TO_GO, TOUCHDOWN_SECTION - section),
                            true
                        )
                    )
                else
                    push!(
                        play_children_states,
                        State(
                            current_state.seconds_remaining - play_seconds,
                            -current_state.score_diff,
                            reverse(current_state.timeouts_remaining),
                            flip_field(section),
                            FIRST_DOWN,
                            min(FIRST_DOWN_TO_GO, flip_field(TOUCHDOWN_SECTION - section)),
                            false
                        )
                    )
                end
            else
                # Not 4th down
                # Made first down 
                if current_state.ball_section + current_state.first_down_dist < section
                    # Clock stops after play
                    push!(
                        play_children_states,
                        State(
                            current_state.seconds_remaining - play_seconds,
                            current_state.score_diff,
                            current_state.timeouts_remaining,
                            section,
                            FIRST_DOWN, 
                            min(FIRST_DOWN_TO_GO, TOUCHDOWN_SECTION - section),
                            false
                        )
                    )
                    # Clock ticks after play
                    push!(
                        play_children_states,
                        State(
                            current_state.seconds_remaining - play_seconds,
                            current_state.score_diff,
                            current_state.timeouts_remaining,
                            section,
                            FIRST_DOWN,
                            min(FIRST_DOWN_TO_GO, TOUCHDOWN_SECTION - section),
                            true
                        )
                    )
                else
                    # Didn't make first down
                    # Clock stops after play
                    push!(
                        play_children_states,
                        State(
                            current_state.seconds_remaining - play_seconds,
                            current_state.score_diff,
                            current_state.timeouts_remaining,
                            section,
                            current_state.down + 1, 
                            current_state.ball_section + current_state.first_down_dist - section,
                            false
                        )
                    )
                    # Clock ticks after play
                    push!(
                        play_children_states,
                        State(
                            current_state.seconds_remaining - play_seconds,
                            current_state.score_diff,
                            current_state.timeouts_remaining,
                            section,
                            current_state.down + 1, 
                            current_state.ball_section + current_state.first_down_dist - section,
                            true
                        )
                    )
                end
            end
        end
        # Break out when delaying play to last second
        if current_state.seconds_remaining < delayed * MAX_PLAY_CLOCK_DURATION + MIN_PLAY_LENGTH
            break
        end
    end
    return play_children_states
end
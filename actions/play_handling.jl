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

function select_hurried_play_child(
    current_state::State
)::State
    return select_play_child(current_state, 0)
end

function select_delayed_play_child(
    current_state::State
)::State
    return select_play_child(current_state, 1)
end

function select_play_child(
    current_state::State,
    delayed::Int
)::State
    """ Random Variables """
    # Time - TODO: I think this data already exists (used to create time_df, play_df)
    PLAY_DURATION_DIST = Normal(8, 2.5) # TODO: factor out time duraiton Distribution
    play_duration = round(rand(PLAY_DURATION_DIST))
    if play_duration < 1
        play_duration = 1
    elseif play_duration > 11
        play_duration = 11
    end
    time_remaining = max(current_state.seconds_remaining - delayed*MAX_PLAY_CLOCK_DURATION, 0)
    # Ball position
    YARDS_GAINED_DIST = Normal(4, 10) # TODO: Fine tune numbers (or get from data processing)
    yards_gained = round(rand(YARDS_GAINED_DIST))
    new_ball_position = current_state.ball_section + yards_gained
    # Clock ticking
    clock_ticking_random_var = rand()
    clock_ticking_random_val = (clock_ticking_random_var > 0.5)

    """ Selecting """
    if new_ball_position <= TOUCHDOWN_CONCEEDED_SECTION
        # Conceeded pick-six
        return (State(
            time_remaining,
            current_state.score_diff - TOUCHDOWN_SCORE,
            current_state.timeouts_remaining,
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        ),
        false)
    elseif new_ball_position >= TOUCHDOWN_SECTION
        # Scoring play
        return (State(
            time_remaining,
            -(current_state.score_diff + TOUCHDOWN_SCORE),
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        ), true)
    else
        # Non-scoring play
        if new_ball_position > current_state.ball_section + current_state.first_down_dist
            # Fresh set of downs
            return (State(
                time_remaining,
                current_state.score_diff,
                current_state.timeouts_remaining,
                new_ball_position,
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                clock_ticking_random_val
            ), false)
        else
            # Short of first down
            if current_state.down == 4
                # Turnover
                return (State(
                    time_remaining,
                    -current_state.score_diff,
                    reverse(current_state.timeouts_remaining),
                    flip_field(new_ball_position),
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    false # Assume clock stops on turnover
                ), true)
            else
                # Next down
                return (State(
                    time_remaining,
                    current_state.score_diff,
                    current_state.timeouts_remaining,
                    new_ball_position,
                    current_state.down + 1,
                    current_state.ball_section + current_state.first_down_dist - new_ball_position,
                    clock_ticking_random_val
                ), false)
            end
        end
    end
end
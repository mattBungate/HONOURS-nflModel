"""
Calculates the expected value after the play is executed

Parameters:
State values: Used for transitioning to next State
probabilities: Probability of transition (dependent on the play type)

The type of play will be handled before this function is called.
Type of play only impacts probabilities. Everything else can be calculated/infered
"""
function play_value_calc(
    current_state::State,
    timeout_called_planned::Bool
)::Union{Nothing,Float64}
    # If timeout planned check it can be done 
    if timeout_called_planned
        if current_state.timeouts_remaining[1] == 0
            return nothing
        end
    end
    play_value = 0

    # Get the probabilities
    probabilities = filter(row ->
            (row[:"Down"] == current_state.down) &
            (row[:"Position"] == current_state.ball_section) &
            (row[:"Timeout Used"] == current_state.timeout_called),
        play_df
    )

    # Pick six scenario
    pick_six_prob = probabilities[1, :"Def Endzone"]
    if pick_six_prob > 0
        dist_gained = -current_state.ball_section
        time_probabilities = filter(row ->
                (row[:"Yards Gained"] == dist_gained) &
                (row[:"Clock Stopped"] == 1),
            time_df
        )
        for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
            if size(time_probabilities, 1) > 1
                time_prob = time_probabilities[1, Symbol("$(seconds) seconds")]
            else
                if seconds == Int(ceil((MIN_PLAY_LENGTH + MAX_PLAY_LENGTH) / 2))
                    time_prob = 1
                else
                    time_prob = 0
                end
            end
            if time_prob > TIME_PROB_TOL || seconds == current_state.seconds_remaining
                next_state = State(
                    current_state.seconds_remaining - seconds, # Change this to seconds. Need data
                    -(current_state.score_diff - TOUCHDOWN_SCORE),
                    current_state.timeouts_remaining,
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
                    false,
                    false, # Clock stops after TD
                    current_state.is_first_half
                )
                play_second_value = -state_value_calc(next_state)[1]
                play_value += pick_six_prob * time_prob * play_second_value
            end
        end
    end

    # Non scoring scenarios
    for section in NON_SCORING_FIELD_SECTIONS
        dist_gained = section - current_state.ball_section
        col_name = Symbol("T-$section")
        transition_prob = probabilities[1, col_name]
        time_probabilities = filter(row ->
                (row[:"Yards Gained"] == dist_gained),
            time_df
        )
        # Transitions
        if transition_prob > 0
            for clock_stopped in 0:1
                for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
                    # TODO: Fix this section. No time data for yards gained
                    if size(time_probabilities, 1) > 0
                        time_prob = time_probabilities[clock_stopped+1, Symbol("$(seconds) seconds")]
                    else
                        if seconds == Int(ceil(MIN_PLAY_LENGTH + MAX_PLAY_LENGTH) / 2)
                            time_prob = 1
                        else
                            time_prob = 0
                        end
                    end
                    if time_prob > TIME_PROB_TOL || seconds == current_state.seconds_remaining
                        # Non 4th down handling
                        if current_state.down < 4
                            if section >= current_state.first_down_section
                                next_first_down = section + 1
                                next_down = FIRST_DOWN
                            else
                                next_first_down = current_state.first_down_section
                                next_down = current_state.down + 1
                            end
                            # Handle timeout stuff
                            if timeout_called_planned
                                timeouts_remaining_if_called = (current_state.timeouts_remaining[1] - 1, current_state.timeouts_remaining[2])
                            end
                            next_state = State(
                                current_state.seconds_remaining - seconds,
                                current_state.score_diff,
                                (Bool(clock_stopped) || !timeout_called_planned) ? current_state.timeouts_remaining : timeouts_remaining_if_called,
                                section,
                                next_down, # Look into how I did this next_down crap
                                next_down == 1 ? section + FIRST_DOWN_TO_GO : current_state.first_down_section, # This is probs wrong. Set up for 10yard thingo
                                Bool(clock_stopped) ? false : !timeout_called_planned,
                                Bool(clock_stopped) || timeout_called_planned,
                                current_state.is_first_half
                            )
                            play_second_value = state_value_calc(next_state)[1]
                            play_value += transition_prob * time_prob * play_second_value
                        else
                            if timeout_called_planned
                                timeouts_remaining_if_called = (current_state.timeouts_remaining[1] - 1, current_state.timeouts_remaining[2])
                            end
                            # 4th down handling
                            if section >= current_state.first_down_section
                                # Made it
                                next_state = State(
                                    current_state.seconds_remaining - seconds,
                                    current_state.score_diff,
                                    (Bool(clock_stopped) || !timeout_called_planned) ? current_state.timeouts_remaining : timeouts_remaining_if_called,
                                    section, # Probs rename
                                    FIRST_DOWN,
                                    section + FIRST_DOWN_TO_GO, # 
                                    Bool(clock_ticking) ? false : !timeout_called_planned,
                                    Bool(clock_stopped) || timeout_called_planned,
                                    current_state.is_first_half
                                )
                                play_value += transition_prob * time_prob * state_value_calc(
                                                  next_state
                                              )[1]
                            else
                                # Short of 1st down
                                next_state = State(
                                    current_state.seconds_remaining - seconds, # Change this to seconds. Need data
                                    -current_state.score_diff,
                                    reverse(current_state.timeouts_remaining), # Figure out timeout handling
                                    flip_field(current_state.ball_section),
                                    FIRST_DOWN,
                                    flip_field(current_state.ball_section) + FIRST_DOWN_TO_GO,
                                    false,
                                    false, # Clock stops during turnover in last 2 mins of 1st half and 5mins of 2nd half. All tests are within this range. 
                                    current_state.is_first_half
                                )
                                play_value += transition_prob * time_prob * -state_value_calc(
                                                  next_state
                                              )[1]
                            end
                        end
                    end
                end
            end
        end
    end

    # Touchdown scenario
    td_prob = probabilities[1, :"Off Endzone"]
    if td_prob > 0
        dist_gained = TOUCHDOWN_SECTION - current_state.ball_section
        for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
            time_probabilities = filter(row ->
                    (row[:"Yards Gained"] == dist_gained) &
                    (row[:"Clock Stopped"] == 1),
                time_df
            )
            if size(time_probabilities, 1) > 0
                time_prob = time_probabilities[1, Symbol("$(seconds) seconds")]
            else
                if seconds == Int(ceil((MIN_PLAY_LENGTH + MAX_PLAY_LENGTH) / 2))
                    time_prob = 1
                else
                    time_prob = 0
                end
            end
            if time_prob > TIME_PROB_TOL || seconds == current_state.seconds_remaining
                next_state = State(
                    current_state.seconds_remaining - seconds, # Change this to seconds. Need data
                    -(current_state.score_diff + TOUCHDOWN_SECTION),
                    reverse(current_state.timeouts_remaining),
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
                    false,
                    false, # We assume fair catch for kickoff.
                    current_state.is_first_half
                )
                play_second_value = -state_value_calc(next_state)[1]
                play_value += td_prob * time_prob * play_second_value
            end
        end
    end
    return play_value
end
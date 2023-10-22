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
    optimal_value_dict::Union{Tuple{Float64,String},Nothing} #Union{Nothing,Float64}
)::Union{Nothing,Float64}
    # println("In play_value_calc function. Optimal value: $optimal_value")
    if optimal_value_dict === nothing
        optimal_value = nothing
    else
        optimal_value = optimal_value_dict[1]
    end
    play_value = 0
    prob_remaining = 1

    # Get the probabilities
    probabilities = filter(row ->
            (row[:"Down"] == current_state.down) &
            (row[:"Position"] == current_state.ball_section) &
            (row[:"Timeout Used"] == current_state.timeout_called),
        play_df
    )

    # Touchdown scenario
    #println("Touchdown section")
    if current_state.seconds_remaining <= MAX_PLAY_LENGTH
        #println("Initialising end of game prob | $(current_state.seconds_remaining) < $(MAX_PLAY_LENGTH)")
        end_of_game_prob = 1
    end
    upper_bound = 0
    td_prob = probabilities[1, :"Off Endzone"]
    dist_gained = TOUCHDOWN_SECTION - current_state.ball_section
    for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
        time_probabilities = filter(row ->
                (row[:"Yards Gained"] >= dist_gained) &
                (row[:"Clock Stopped"] == 1), # why is this here
            time_df
        )
        if current_state.seconds_remaining > seconds
            if size(time_probabilities, 1) > 0
                if current_state.seconds_remaining - seconds > 0
                    time_prob = sum(time_probabilities[!, "$(seconds) seconds"])
                else
                    break
                end
            else
                if seconds == Int(ceil((MIN_PLAY_LENGTH + MAX_PLAY_LENGTH) / 2))
                    time_prob = 1
                else
                    time_prob = 0
                end
            end
            if current_state.seconds_remaining <= MAX_PLAY_LENGTH
                end_of_game_prob -= time_prob
            end
        end
        if seconds == current_state.seconds_remaining || time_prob > TIME_PROB_TOL
            next_state = State(
                current_state.seconds_remaining - seconds,
                -(current_state.score_diff + TOUCHDOWN_SCORE),
                reverse(current_state.timeouts_remaining),
                TOUCHBACK_SECTION,
                FIRST_DOWN,
                TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
                false,
                false, # We assume fair catch for kickoff.
                current_state.is_first_half
            )
            play_second_value = -state_value_calc(next_state)[1]
            if current_state.seconds_remaining > seconds
                #println("Updating upper bound for $(seconds) seconds. Not end of game")
                upper_bound += time_prob * play_second_value
            else
                # End of game caluclation (all lengths of plays that end game caluclated here)
                #println("Updating upper bound for $(seconds) seconds. End of game")
                upper_bound += end_of_game_prob * play_second_value
                break
            end
        end
    end
    #println("Upper bound is: $(upper_bound)")
    prob_remaining -= td_prob

    # Pick six scenario
    #println("\nPick sick scenario")
    if current_state.seconds_remaining <= MAX_PLAY_LENGTH
        end_of_game_prob = 1
    end
    pick_six_prob = probabilities[1, :"Def Endzone"]
    #println("Pick six prob: $(pick_six_prob)")
    if pick_six_prob > 0
        dist_gained = -current_state.ball_section
        time_probabilities = filter(row ->
                (row[:"Yards Gained"] == dist_gained) &
                (row[:"Clock Stopped"] == current_state.clock_ticking),
            time_df
        )
        for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
            if seconds < current_state.seconds_remaining
                if size(time_probabilities, 1) > 1
                    time_prob = time_probabilities[1, Symbol("$(seconds) seconds")]
                    if current_state.seconds_remaining <= MAX_PLAY_LENGTH
                        end_of_game_prob -= time_prob
                    end
                else
                    if seconds == Int(ceil((MIN_PLAY_LENGTH + MAX_PLAY_LENGTH) / 2)) # TODO: fix data so this isn't necessary. Hacky fix
                        time_prob = 1
                        if current_state.seconds_remaining <= MAX_PLAY_LENGTH
                            end_of_game_prob = 0
                        end
                    else
                        time_prob = 0
                    end
                end
            end
            if seconds == current_state.seconds_remaining || time_prob > TIME_PROB_TOL
                next_state = State(
                    current_state.seconds_remaining - seconds,
                    current_state.score_diff - TOUCHDOWN_SCORE,
                    current_state.timeouts_remaining,
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
                    false,
                    false, # Clock stops after TD
                    current_state.is_first_half
                )
                play_second_value = -state_value_calc(next_state)[1]
                if seconds < current_state.seconds_remaining
                    #println("Updating play value for $(seconds) pick six. Not end of game")
                    play_value += pick_six_prob * time_prob * play_second_value
                    prob_remaining -= pick_six_prob * time_prob
                else
                    # End of game (probs of any play length ending with 0 seconds)
                    #println("Updating play value for $(seconds) pick six. End of game")
                    play_value += pick_six_prob * end_of_game_prob * play_second_value
                    prob_remaining -= pick_six_prob * end_of_game_prob
                end
                if optimal_value !== nothing && play_value + prob_remaining * upper_bound < optimal_value
                    if current_state.seconds_remaining == 5
                        #println("Exiting play calc")
                        #println("$play_value | $prob_remaining | $upper_bound | $(play_value + prob_remaining * upper_bound)")
                    end
                    return nothing
                end
                # Exit if game clock is 0 (all longer plays included in calculation)
                if seconds == current_state.seconds_remaining
                    break
                end
            end
        end
    end
    prob_remaining -= pick_six_prob

    # Non scoring scenarios
    #println("\nNon scoring play section")
    for section in NON_SCORING_FIELD_SECTIONS
        dist_gained = section - current_state.ball_section
        col_name = Symbol("T-$section")
        transition_prob = probabilities[1, col_name]
        time_probabilities = filter(row ->
                (row[:"Yards Gained"] == dist_gained),
            time_df
        )
        if current_state.seconds_remaining <= MAX_PLAY_LENGTH
            end_of_game_prob = 1
        end
        # Transitions
        if transition_prob > 0
            for clock_stopped in 0:1
                for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
                    if seconds < current_state.seconds_remaining
                        if size(time_probabilities, 1) > 0
                            time_prob = time_probabilities[clock_stopped+1, Symbol("$(seconds) seconds")]
                        else
                            if seconds == Int(ceil(MIN_PLAY_LENGTH + MAX_PLAY_LENGTH) / 2)
                                time_prob = 1
                            else
                                time_prob = 0
                            end
                        end
                        if current_state.seconds_remaining <= MAX_PLAY_LENGTH
                            end_of_game_prob -= time_prob
                        end
                    end
                    if seconds == current_state.seconds_remaining || time_prob > TIME_PROB_TOL
                        # Non 4th down handling
                        if current_state.down < 4
                            if section >= current_state.first_down_section
                                next_first_down = section + 1
                                next_down = FIRST_DOWN
                            else
                                next_first_down = current_state.first_down_section
                                next_down = current_state.down + 1
                            end
                            next_state = State(
                                current_state.seconds_remaining - seconds,
                                current_state.score_diff,
                                current_state.timeouts_remaining,
                                section,
                                next_down, # Look into how I did this next_down crap
                                (next_down == 1) ? section + FIRST_DOWN_TO_GO : current_state.first_down_section,
                                false,
                                true, # Assumes clock is always ticking
                                current_state.is_first_half
                            )
                            play_second_value = state_value_calc(next_state)[1]
                            if seconds < current_state.seconds_remaining
                                #println("Updating play value for non 4th down play ending $(section) with time $(seconds). Not end of game")
                                play_value += transition_prob * time_prob * play_second_value
                                prob_remaining -= transition_prob * time_prob
                            else
                                # Handle end of game (all lengths of plays that end game)
                                #println("Updating play value for non 4th down play ending $(section) with time $(seconds). End of game")
                                play_value += transition_prob * end_of_game_prob * play_second_value
                                prob_remaining -= transition_prob * end_of_game_prob
                            end
                            if optimal_value !== nothing && play_value + prob_remaining * upper_bound < optimal_value
                                if current_state.seconds_remaining == 5
                                    #println("Exiting play calc | $section | $seconds")
                                    #println("$play_value | $prob_remaining | $upper_bound | $(play_value + prob_remaining * upper_bound)")
                                end
                                return nothing
                            end
                            # Check if game has ended (and thus all longer plays have already been calcualted)
                            if seconds == current_state.seconds_remaining
                                break
                            end
                        else
                            # 4th down handling
                            if section >= current_state.first_down_section
                                # Made it
                                next_state = State(
                                    current_state.seconds_remaining - seconds,
                                    current_state.score_diff,
                                    current_state.timeouts_remaining,
                                    section, # Probs rename
                                    FIRST_DOWN,
                                    section + FIRST_DOWN_TO_GO, # 
                                    false,
                                    true, # Assumes clock is always ticking
                                    current_state.is_first_half
                                )
                                play_second_value = state_value_calc(next_state)[1]
                                if current_state.seconds_remaining > seconds
                                    #println("Updating play value for 4th down made play ending $(section) with time $(seconds). Not end of game")
                                    play_value += transition_prob * time_prob * play_second_value
                                    prob_remaining -= transition_prob * time_prob
                                else
                                    #println("Updating play value for 4th down made play ending $(section) with time $(seconds). End of game")
                                    # Handle end of game (and all lengths of plays that result in this)
                                    play_value += transition_prob * end_of_game_prob * play_second_value
                                    prob_remaining -= transition_prob * end_of_game_prob
                                end
                                if optimal_value !== nothing && play_value + prob_remaining * upper_bound < optimal_value
                                    if current_state.seconds_remaining == 5
                                        #println("Exiting play calc | $section | $seconds | 4th down")
                                        #println("$play_value | $prob_remaining | $upper_bound | $(play_value + prob_remaining * upper_bound) | $optimal_value")
                                    end
                                    return nothing
                                end
                                # Check if game is over (and thus all longer plays have been calcualted)
                                if current_state.seconds_remaining == seconds
                                    break
                                end
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
                                play_second_value = -state_value_calc(next_state)[1]
                                if current_state.seconds_remaining > seconds
                                    #println("Updating play value for 4th down short play ending $(section) with time $(seconds). Not end of game")
                                    play_value += transition_prob * time_prob * play_second_value
                                    prob_remaining -= transition_prob * time_prob
                                else
                                    #println("Updating play value for 4th down short play ending $(section) with time $(seconds). End of game")
                                    # Handle end of game (and all lengths of plays that result in this)
                                    play_value += transition_prob * end_of_game_prob * play_second_value
                                    prob_remaining -= transition_prob * end_of_game_prob
                                end
                                if optimal_value !== nothing && play_value + prob_remaining * upper_bound < optimal_value
                                    if current_state.seconds_remaining == 5
                                        #println("Exiting play calc | $section | $seconds | 4th down hsort")
                                        #println("$play_value | $prob_remaining | $upper_bound | $(play_value + prob_remaining * upper_bound)")
                                    end
                                    return nothing
                                end
                                # Check if game is over (and thus all longer plays have been calculated)
                                if current_state.seconds_remaining == seconds
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    #println(current_state)
    #println("Play value: $play_value\n")
    return play_value
end
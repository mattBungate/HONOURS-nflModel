"""
Calculates the expected value after the play is executed

Parameters:
State values: Used for transitioning to next State
probabilities: Probability of transition (dependent on the play type)

The type of play will be handled before this function is called.
Type of play only impacts probabilities. Everything else can be calculated/infered
"""
function delayed_play_action_calc(
    current_state::State,
    optimal_value::Union{Nothing,Float64},
    seconds_cutoff::Int
)
    if !current_state.clock_ticking || current_state.seconds_remaining == 1
        return nothing
    end
    delayed_play_value = play_value_calc(current_state, optimal_value, 1, seconds_cutoff)
    return delayed_play_value
end

function hurried_play_action_calc(
    current_state::State,
    optimal_value::Union{Nothing,Float64},
    seconds_cutoff::Int
)
    hurried_play_value = play_value_calc(current_state, optimal_value, 0, seconds_cutoff)
    return hurried_play_value
end

function play_value_calc(
    current_state::State,
    optimal_value::Union{Nothing,Float64},
    delayed::Int,
    seconds_cutoff::Int
)::Union{Nothing,Float64}
    play_value = 0
    prob_remaining = 1

    # Get the probabilities
    probabilities = filter(row ->
            (row[:"Down"] == current_state.down) &
            (row[:"Position"] == current_state.ball_section) &
            (row[:"Timeout Used"] == !current_state.clock_ticking), # TODO: Fix this so that prob is based on clock ticking or not
        play_df
    )

    # Touchdown scenario
    if current_state.seconds_remaining <= MAX_PLAY_LENGTH
        end_of_game_prob = 1
    end
    upper_bound = 0
    td_prob = probabilities[1, :"Off Endzone"]
    dist_gained = TOUCHDOWN_SECTION - current_state.ball_section
    for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
        time_probabilities = filter(row ->
                (row[:"Yards Gained"] >= dist_gained) &
                (row[:"Clock Stopped"] == !current_state.clock_ticking),
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
        #if seconds == current_state.seconds_remaining || time_prob > TIME_PROB_TOL
        next_state = State(
            max(current_state.seconds_remaining - seconds - delayed * MAX_PLAY_CLOCK_DURATION, 0), # This will likely give errors in terms of the time prob bullshit
            -(current_state.score_diff + TOUCHDOWN_SCORE),
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false, # We assume fair catch for kickoff.
        )
        play_second_value = -state_value_calc(next_state, false, "")[1]
        if current_state.seconds_remaining > seconds
            upper_bound += time_prob * play_second_value
        else
            upper_bound += end_of_game_prob * play_second_value
            break
        end
        #end
    end
    prob_remaining -= td_prob

    # Pick six scenario
    if current_state.seconds_remaining <= MAX_PLAY_LENGTH
        end_of_game_prob = 1
    end
    pick_six_prob = probabilities[1, :"Def Endzone"]
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
            #if seconds == current_state.seconds_remaining || time_prob > TIME_PROB_TOL
            next_state = State(
                max(current_state.seconds_remaining - seconds - delayed * MAX_PLAY_CLOCK_DURATION, 0), # This will likely give errors for end of game probs (time probs)
                current_state.score_diff - TOUCHDOWN_SCORE,
                current_state.timeouts_remaining,
                TOUCHBACK_SECTION,
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false, # Clock stops after TD
            )
            play_second_value = state_value_calc(next_state, false, "")[1]
            if seconds < current_state.seconds_remaining
                play_value += pick_six_prob * time_prob * play_second_value
                prob_remaining -= pick_six_prob * time_prob
            else
                play_value += pick_six_prob * end_of_game_prob * play_second_value
                prob_remaining -= pick_six_prob * end_of_game_prob
            end
            if optimal_value !== nothing && play_value + prob_remaining * upper_bound < optimal_value
                return nothing
            end
            # Exit if game clock is 0 (all longer plays included in calculation)
            if seconds == current_state.seconds_remaining
                break
            end
            #end
        end
    end
    prob_remaining -= pick_six_prob

    # Non scoring scenarios
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
                    #if seconds == current_state.seconds_remaining || time_prob > TIME_PROB_TOL
                    # Non 4th down handling
                    if current_state.down < 4
                        if section >= current_state.ball_section + current_state.first_down_dist
                            next_first_down = section + 1
                            next_down = FIRST_DOWN
                        else
                            next_first_down = current_state.first_down_dist
                            next_down = current_state.down + 1
                        end
                        next_state = State(
                            max(current_state.seconds_remaining - seconds - delayed * MAX_PLAY_CLOCK_DURATION, 0), # TODO: Likely returns faulty for end of game time probs
                            current_state.score_diff,
                            current_state.timeouts_remaining,
                            section,
                            next_down, # Look into how I did this next_down crap
                            (next_down == 1) ? FIRST_DOWN_TO_GO : min(current_state.first_down_dist + current_state.ball_section - section, MAX_FIRST_DOWN),
                            !Bool(clock_stopped)
                        )
                        play_second_value = state_value_calc(next_state, false, "")[1]
                        if seconds < current_state.seconds_remaining
                            play_value += transition_prob * time_prob * play_second_value
                            prob_remaining -= transition_prob * time_prob
                        else
                            play_value += transition_prob * end_of_game_prob * play_second_value
                            prob_remaining -= transition_prob * end_of_game_prob
                        end
                        if optimal_value !== nothing && play_value + prob_remaining * upper_bound < optimal_value
                            return nothing
                        end
                        # Check if game has ended (and thus all longer plays have already been calcualted)
                        if seconds == current_state.seconds_remaining
                            break
                        end
                    else
                        # 4th down handling
                        if section >= current_state.first_down_dist
                            # Made it
                            next_state = State(
                                max(current_state.seconds_remaining - seconds, 0), # TODO: Likely returns faulty for end of game time probs
                                current_state.score_diff,
                                current_state.timeouts_remaining,
                                section, # Probs rename
                                FIRST_DOWN,
                                FIRST_DOWN_TO_GO,
                                !Bool(clock_stopped)
                            )
                            play_second_value = state_value_calc(next_state, false, "")[1]
                            if current_state.seconds_remaining > seconds
                                play_value += transition_prob * time_prob * play_second_value
                                prob_remaining -= transition_prob * time_prob
                            else
                                play_value += transition_prob * end_of_game_prob * play_second_value
                                prob_remaining -= transition_prob * end_of_game_prob
                            end
                            if optimal_value !== nothing && play_value + prob_remaining * upper_bound < optimal_value
                                return nothing
                            end
                            # Check if game is over (and thus all longer plays have been calcualted)
                            if current_state.seconds_remaining == seconds
                                break
                            end
                        else
                            # Short of 1st down
                            next_state = State(
                                max(current_state.seconds_remaining - seconds, 0), # TODO: Likely returns faulty for end of game time probs
                                -current_state.score_diff,
                                reverse(current_state.timeouts_remaining),
                                flip_field(current_state.ball_section),
                                FIRST_DOWN,
                                FIRST_DOWN_TO_GO,
                                false, # Clock stops during turnover in last 2 mins of 1st half and 5mins of 2nd half. All tests are within this range.
                            )
                            play_second_value = -state_value_calc(next_state, false, "")[1]
                            if current_state.seconds_remaining > seconds
                                play_value += transition_prob * time_prob * play_second_value
                                prob_remaining -= transition_prob * time_prob
                            else
                                play_value += transition_prob * end_of_game_prob * play_second_value
                                prob_remaining -= transition_prob * end_of_game_prob
                            end
                            if optimal_value !== nothing && play_value + prob_remaining * upper_bound < optimal_value
                                return nothing
                            end
                            # Check if game is over (and thus all longer plays have been calculated)
                            if current_state.seconds_remaining == seconds
                                break
                            end
                        end
                    end
                    #end
                end
            end
        end
    end
    return play_value
end

function hurried_play_outcome_space(
    state::State
)::Vector{Tuple{State, Float64, Bool}} # State, prob, change possession
    # TODO: could have different stats fed into this function
    return play_outcome_space(state, 0)
end

function delayed_play_outcome_space(
    state::State
)::Vector{Tuple{State, Float64, Bool}} # State, prob, change possession
    # TODO: could have different stats fed into the play_outcome_space function
    return play_outcome_space(state, 1)
end

function play_outcome_space(
    state::State,
    delayed::Int
)::Vector{Tuple{State, Float64, Bool}} # State, prob, change possession
    # Invalid action
    
    # Domain knowledge

    """ Outcome space """
    outcome_space = []
    # Get the probabilities
    all_position_probs = filter(row ->
            (row[:"Down"] == state.down) &
            (row[:"Position"] == state.ball_section) &
            (row[:"Timeout Used"] == !state.clock_ticking), # TODO: Fix this so that prob is based on clock ticking or not
        play_df
    )
    # Score TD
    td_end_of_game_prob = 1
    td_prob = all_position_probs[1, :"Off Endzone"]
    for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
        play_length = min(seconds + delayed*MAX_PLAY_CLOCK_DURATION, state.seconds_remaining)
        if play_length >= state.seconds_remaining
            td_time_prob = td_end_of_game_prob
        else
            td_time_prob = TIME_PROBS[seconds]
            td_end_of_game_prob -= td_time_prob
        end

        state_prob = td_prob * td_time_prob

        push!(
            outcome_space, 
            (
                State(
                    state.seconds_remaining - play_length,
                    -(state.score_diff + TOUCHDOWN_SCORE),
                    reverse(state.timeouts_remaining),
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    false
                ),
                state_prob,
                true
            )
        )
        if play_length >= state.seconds_remaining
            break
        end
    end

    # Conceed TD
    pick_six_end_of_game_prob = 1
    pick_six_prob = all_position_probs[1, :"Def Endzone"]
    for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
        play_length = min(seconds + delayed*MAX_PLAY_CLOCK_DURATION, state.seconds_remaining)
        if play_length >= state.seconds_remaining
            pick_six_time_prob = pick_six_end_of_game_prob
        else
            pick_six_time_prob = TIME_PROBS[seconds]
            pick_six_end_of_game_prob -= pick_six_time_prob
        end

        state_prob = pick_six_prob * pick_six_time_prob

        push!(
            outcome_space, 
            (
                State(
                    state.seconds_remaining - play_length,
                    state.score_diff - TOUCHDOWN_SCORE,
                    state.timeouts_remaining,
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    false
                ),
                state_prob,
                true
            )
        )
        if play_length >= state.seconds_remaining
            break 
        end
    end

    # Non-scoring play
    for field_position in NON_SCORING_FIELD_SECTIONS
        end_of_game_prob = 1
        pos_prob = all_position_probs[1, Symbol("T-$field_position")]
        for seconds in MIN_PLAY_LENGTH:MAX_PLAY_LENGTH
            play_length = min(seconds + delayed*MAX_PLAY_CLOCK_DURATION, state.seconds_remaining)
            if play_length >= state.seconds_remaining
                time_prob = end_of_game_prob
            else
                time_prob = TIME_PROBS[seconds]
                end_of_game_prob -= time_prob
            end

            for clock_ticking in 0:1
                clock_ticking_prob = 0.5 # TODO: Improve prob
                
                state_prob = pos_prob * time_prob * clock_ticking_prob

                # Made first down 
                if field_position >= state.ball_section + state.first_down_dist
                    push!(
                        outcome_space,
                        (
                            State(
                                state.seconds_remaining - play_length,
                                state.score_diff,
                                state.timeouts_remaining,
                                field_position,
                                FIRST_DOWN,
                                min(FIRST_DOWN_TO_GO, TOUCHDOWN_SECTION - field_position),
                                Bool(clock_ticking)
                            ),
                            state_prob,
                            false
                        )
                    )
                else
                    # Short 4th down
                    if state.down == 4
                        push!(
                            outcome_space,
                            (
                                State(
                                    state.seconds_remaining - play_length,
                                    -state.score_diff,
                                    reverse(state.timeouts_remaining),
                                    flip_field(field_position),
                                    FIRST_DOWN,
                                    min(FIRST_DOWN_TO_GO, TOUCHDOWN_SECTION - flip_field(field_position)),
                                    Bool(clock_ticking)
                                ),
                                state_prob,
                                true
                            )
                        )
                    else
                        # Short non-4th down
                        push!(
                            outcome_space,
                            (
                                State(
                                    state.seconds_remaining - play_length,
                                    state.score_diff,
                                    state.timeouts_remaining,
                                    field_position,
                                    FIRST_DOWN,
                                    min(30, state.ball_section + state.first_down_dist - field_position),
                                    Bool(clock_ticking)
                                ),
                                state_prob,
                                false
                            )
                        )
                    end
                end
            end
            # Break out if end of game play
            if play_length >= state.seconds_remaining
                break 
            end
        end
    end
    return outcome_space
end
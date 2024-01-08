"""
Calculates the expected value of punting

Parameters:
- State space

Very simple implementation. Doesn't account for any state factors.
Finds transition probs by creating a normal distrubtion fitted to all punts. 
"""
function punt_value_calc(
    current_state::State,
    optimal_value::Union{Nothing,Float64},
    seconds_cutoff::Int
)::Union{Nothing,Float64}
    # Assume only punt on 4th down
    if current_state.down != 4 || current_state.ball_section == TOUCHDOWN_SECTION - 1
        return nothing
    end
    # Initialise values
    punt_val = 0
    prob_remaining = 1

    # Get Punt probabilities
    probabilities = filter(row ->
            (row[:"Punt Section"] == current_state.ball_section),
        punt_df
    )

    # Calculate best case scenario (on opponent 1 yard line)
    best_case_state_value = 0

    best_case_yards_gained = TOUCHDOWN_SECTION - current_state.ball_section - 1
    best_case_prob = probabilities[1, Symbol("T-$(best_case_yards_gained)")]
    best_case_time_probs = filter(row ->
            (row[:"Yards Gained"] == best_case_yards_gained),
        time_punt_df
    )
    if current_state.seconds_remaining <= MAX_PUNT_DURATION
        best_case_end_game_prob = 1
    end
    for seconds in MIN_PUNT_DURATION:MAX_PUNT_DURATION
        if size(best_case_time_probs, 1) > 1
            time_prob = best_case_time_probs[1, Symbol("$(seconds) secs")]
        else
            if seconds == floor((MIN_PUNT_DURATION + MAX_PUNT_DURATION) / 2)
                time_prob = 1
            else
                time_prob = 0
            end
        end
        #if time_prob > TIME_PROB_TOL || seconds == current_state.seconds_remaining
        next_state = State(
            current_state.seconds_remaining - seconds,
            -current_state.score_diff,
            reverse(current_state.timeouts_remaining),
            1, # Best case is other team on 1 yard line
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        )
        punt_time_value = -state_value_calc_LDFS(next_state, seconds_cutoff, false, "")[1]
        if current_state.seconds_remaining <= seconds
            best_case_state_value += best_case_end_game_prob * punt_time_value
            break
        else
            best_case_state_value += time_prob * punt_time_value
        end
        #end
        if current_state.seconds_remaining <= MAX_PUNT_DURATION
            best_case_end_game_prob -= time_prob
        end
    end
    punt_val += best_case_prob * best_case_state_value
    prob_remaining -= best_case_prob

    for end_section in FIELD_SECTIONS
        # Already calculated best case (offensive team's 99 yards line)
        if end_section == 99
            continue
        end
        # Skip scoring of punt
        if end_section == TOUCHDOWN_SECTION
            continue
        end
        time_probs = filter(row ->
                (row[:"Yards Gained"] == end_section - current_state.ball_section),
            time_punt_df
        )
        # Initialise game ending play duration 
        if current_state.seconds_remaining <= MAX_PUNT_DURATION
            game_end_duration_prob = 1
        end
        # Handle return TD
        if end_section == TOUCHDOWN_CONCEEDED_SECTION
            end_section_prob = probabilities[1, Symbol("Def Endzone")]
            if end_section_prob > PROB_TOL
                for seconds in MIN_PUNT_DURATION:MAX_PUNT_DURATION
                    # Get time prob
                    if size(time_probs, 1) > 0
                        time_prob = time_probs[1, Symbol("$(seconds) secs")]
                    else
                        if seconds == floor((MIN_PUNT_DURATION + MAX_PUNT_DURATION) / 2)
                            time_prob = 1
                        else
                            time_prob = 0
                        end
                    end
                    #if time_prob > TIME_PROB_TOL || seconds == current_state.seconds_remaining
                    next_state = State(
                        current_state.seconds_remaining - seconds,
                        current_state.score_diff - TOUCHDOWN_SCORE,
                        current_state.timeouts_remaining,
                        TOUCHBACK_SECTION,
                        FIRST_DOWN,
                        FIRST_DOWN_TO_GO,
                        false, # Clock ticking handling. Need data
                    )
                    punt_time_value = state_value_calc_LDFS(next_state, seconds_cutoff, false, "")[1]
                    if current_state.seconds_remaining <= seconds
                        punt_val += end_section_prob * game_end_duration_prob * punt_time_value
                        prob_remaining -= end_section_prob * game_end_duration_prob
                    else
                        punt_val += end_section_prob * time_prob * punt_time_value
                        prob_remaining -= end_section_prob * time_prob
                    end
                    # Check for optimality
                    if optimal_value !== nothing && punt_val + prob_remaining * best_case_state_value < optimal_value
                        return nothing
                    end
                    #end
                    # Update end of game prob remaining
                    if current_state.seconds_remaining <= MAX_PUNT_DURATION
                        game_end_duration_prob -= time_prob
                    end
                end
            end
            # Handle all other return
        else
            # Get the probability
            col_name = Symbol("T-$(end_section)")
            end_section_prob = probabilities[1, col_name]
            if end_section_prob == 1
                continue # TODO: Found an error (9 yard has prob of 1?). This skips but need to debug 
            end

            if end_section_prob > PROB_TOL
                for seconds in MIN_PUNT_DURATION:MAX_PUNT_DURATION
                    # Get time prob
                    if size(time_probs, 1) > 1
                        time_prob = time_probs[1, Symbol("$(seconds) secs")]
                    else
                        if seconds == floor((MIN_PUNT_DURATION + MAX_PUNT_DURATION) / 2)
                            time_prob = 1
                        else
                            time_prob = 0
                        end
                    end
                    #if time_prob > TIME_PROB_TOL || seconds == current_state.seconds_remaining
                    next_state = State(
                        current_state.seconds_remaining - seconds,
                        -current_state.score_diff,
                        current_state.timeouts_remaining,
                        end_section,
                        FIRST_DOWN,
                        FIRST_DOWN_TO_GO,
                        false
                    )
                    punt_time_val = -state_value_calc_LDFS(next_state, seconds_cutoff, false, "")[1]
                    if current_state.seconds_remaining <= seconds
                        punt_val += end_section_prob * game_end_duration_prob * punt_time_val
                        prob_remaining -= end_section_prob * game_end_duration_prob
                    else
                        punt_val += end_section_prob * time_prob * punt_time_val
                        prob_remaining -= end_section_prob * time_prob
                    end
                    # Check if can still be optimal
                    if optimal_value !== nothing && punt_val + prob_remaining * best_case_state_value < optimal_value
                        return nothing
                    end
                    #end
                    # Update end game duration prob
                    if current_state.seconds_remaining <= seconds
                        game_end_duration_prob -= time_prob
                    end
                end
            end
        end
    end
    return punt_val
end
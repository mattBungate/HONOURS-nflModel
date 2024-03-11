

function hurried_play_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{PlayState,KickoffState,ConversionState}, Float64, Int, Bool}} # State, prob, reward, change possession
    # TODO: could have different stats fed into this function
    return play_outcome_space(state, 0)
end

function delayed_play_outcome_space(
    state::PlayState
)::Vector{Tuple{Union{ConversionState,KickoffState,PlayState}, Float64, Int, Bool}} # State, prob, reward, change possession
    # TODO: could have different stats fed into the play_outcome_space function
    return play_outcome_space(state, 1)
end

function play_outcome_space(
    state::PlayState,
    delayed::Int
)::Vector{Tuple{Union{PlayState,KickoffState,ConversionState}, Float64, Int, Bool}} # State, prob, reward, change possession
    # Invalid action
    
    # Domain knowledge

    """ Outcome space """
    outcome_space = Vector{Tuple{Union{PlayState,KickoffState,ConversionState}, Float64, Int, Bool}}()
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
                ConversionState(
                    state.seconds_remaining - play_length,
                    reverse(state.timeouts_remaining)
                ),
                state_prob,
                TOUCHDOWN_SCORE,
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
                ConversionState(
                    state.seconds_remaining - play_length,
                    reverse(state.timeouts_remaining),
                ),
                state_prob,
                -TOUCHDOWN_SCORE,
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
                            PlayState(
                                state.seconds_remaining - play_length,
                                state.timeouts_remaining,
                                field_position,
                                FIRST_DOWN,
                                min(FIRST_DOWN_TO_GO, TOUCHDOWN_SECTION - field_position),
                                Bool(clock_ticking)
                            ),
                            state_prob,
                            0,
                            false
                        )
                    )
                else
                    # Short 4th down
                    if state.down == 4
                        push!(
                            outcome_space,
                            (
                                PlayState(
                                    state.seconds_remaining - play_length,
                                    reverse(state.timeouts_remaining),
                                    flip_field(field_position),
                                    FIRST_DOWN,
                                    min(FIRST_DOWN_TO_GO, TOUCHDOWN_SECTION - flip_field(field_position)),
                                    Bool(clock_ticking)
                                ),
                                state_prob,
                                0,
                                true
                            )
                        )
                    else
                        # Short non-4th down
                        push!(
                            outcome_space,
                            (
                                PlayState(
                                    state.seconds_remaining - play_length,
                                    state.timeouts_remaining,
                                    field_position,
                                    FIRST_DOWN,
                                    min(state.ball_section + state.first_down_dist - field_position, 30),
                                    Bool(clock_ticking)
                                ),
                                state_prob,
                                0,
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
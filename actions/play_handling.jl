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
        next_state = State(
            current_state.plays_remaining - 1, # Change this to seconds. Need data
            -(current_state.score_diff - TOUCHDOWN_SCORE),
            current_state.timeouts_remaining,
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
            false,
            current_state.clock_ticking, # Look into this. Need data (I assume)
            current_state.is_first_half
        )
        play_value += pick_six_prob * -state_value_calc(
            next_state
        )[1]
    end

    # Non scoring scenarios
    for section in NON_SCORING_FIELD_SECTIONS
        col_name = Symbol("T-$section")
        transition_prob = probabilities[1, col_name]
        # Transitions
        if transition_prob > 0
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
                    timeouts_remaining = (current_state.timeouts_remaining[1] - 1, current_state.timeouts_remaining[2])
                else
                    timeouts_remaining = current_state.timeouts_remaining
                end
                next_state = State(
                    current_state.plays_remaining - 1, # Need to change this to seconds. Need data
                    current_state.score_diff,
                    timeouts_remaining, # need to figure this one out
                    section,
                    next_down, # Look into how I did this next_down crap
                    next_down == 1 ? section + FIRST_DOWN_TO_GO : current_state.first_down_section, # This is probs wrong. Set up for 10yard thingo
                    timeout_called_planned, # timeout called
                    current_state.clock_ticking, # Look at this. Will probs need data to do this properly
                    current_state.is_first_half
                )
                play_value += transition_prob * state_value_calc(
                    next_state
                )[1]
            else
                timeouts_remaining = current_state.timeouts_remaining
                if timeout_called_planned
                    timeouts_remaining[1] -= 1
                end
                # 4th down handling
                if section >= current_state.first_down_section
                    # Made it
                    next_state = State(
                        current_state.plays_remaining - 1, # Change this to seconds. Need data
                        current_state.score_diff,
                        timeouts_remaining, # Figure out timeout handling
                        section, # Probs rename
                        FIRST_DOWN,
                        section + FIRST_DOWN_TO_GO, # 
                        timeout_called_planned,
                        current_state.clock_ticking, # Look into this. Need data (I assume)
                        current_state.is_first_half
                    )
                    play_value += transition_prob * state_value_calc(
                        next_state
                    )[1]
                else
                    # Short of 1st down
                    next_state = State(
                        current_state.plays_remaining - 1, # Change this to seconds. Need data
                        -current_state.score_diff,
                        current_state.timeouts_remaining, # Figure out timeout handling
                        TOUCHDOWN_SECTION - section,
                        FIRST_DOWN,
                        TOUCHDOWN_SECTION - section + FIRST_DOWN_TO_GO,
                        false,
                        false, # Clock stops during turnover in last 2 mins of 1st half and 5mins of 2nd half. All tests are within this range. 
                        current_state.is_first_half
                    )
                    play_value += transition_prob * -state_value_calc(
                        next_state
                    )[1]
                end
            end

        end
    end

    # Touchdown scenario
    td_prob = probabilities[1, :"Off Endzone"]
    if td_prob > 0
        next_state = State(
            current_state.plays_remaining - 1, # Change this to seconds. Need data
            -(current_state.score_diff + TOUCHDOWN_SECTION),
            reverse(current_state.timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            TOUCHBACK_SECTION + FIRST_DOWN_TO_GO,
            false,
            false, # We assume fair catch for kickoff.
            current_state.is_first_half
        )
        play_value += td_prob * -state_value_calc(
            next_state
        )[1]
    end
    return play_value
end
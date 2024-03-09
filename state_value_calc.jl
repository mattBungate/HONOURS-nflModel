"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
state: State space currently occupied.
"""
function state_value_calc(
    state::Union{PlayState, ConversionState, KickoffState},
    is_root::Bool
)
    # Check conversion
    if isa(state, ConversionState)
        return conversion_decision(state)
    end

    # Base cases
    if state.seconds_remaining <= 0
        return evaluate_game(state)
    end

    # Play Decision 
    if isa(state, PlayState)
        return play_decision(state, is_root)
    end

    # Kickoff Decision
    if isa(state, KickoffState)
        return kickoff_decision(state)
    end

    throw(ArgumentError("State was not conversion, play or kickoff: $(state)"))
end

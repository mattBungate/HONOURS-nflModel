"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
state: State space currently occupied.
"""
function state_value_calc(
    state::Union{PlayState, KickoffState, ConversionState},
    is_root::Bool
)
    if isa(state, ConversionState)
        return conversion_decision(state)
    end

    if state.seconds_remaining <= 0
        return 0
    end
    
    if isa(state, PlayState)
        return play_decision(state, is_root)
    end

    if isa(state, KickoffState)
        return kickoff_decision(state)
    end

    throw(ArgumentError("State was not conversion, play or kickoff: $(state)"))

end

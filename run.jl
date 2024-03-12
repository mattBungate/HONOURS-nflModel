using DataFrames
using CSV
using Distributions
#using Base: @sync, @async, Task

#using Base.Threads: Atomic

include("util/state.jl")
include("util/constants.jl")
include("util/util.jl")
include("plays/actions/field_goal_handling.jl")
include("plays/actions/kneel_handling.jl")
include("plays/actions/play_type_handling.jl")
include("plays/actions/punt_handling.jl")
include("plays/actions/spike_handling.jl")
include("plays/actions/timeout_handling.jl")
include("plays/play_handling.jl")
include("conversions/consts.jl")
include("conversions/actions/one_point_handling.jl")
include("conversions/actions/two_point_handling.jl")
include("conversions/conversion_handling.jl")
include("kickoffs/consts.jl")
include("kickoffs/actions/onside_kick_handling.jl")
include("kickoffs/actions/returnable_kick_handling.jl")
include("kickoffs/actions/forced_touchback_handling.jl")
include("kickoffs/kickoff_handling.jl")
#include("tests/real_tests.jl")
include("tests/run_tests.jl")
include("state_value_calc.jl")
include("interpolation.jl")
include("evaluate_game.jl")
include("order_actions.jl")

PLAY_ACTIONS = ["Kneel", "Punt", "Delayed Play", "Delayed Timeout", "Field Goal", "Timeout", "Hurried Play", "Spike"]
GENERATE_PLAY_OUTCOME_SPACE = Dict{String, Function}(
    "Kneel" => kneel_outcome_space,
    "Timeout" => immediate_timeout_outcome_space,
    "Delayed Timeout" => delayed_timeout_outcome_space,
    "Field Goal" => field_goal_outcome_space,
    "Punt" => punt_outcome_space,
    "Hurried Play" => hurried_play_outcome_space,
    "Delayed Play" => delayed_play_outcome_space,
    "Spike" => spike_outcome_space
)
CONVERSION_ACTIONS = ["Extra point", "Two point"]
GENERATE_CONVERSION_OUTCOME_SPACE = Dict{String, Function}(
    "Extra point" => one_point_outcome_space,
    "Two point" => two_point_outcome_space
)
KICKOFF_ACTIONS = ["Onside kick", "Returnable kick", "Forced touchback"]
GENERATE_KICKOFF_OUTCOME_SPACE = Dict{String, Function}(
    "Onside kick" => onside_kick_outcome_space,
    "Returnable kick" => returnable_kick_outcome_space,
    "Forced touchback" => forced_touchback_outcome_space
)

# Order from easiest to hardest: 4, 8, 11, 10, 6, 7
#test_case = REAL_TESTS[4]
#test_state = test_case[1]
#test_action = test_case[2]

#const starting_score_diff = test_state.score_diff
#const SCORE_BOUND = 14


function run_with_timeout(func::Function, timeout_seconds::Int, state::Union{PlayState, KickoffState, ConversionState})
    result = Ref{Any}((-Inf, "Timed out", -1))
    done = Channel{Bool}(1) # Channel to signal task completion
    stop_signal = Atomic{Bool}(false) # Shared signal to indicate stopping

    @sync begin
        @async begin
            try
                start_time = time()
                action_val, optimal_action = func(state, true, "", stop_signal) # func needs to accept stop_signal and check it
                end_time = time()
                if !stop_signal[]
                    result[] = (action_val, optimal_action, end_time - start_time) # Store result and execution time
                end
                # Signal completion by closing the channel, which also signals the timer task to stop waiting
                close(done)
            catch e
                println("Task interrupted or an error occurred: $e")
            end
        end

        @async begin
            sleep(timeout_seconds)
            if isopen(done) # Check if the channel is still open before attempting to signal
                stop_signal[] = true # Signal the function to stop
                try
                    put!(done, false) # Signal timeout, if the channel is still open
                catch e
                    # Channel might be closed if function completed just before timeout
                end
            end
        end
    end
    
    # Wait for either completion or timeout, but due to channel being closed by the func task,
    # this will immediately proceed if func finishes first.
    if isopen(done)
        take!(done) # This will only block if the done channel is still open and has not been taken or closed.
    end
    
    return result[]
end

"""
State:
- Seconds remaining
- Score differential
- Timeouts remaining
- Ball position
- Down
- First down dist
- Clock ticking
"""
test_kickoff("first_half/interpolation")  

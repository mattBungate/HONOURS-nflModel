using DataFrames
using CSV
using Distributions

include("util/state.jl")
include("util/constants.jl")
include("actions/punt_handling.jl")
include("actions/field_goal_handling.jl")
include("actions/play_handling.jl")
include("actions/kneel_handling.jl")

"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
state: State space currently occupied.
"""
function state_value_calc(
    state::State
)

    # Base cases
    if state.plays_remaining <= 0
        # 1st half: maximise points
        if state.is_first_half
            return state.score_diff, "End 1st half"
        end
        # 2nd half: maximise winning
        if state.score_diff > 0
            return 1, "End Game"
        elseif score_diff == 0
            return 0, "End Game"
        else
            return -1, "End Game"
        end
    end

    # Check if state is cached
    if haskey(state_values, state)
        return state_values[state]
    end

    # Initialise arrays to store action space and associated values
    action_values = Dict{String,Float64}()

    # Iterate through each action in action_space
    for action in action_space
        # Calculate action value
        if action == "Timeout Play"
            action_value = action_functions[action](state, true) # Clean this up
        elseif action == "No Timeout Play"
            action_value = action_functions[action](state, false) # Clean this up
        else
            action_value = action_functions[action](state)
        end
        # Store action value if value returned        
        if action_value !== nothing
            action_values[action] = action_value
        end
    end

    # Find optimal action
    optimal_action = findmax(action_values)

    state_values[state] = optimal_action

    return optimal_action
end

# Data
play_df = CSV.File("processed_data/stats_1_yard_sections.csv") |> DataFrame
field_goal_df = CSV.File("processed_data/field_goal_stats.csv") |> DataFrame
punt_df = CSV.File("processed_data/punt_probs.csv") |> DataFrame

# Inputs
plays_remaining = 3
score_diff = 0
timeouts_remaining = (1, 0)
ball_position = TOUCHBACK_SECTION
down = 1
first_down_dist = TOUCHBACK_SECTION + FIRST_DOWN_TO_GO
timeout_called = false
clock_ticking = false
is_first_half = true

initial_state = State(
    plays_remaining,
    score_diff,
    timeouts_remaining,
    ball_position,
    down,
    first_down_dist,
    timeout_called,
    clock_ticking,
    is_first_half
)

action_space = ["Kneel", "Field Goal", "Punt", "No Timeout Play", "Timeout Play"]

action_functions = Dict{String,Function}(
    "Kneel" => kneel_value_calc,
    "Field Goal" => field_goal_value_calc,
    "Punt" => punt_value_calc,
    "No Timeout Play" => play_value_calc,
    "Timeout Play" => play_value_calc
)

state_values = Dict{State,Tuple{Float64,String}}()

println("Plays remaining: $plays_remaining")
@time state_value = state_value_calc(
    initial_state
)
println(length(state_values))

state_value_rounded = round(state_value[1], digits=2)
play_type = state_value[2]

if Bool(is_first_half)
    println("\n\nThe expected score differential for this position if played optimally is $state_value_rounded")
else
    println("\n\nThere is a $state_value_rounded % chance of winning in this position")
end
println("Optimal play: $play_type\n\n")

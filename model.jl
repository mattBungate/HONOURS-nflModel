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
function state_value(
    state::State
)
    # Base cases
    if state.plays_remaining <= 0
        if Bool(state.is_first_half)
            # 1st half: Maximise points
            return state.score_diff
        else
            # 2nd half: Maximise win chance
            if state.score_diff > 0
                return 100
            elseif state.score_diff == 0
                return 50
            else
                return 0
            end
        end
    end

    # Check score to see if we want to be risky or risk-averse
    action_space_vals = Dict{String,Float64}()

    if state.score_diff > 0
        actions_ordered = actions
    else
        actions_ordered = reverse(actions)
    end

    optimal_value::Union{Nothing,Float64} = nothing

    for action in actions_ordered
        if action == "Play Timeout"
            action_value = action_funcs[action](state, true, optimal_value)
        elseif action == "Play No Timeout"
            action_value = action_funcs[action](state, false, optimal_value)
        else
            action_value = action_funcs[action](state, optimal_value)
        end
        if action_value !== nothing
            action_space_vals[action] = action_value
            if optimal_value === nothing
                optimal_value = action_value
            elseif action_value > optimal_value
                optimal_value = action_value
            end
        end
    end

    # Get optimal
    optimal_decision = findmax(action_space_vals)

    # Store solution
    state_values[state] = optimal_decision

    return optimal_decision
end

# Data
const transition_df = CSV.File("processed_data/stats_$(SECTION_WIDTH)_yard_sections.csv") |> DataFrame
const field_goal_df = CSV.File("processed_data/field_goal_stats.csv") |> DataFrame
const punt_df = CSV.File("processed_data/punt_stats.csv") |> DataFrame
const punt_dist = Normal(punt_df[1, :"Mean"], punt_df[1, :"Std"])

# Actions ordered in terms of risk (least to most)
const actions = ["Kneel", "Punt", "Field Goal", "Play Timeout", "Play No Timeout"]

const action_funcs = Dict{String,Function}(
    "Kneel" => kneel_calc,
    "Punt" => punt_value,
    "Field Goal" => field_goal_attempt,
    "Play Timeout" => play_value,
    "Play No Timeout" => play_value
)

# Inputs
const plays_remaining = 4
const score_diff = -1
const timeouts_remaining = 3
const ball_position = TOUCHBACK_SECTION
const down = 1
const first_down_dist = TOUCHBACK_SECTION + FIRST_DOWN_TO_GO
const offense_has_ball = 1
const is_first_half = 0

const initial_state = State(
    plays_remaining,
    score_diff,
    timeouts_remaining,
    ball_position,
    down,
    first_down_dist,
    offense_has_ball,
    is_first_half
)

state_values = Dict{State,Tuple{Float64,String}}()

println("Plays remaining: $plays_remaining")
@time play_value_calc = state_value(
    initial_state
)
println(length(state_values))

play_value_rounded = round(play_value_calc[1], digits=2)
play_type = play_value_calc[2]

if Bool(is_first_half)
    println("\n\nThe expected score differential for this position if played optimally is $play_value_rounded")
else
    println("\n\nThere is a $play_value_rounded % chance of winning in this position")
end
println("Optimal play: $play_type\n\n")

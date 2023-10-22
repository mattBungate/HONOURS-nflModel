using DataFrames
using CSV
using Distributions

include("util/state.jl")
include("util/constants.jl")
include("util/util.jl")
include("actions/punt_handling.jl")
include("actions/field_goal_handling.jl")
include("actions/play_handling.jl")
include("actions/kneel_handling.jl")
include("actions/spike_handling.jl")
include("actions/timeout_handling.jl")
include("tests/real_tests.jl")

"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
state: State space currently occupied.
"""
function state_value_calc(
    state::State
)
    global state_value_calc_calls
    state_value_calc_calls += 1
    if mod(state_value_calc_calls, FUNCTION_CALL_PRINT_INTERVAL) == 0
        println("Function called $(state_value_calc_calls/1000000)M times")
    end
    # Base cases
    if state.seconds_remaining <= 0
        # 1st half: maximise points
        if state.is_first_half
            return state.score_diff, "End 1st half"
        end
        # 2nd half: maximise winning
        if state.score_diff > 0
            return 1, "End Game"
        elseif state.score_diff == 0
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

    # Order the actions
    if state.score_diff > 0
        action_space_ordered = action_space
    else
        action_space_ordered = reverse(action_space)
    end

    optimal_value::Union{Nothing,Float64} = nothing

    # Iterate through each action in action_space
    for action in action_space_ordered
        #println("Checking play: $action")
        # Calculate action value
        if isempty(action_values)
            action_value = action_functions[action](state, nothing)
        else
            action_value = action_functions[action](state, findmax(action_values))
        end
        # Print info on whats going on
        if state.seconds_remaining == 5
            #println("$action | $action_value | $optimal_value")
        end
        # Store action value if value returned        
        if action_value !== nothing
            action_values[action] = action_value
            if optimal_value === nothing || optimal_value < action_value
                #println("Replacing optimal value $(optimal_value) with $(action_value)")
                optimal_value = action_value
                if state.seconds_remaining == 5
                    #println("New optimal value from $action: $optimal_value")
                end
            end
        else
            action_values[action] = -2
        end
    end

    # Find optimal action
    optimal_action = findmax(action_values)

    # Store all states
    state_values[state] = optimal_action

    return (optimal_action[1], optimal_action[2], action_values)
end

global state_value_calc_calls = 0

# Data
play_df = CSV.File("processed_data/stats_1_yard_sections.csv") |> DataFrame # TODO: Missing data for last 10 yards with timeout called
field_goal_df = CSV.File("processed_data/field_goal_stats.csv") |> DataFrame
punt_df = CSV.File("processed_data/punt_probs.csv") |> DataFrame
time_df = CSV.File("processed_data/time_stats_2022.csv") |> DataFrame
time_punt_df = CSV.File("processed_data/punt_time_stats_2022.csv") |> DataFrame
time_field_goal_df = CSV.File("processed_data/field_goal_time_2022.csv") |> DataFrame

# Fill in missing data with dummy data
# TODO: Fix data (90-99 yards touchdown called, 4th down)
# TODO: sum -1 for dodgy dummy data
for section in NON_SCORING_FIELD_SECTIONS
    for down in POSSIBLE_DOWNS
        for timeout_called in 0:1
            filtered_df = filter(row ->
                    (row[:"Down"] == down) &
                    (row[:"Position"] == section) &
                    (row[:"Timeout Used"] == timeout_called),
                play_df
            )
            if ismissing(filtered_df[1, :"Def Endzone"])
                # Fill in with dummy data
                # 0.5 staying in the same spot. 0.5 of scoring
                row_idx = findfirst((play_df."Down" .== down) .& (play_df."Position" .== section) .& (play_df."Timeout Used" .== timeout_called))
                df_entry = [row_idx, down, section, timeout_called, 0]
                df_entry = convert(Vector{Union{Float64,Nothing}}, df_entry)
                for end_section in NON_SCORING_FIELD_SECTIONS
                    if end_section == section
                        push!(df_entry, 0.5)
                    else
                        push!(df_entry, 0)
                    end
                end
                # Push 0.5 chance of scoring td
                push!(df_entry, 0.5)
                # Put 'sum' value
                push!(df_entry, -1)

                # Change DataFrame
                play_df[row_idx, :] = df_entry
                #play_df[(play_df[:"Down"]==down)&&(play_df[:"Position"]==section)&&(play_df[:"Timeout_called"]==timeout_called)] = df_entry
                #println("Changed $(down) $(section) $(timeout_called)")
                changed_row = filter(row ->
                        (row[:"Down"] == down) &
                        (row[:"Position"] == section) &
                        (row[:"Timeout Used"] == timeout_called),
                    play_df
                )
            end
        end
    end
end

# Inputs
seconds_remaining = 1
score_diff = -1
timeouts_remaining = (3, 3)
ball_position = 50 + TOUCHBACK_SECTION
down = 4
first_down_dist = 50 + TOUCHBACK_SECTION + FIRST_DOWN_TO_GO
timeout_called = false
clock_ticking = false
is_first_half = false
initial_state = State(
    seconds_remaining,
    score_diff,
    timeouts_remaining,
    ball_position,
    down,
    first_down_dist,
    timeout_called,
    clock_ticking,
    is_first_half
)

action_space = ["Kneel", "Punt", "Timeout", "Delayed Timeout", "Field Goal", "Play", "Spike"]
action_functions = Dict{String,Function}(
    "Kneel" => kneel_value_calc,
    "Timeout" => immediate_timeout_value_calc,
    "Delayed Timeout" => delayed_timeout_value_calc,
    "Field Goal" => field_goal_value_calc,
    "Punt" => punt_value_calc,
    "Play" => play_value_calc,
    "Spike" => spike_value_calc
)

state_values = Dict{State,Tuple{Float64,String}}()

state_val_calculation = state_value_calc(initial_state)
println(state_val_calculation)



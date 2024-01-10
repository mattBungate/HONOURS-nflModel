using DataFrames
using CSV
using Distributions

include("util/state.jl")
include("actions/punt_handling.jl")
include("actions/field_goal_handling.jl")
include("actions/play_handling.jl")
include("actions/kneel_handling.jl")
include("actions/spike_handling.jl")
include("actions/timeout_handling.jl")
include("util/constants.jl")
include("util/util.jl")
include("tests/real_tests.jl")
include("tests/run_tests.jl")
include("state_value_calc.jl")
include("interpolation.jl")
include("evaluate_game.jl")

"""
function solve_MCTS(
    initial_state::State
)
    while true
        try 
            # 1. Selection (using formula)
            # 2. Expansion (Randomly choose an outcome from outcome space. If already explored continue)
            # 3. Simulation (Create node for new state. Randomly choose action. Randomly choose outcome from each action. Additionally can "inform" the play)
            # 4. Backpropogation (Iterate through all parent nodes recursively, incrementing total score and times visited)
        catch e
            if isa(e, InterruptException)
                # Sort through all the actions and see what is the best action
    end
end
"""

global state_value_calc_calls = 0
global interpolated_value_calls = 0

# Data
play_df = CSV.File("processed_data/stats_1_yard_sections.csv") |> DataFrame             # TODO: Missing data for last 10 yards with timeout called
field_goal_df = CSV.File("processed_data/field_goal_stats.csv") |> DataFrame            # TODO: More accurate data (yard instead of 10 yard)
punt_df = CSV.File("processed_data/punt_probs.csv") |> DataFrame
time_df = CSV.File("processed_data/time_stats_2022.csv") |> DataFrame                   # TODO: Seperate game clock time from play time
time_punt_df = CSV.File("processed_data/punt_time_stats_2022.csv") |> DataFrame
time_field_goal_df = CSV.File("processed_data/field_goal_time_2022.csv") |> DataFrame

# Fill in missing data with dummy data
# TODO: Fix data (90-99 yards touchdown called, 4th down) | sum=-1 for dodgy dummy data
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



function run_with_timeout(
    func::Function, 
    state::State)
    @sync begin
        task = @async begin
            try
                func(state)
            catch e
                println("Task interrupted or an error occurred: $e")
            finally
                println("We are now exiting the @async block")
                yield()
            end
        end
        sleep(timeout_seconds)
        schedule(task, InterruptException(), error=true)
    end
    println("Exiting improved_run_with_timeout")
end


const IS_FIRST_HALF = false # TODO: Have a way to have this as an input

# Order from easiest to hardest: 4, 8, 11, 10, 6, 7
test_case = REAL_TESTS[4]
test_state = test_case[1]
test_action = test_case[2]
#println(REAL_TEST_DESCRIPTION[11])
dummy_test_state = State(
    test_state.seconds_remaining,
    test_state.score_diff,
    (0, 3),
    60,
    4,
    test_state.first_down_dist,
    test_state.clock_ticking
)

const starting_score_diff = test_state.score_diff
const SCORE_BOUND = 14

println("Testing: $dummy_test_state")
delayed_states = delayed_play_children(dummy_test_state)
println("Number of children for delayed play: $(length(delayed_states))")
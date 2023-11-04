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
include("tests/run_tests.jl")
include("state_value_calc.jl")
include("interpolation.jl")

function solve(
    initial_state::State
)
    return state_value_calc(initial_state)
end


global state_value_calc_calls = 0
global interpolated_value_calls = 0

# Data
play_df = CSV.File("processed_data/stats_1_yard_sections.csv") |> DataFrame # TODO: Missing data for last 10 yards with timeout called
field_goal_df = CSV.File("processed_data/field_goal_stats.csv") |> DataFrame # TODO: More accurate data (yard instead of 10 yard)
punt_df = CSV.File("processed_data/punt_probs.csv") |> DataFrame
time_df = CSV.File("processed_data/time_stats_2022.csv") |> DataFrame # TODO: Seperate game clock time from play time
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

const INTERPOLATE_POSITION = true
const INTERPOLATE_FIRST_DOWN = true

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
test_case = REAL_TESTS[4]
test_state = test_case[1]
test_action = test_case[2]
println(REAL_TEST_DESCRIPTION[4])
dummy_test_state = State(
    10,
    test_state.score_diff,
    test_state.timeouts_remaining,
    test_state.ball_section,
    test_state.down,
    test_state.first_down_dist,
    test_state.timeout_called,
    test_state.clock_ticking,
    test_state.is_first_half
)
println("Testing: $test_state")
@time solved_test_case = solve(
    test_state
)

println("States stored: $(length(state_values))")
println("Interpolated states: $(interpolated_value_calls)")
println("Function calls: $state_value_calc_calls")
println("Optimal action: $(solved_test_case[2])")
println("Action value: $(solved_test_case[1])")
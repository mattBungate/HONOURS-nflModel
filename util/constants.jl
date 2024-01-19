"""
All the constants that are used throughout this codebase
"""

using DataFrames
using CSV
using Distributions

const VERSION_NUM = "V_4_0_7"

const action_space = [
    "Kneel", 
    "Punt", 
    "Delayed Play", 
    "Delayed Timeout", 
    "Field Goal", 
    "Timeout", 
    "Hurried Play", 
    "Spike"
]
const action_children_functions = Dict{String,Function}(
    "Kneel" => kneel_children,
    "Timeout" => immediate_timeout_children,
    "Delayed Timeout" => delayed_timeout_children,
    "Field Goal" => field_goal_children,
    "Punt" => punt_children,
    "Hurried Play" => hurried_play_children,
    "Delayed Play" => delayed_play_children,
    "Spike" => spike_children
)
const select_action_child_functions = Dict{String, Function}(
    "Kneel" => select_kneel_child,
    "Timeout" => select_immediate_timeout_child,
    "Delayed Timeout" => select_delayed_timeout_child,
    "Field Goal" => select_field_goal_child,
    "Punt" => select_punt_child,
    "Hurried Play" => select_hurried_play_child,
    "Delayed Play" => select_delayed_play_child,
    "Spike" => select_spike_child
)

const IS_FIRST_HALF = false # TODO: Have a way to have this as an input

const SECTION_WIDTH = 1                                     # Width of the sections

const FIELD_SECTIONS = [i for i in 0:100]                   # All field sections
const NON_SCORING_FIELD_SECTIONS = [i for i in 1:99]        # Field sections that aren't end zones
const TOUCHBACK_SECTION = 25                                # Touchback is 25yrd line (section 3)
const TOUCHDOWN_SECTION = 100                               # Scoring touchdown section
const TOUCHDOWN_CONCEEDED_SECTION = 0                       # Conceeding touchdown section
const FIELD_GOAL_MERCY_SECTION = 80                         # If a field goal inside this the ball is placed on the 25

const POSSIBLE_DOWNS = [1, 2, 3, 4]                         # All downs possible

const TOUCHDOWN_SCORE = 7                                   # Score of a touchdown
const FIELD_GOAL_SCORE = 3                                  # Score of a field goal

const FIRST_DOWN_TO_GO = 10                                 # Dist to first down if first down 
const FIRST_DOWN = 1                                        # For clarity

const PROB_TOL = 10e-4                                      # If prob is under its considered insignificant
const TIME_PROB_TOL = 10e-3

const MAX_PLAY_CLOCK_DURATION = 40                          # Time elapsed when Kneel action is taken

const FIELD_GOAL_CUTOFF = 50                                # Max distance a team will attempt a field goal from

const MIN_PLAY_LENGTH = 1                                   # Minimum duration of a play
const MAX_PLAY_LENGTH = 11                                  # Maximum duration of a play TODO: Fix this. this includes game clock. Need stats on how long the play is not just between each play

const MIN_FIELD_GOAL_DURATION = 3                           # Minimum duration of a field goal
const MAX_FIELD_GOAL_DURATION = 9                           # Maximum duration of a field goal

const MIN_PUNT_DURATION = 3                                 # Minimum duration of a punt
const MAX_PUNT_DURATION = 22                                # Maximum duraiton of a punt

const FUNCTION_CALL_PRINT_INTERVAL = 1e7                    # Frequency that the function called counter is printed

const INTERPOLATION_SIZE = 10
const MAX_SCORE = 72                                        # Max score considered by model (largest a team has ever scored)
const AUTO_WIN_SCORE = 22                                   # Score where we assume you automatically win (4+ score game)

const MAX_FIRST_DOWN = 30

const SAFETY_SCORE = 2

const MIN_TIME_TO_SCORE = 15


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

# Initialise seconds and ball sections to be calculated/interpolated
# TODO: Have a better way to set this up instead of hard coding array
"""
1 yard for 1-10 & 90-99
2 yard for 10-30 & 70-90
5 yard for 30-70
"""
#calculated_sections = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 35, 40, 45, 50, 55, 60, 65, 70, 72, 74, 76, 78, 80, 82, 84, 86, 88, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99]
#calculated_sections = [1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 13, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 87, 89, 91, 92, 93, 94, 95, 96, 97, 98, 99]
calculated_sections = [1, 3, 5, 10, 15, 20, 30, 40, 50, 60, 70, 80, 85, 90, 95, 97, 99]
println("Calculated ball positions: $(calculated_sections)")
# TODO: Have a better way to set this up instead of hard coding array
"""
1 second - 1-20 seconds
2 second - 20-90 seconds
5 second - 90+ seconds
"""
#calculated_first_down = [1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30]
calculated_first_down = [1, 3, 5, 10, 20, 30]
println("First down calculated: $(calculated_first_down)")
# Neighbours of sections
ball_pos_neighbours = Dict{Int,Tuple{Int,Int}}()
for section in NON_SCORING_FIELD_SECTIONS
    if !in(section, calculated_sections)
        # Find lower neighbour
        lower_neighbour = section - 1
        while !in(lower_neighbour, calculated_sections)
            lower_neighbour -= 1
        end
        # Find upper neighbour
        upper_neighbour = section + 1
        while !in(upper_neighbour, calculated_sections)
            upper_neighbour += 1
        end
        ball_pos_neighbours[section] = (lower_neighbour, upper_neighbour)
    end
end
# Neighbours of time
first_down_neighbours = Dict{Int,Tuple{Int,Int}}()
for first_down_dist in 1:30
    if !in(first_down_dist, calculated_first_down)
        # Find lower neighbour
        lower_neighbour = first_down_dist - 1
        while !in(lower_neighbour, calculated_first_down)
            lower_neighbour -= 1
        end
        # Find upper neighbour
        upper_neighbour = first_down_dist + 1
        while !in(upper_neighbour, calculated_first_down)
            upper_neighbour += 1
        end
        first_down_neighbours[first_down_dist] = (lower_neighbour, upper_neighbour)
    end
end
# Time values
seconds_calculated = [1, 2, 3, 5, 7, 9, 11, 13, 15, 20, 25, 30, 40, 50, 60, 80, 100, 120]
println("Seconds Calculated: $(seconds_calculated)")
println("Number of First down dist values: $(length(calculated_first_down))")
println("Number of ball positions calculated: $(length(calculated_sections))")
println("Number of secodns calculated: $(length(seconds_calculated))")
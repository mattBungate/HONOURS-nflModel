using DataFrames
using CSV
using Distributions

include("../util/state.jl")
include("../util/constants.jl")
include("../util/util.jl")

include("../actions/field_goal_handling.jl")
include("../actions/kneel_handling.jl")
include("../actions/play_handling.jl")
include("../actions/punt_handling.jl")
include("../actions/spike_handling.jl")
include("../actions/timeout_handling.jl")

include("../state_value_calc.jl")
include("../evaluate_game.jl")

include("unit_tests/outcome_space_tests.jl")

# TODO: Move this to appropriate spot. Just here for convenience and to compile
action_space = ["Kneel", "Punt", "Delayed Play", "Delayed Timeout", "Field Goal", "Timeout", "Hurried Play", "Spike"]
action_functions = Dict{String,Function}(
    "Kneel" => kneel_value_calc,
    "Timeout" => immediate_timeout_value_calc,
    "Delayed Timeout" => delayed_timeout_value_calc,
    "Field Goal" => field_goal_value_calc,
    "Punt" => punt_value_calc,
    "Hurried Play" => hurried_play_action_calc,
    "Delayed Play" => delayed_play_action_calc,
    "Spike" => spike_value_calc
)

generate_outcome_space = Dict{String, Function}(
    "Field Goal" => field_goal_outcome_space
)

"""
Unit testing for functions
"""

#test_field_goal_outcome_space_generation()
"""
IS_FIRST_HALF = false
field_goal_state = State(1, 0, (0,0), 75, 1, 10, false)
field_goal_value = calculate_action_value(field_goal_state, "Field Goal")
"""
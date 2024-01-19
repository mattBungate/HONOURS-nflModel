using DataFrames
using CSV
using Distributions
using Random

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
include("MCTS_functions/node.jl")
include("MCTS_functions/MCTS_helper.jl")


function solve_MCTS(
    initial_state::State,
    max_iters=100000::Int
)
    println("----Starting MCTS----")
    # Initialise vars
    current_iter = 0
    action = "" # only here so it can be accessed in catch block
    root_node = create_root(initial_state)

    while current_iter < max_iters
        current_iter += 1
        try 
            # 1. Selection (using formula)
            selected_state, leaf_node, change_possession, action, end_of_game = selection(root_node)
            if end_of_game
                # End of game - skip expansion & simulation. Only backpropogate
                game_result = evaluate_game(selected_state)
                root_node = backpropogation(
                    game_result,
                    change_possession,
                    leaf_node,
                    root_node
                )
            else
                # 2. Expansion (Randomly choose an outcome from outcome space. If already explored continue)
                expansion_node = expansion(
                    selected_state,
                    leaf_node,
                    change_possession,
                    action
                )
                # 3. Simulation (Create node for new state. Randomly choose action. Randomly choose outcome from each action. Additionally can "inform" the play)
                simulation_output = simulation(expansion_node.state, false)
                # 4. Backpropogation (Iterate through all parent nodes recursively, incrementing total score and times visited)
                root_node = backpropogation(
                    simulation_output[1],
                    simulation_output[2],
                    expansion_node,
                    root_node
                )
            end
        catch e
            println("\nIterations: $current_iter")
            if isa(e, InterruptException)
                # Sort through all the actions and see what is the best action
                println("Interrupt exception encountered")
                break    
            else
                println("Exploring $(action)")
                println("Encountered exception: $e")
                break
            end
        end
    end
    println("\n\n----Ending MCTS----\n\n")
    println()
    print_node_summary(root_node)
    println()
    print_node_action_stats(root_node)

    # Find the best action
    # for starters this will jsut be the best average
    # this could be flawed as a not promising action isn't explored a lot but could have a high score from chance/randomness
    # will likely need code to run simulations for actions with better scores but less iterations
    best_action = ""
    best_score = -Inf
    for (action, action_stats) in root_node.action_stats
        if action_stats[2] == 0
            continue
        end
        action_ave_score = action_stats[1] / action_stats[2]
        if action_ave_score > best_score
            best_action = action
            best_score = action_ave_score
        end
    end
    return best_action, best_score
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



# Order least to most seconds remaining: 
# 4, 8, 11, 10, 6, 7
test_case = REAL_TESTS[4]
test_state = test_case[1]
test_action = test_case[2]
dummy_test_state = State(
    test_state.seconds_remaining,
    -1,
    (0, 3),
    99,
    4,
    test_state.first_down_dist,
    test_state.clock_ticking
)

const starting_score_diff = test_state.score_diff
const SCORE_BOUND = 14
const RANDOM = false

if !RANDOM
    Random.seed!(123)
end
"""
println("Test state: $(test_state)")

start_time = time()
MCTS_output = solve_MCTS(test_state)
end_time = time()

println("Best action: (MCTS_output[1])")
println("Best action score: (MCTS_output[2])")
println("MCTS took (end_time - start_time)s")
"""

run_tests()
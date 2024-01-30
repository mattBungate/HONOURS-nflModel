

function solve_MCTS(
    initial_state::State,
    is_first_half::Bool,
    max_iters=100000::Int
)::Tuple{String, Float64, Float64, Int} # Action, Score, Time elapsed, Iterations
    println("----Starting MCTS----")
    start_time = time()
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
                game_result = evaluate_game(selected_state, is_first_half)
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
                simulation_output = simulation(expansion_node.state, is_first_half, false)
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
    end_time = time()
    println("\n\n----Ending MCTS----\n\n")
    println("Hello there")
    print_node_summary(root_node)
    println("Whatsw up buddy")
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
    println("Returing from MCTS:")
    println("Best action: $(best_action)")
    println("Best Score: $(best_score)")
    println("Time taken: $(end_time - start_time)")
    println("# Iterations: $(current_iter)")
    return best_action, best_score, end_time - start_time, current_iter
end
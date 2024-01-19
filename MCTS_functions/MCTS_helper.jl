using Distributions
using Random

include("../util/state.jl")
include("node.jl")

function get_feasible_actions(
    state::State
)::Vector{String}
    feasible_actions = []
    if state.ball_section > FIELD_GOAL_CUTOFF
        push!(feasible_actions, "Field Goal")
    end
    if state.down != 4
        if state.clock_ticking
            push!(feasible_actions, "Kneel")
            push!(feasible_actions, "Spike")
        end
    elseif state.ball_section < flip_field(TOUCHBACK_SECTION)
        push!(feasible_actions, "Punt")
    end
    if state.timeouts_remaining[1] > 0 && state.clock_ticking
        push!(feasible_actions, "Timeout")
        if state.seconds_remaining > 1
            push!(feasible_actions, "Delayed Timeout")
        end
    end
    push!(feasible_actions, "Hurried Play")
    if state.seconds_remaining > 1
        push!(feasible_actions, "Delayed Play")
    end
    
    return feasible_actions
end

function UCB(
    total_score::Int,
    action_visits::Int,
    state_visits::Int
)::Float64
    UCB_constant = 2
    return total_score/action_visits + UCB_constant + sqrt(log(state_visits) / action_visits)
end

function select_action(
    node::Node
)::String
    feasible_actions = get_feasible_actions(node.state)

    best_action_score = -Inf
    best_action = ""
    for action in feasible_actions
        # Check action that has not been explored before
        if node.action_stats[action][2] == 0
            return action
        end
        # Otherwise use formula
        action_score = UCB(node.action_stats[action][1], node.action_stats[action][2], node.times_visited)
        if action_score > best_action_score
            best_action = action
            best_action_score = action_score
        end
    end
    return best_action
end

function random_state(
    current_state::State,
    action::String,
)::Tuple{State, Bool}
    return select_action_child_functions[action](current_state)
end

function selection(
    root::Node
)::Tuple{State, Node, Bool, String, Bool} # New state, Leaf node, Posssesion change, Action, End of Game
    # Create node variable
    node = root
    depth = 0
    while true
        depth += 1
        #println("Search Depth: $(depth)")
        # Check if game over (no children then)
        if node.state.seconds_remaining <= 0
            # We have been returning new state, leaf node but what happens when we reach end of game?
            # I assume that we will need to return another bool var to indicate end of game selected
            # Then check this bool var to see if expansion and simulation stages can be skipped
            # Then backpropogate the value of the end of game state
            #println("Selecting an end of game state")
            return (node.state, node, false, "", true) # TODO: Make sure this is handled appropriately
        end

        # Select the action (using formula)
        action = select_action(node)

        # Randomly select state from the outcome space of that action
        state, state_change_possesion = random_state(node.state, action)

        # Look for node in tree
        state_node = find_node(root, state)
        if state_node === nothing
            #println("Found our new state")
            # Retrun the leaf node and state of unexplored node
            return (state, node, state_change_possesion, action, false)
        else
            #println("Searching further")
            # Update 
            parent_found = false
            for parent in state_node.parents
                if node == parent
                    parent_found = true
                end
            end
            if !parent_found
                push!(state_node.parents, node)
                push!(state_node.parent_change_possesion, state_change_possesion)
            end
            # Repeat with process with already explored node
            node = state_node
        end
    end
end
# TODO: write a testing suite for the selection stage

function expansion(
    new_state::State,
    parent_node::Node,
    parent_change_possesion::Bool,
    parent_action::String
)::Node
    new_node = create_child(
        parent_node,
        parent_change_possesion,
        new_state
    )
    push!(parent_node.visited_children[parent_action], new_node)
    return new_node
end
# TODO: write a testingsuite for the expansion stage (this should be very simple)

function evaluate_game(state::State)::Int
    if IS_FIRST_HALF
        return state.score_diff
    else
        if state.score_diff > 0
            return 1
        elseif state.score_diff == 0
            return 0
        else
            return -1
        end
    end
end

"""
Returns the score from the random simulation
"""
function simulation(
    current_state::State,
    changed_possession::Bool
)::Tuple{Int, Bool}
    #println("Simulation with state: $current_state")
    # TODO: Make this simulation more random (while still maintaining some randomness)\
    if current_state.seconds_remaining <= 0
        #print("Terminal state: $(current_state)")
        return (evaluate_game(current_state), changed_possession)
    else
        feasible_actions = get_feasible_actions(current_state)
        random_action = rand(feasible_actions)
        #println("Chosen random action: $random_action")
        random_state_tuple = random_state(current_state, random_action)
        if random_state_tuple[2]
            return simulation(random_state_tuple[1], !changed_possession)
        else
            return simulation(random_state_tuple[1], changed_possession)
        end
    end
end
# TODO: write a testing suite for the simulation stage 

function backpropogation(
    simulation_result::Int,
    changed_possesion::Bool,
    node::Node,
    root_node::Node
) # VOID FUNCTION
    """ Update node stats """
    node.times_visited += 1
    if changed_possesion
        node.total_score -= simulation_result
    else
        node.total_score += simulation_result
    end

    """ Check for root node / initial state """
    if length(node.parents) == 0
        return root_node
    end

    """ Update action stats of parent node """
    # Iterate through all parents
    for parent_index in 1:length(node.parents)
        # Iterate through all action of parents
        for (action, child_nodes) in node.parents[parent_index].visited_children
            # Look for this node in the children for each action
            if in(node, child_nodes)
                # Increment the times visited for action
                node.parents[parent_index].action_stats[action][2] += 1
                # Increment
                parent_change_possesion = changed_possesion
                if node.parent_change_possesion[parent_index]
                    parent_change_possesion = !changed_possesion
                end
                if parent_change_possesion
                    node.parents[parent_index].action_stats[action][1] -= simulation_result
                else
                    node.parents[parent_index].action_stats[action][1] += simulation_result
                end
                root_node = backpropogation(
                    simulation_result, 
                    parent_change_possesion,
                    node.parents[parent_index],
                    root_node
                )
            end 
        end
    end
    return root_node
end

"""
TODO: 
    Look at optimising because this will go through every way to the leaf nodes.
    Will look at children who have already been searched 
    (because it was reached a different way)
"""
function find_node(
    node::Node,
    target_state::State
)::Union{Nothing, Node}
    # Exit Cases
    if node.state == target_state
        return node
    elseif length(node.visited_children) == 0
        return nothing
    end 

    for action_nodes in values(node.visited_children)
        for child in action_nodes
            child_result = find_node(child, target_state)
            if child_result !== nothing
                return child_result
            end
        end
    end
    # Node not found
    return nothing
end




using Distributions
using Random

include("../util/state.jl")
include("node.jl")

function feasible_actions(
    state::State
)::Vector{String}
    feasible_actions = []
    if state.ball_section > FIELD_GOAL_CUTOFF
        push!(feasible_actions, "Field Goal")
    end
    if state.down != 4
        push!(feasible_actions, "Kneel")
        push!(feasible_actions, "Spike")
    elseif state.ball_section < TOUCHBACK_SECTION
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
    feasible_actions = feasible_actions(node.state)

    best_action_score = -Inf
    best_action = ""
    for action in feasible_actions
        # Check action that has not been explored before
        if length(node.action_stats[action]) == 0
            return action
        end
        # Otherwise use formula
        action_score = UCB(node.action_stats[action][1], node.action_stats[action][2], node.times_visited)
        if action_score > best_action_score
            best_action = action
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
)::Tuple{State, Node}
    # Create node variable
    node = root
    while true
        # Check if game over (no children then)
        if node.state.seconds_remaining <= 0
            return (state, node) # TODO: Make sure this is handled appropriately
        end

        # Select the action (using formula)
        action = select_action(node)

        # Randomly select state from the outcome space of that action
        random_state_tuple = random_state(state, action)
        state = random_state_tuple[1]
        state_change_possesion = random_state_tuple[2]

        # Look for node in tree
        state_node = find_node(root, state)
        if state_node === nothing
            # Retrun the leaf node and state of unexplored node
            return (state, state_node) 
        else
            # Update 
            parent_found = false
            for parent in child.parents
                if node == parent
                    parent_found = true
                end
            end
            if !parent_found
                push!(node.child.parents, node)
                push!(node.parent_change_possesion, state_change_possesion)
            end
            # Repeat with process with already explored node
            node = state_node
        end 
    end
end
# TODO: write a testing suite for the selection stage

function expansion(
    new_state::State,
    leaf_node::Node,
    parent_change_possesion::Bool
)::Node
    new_node = Node(
        new_state, 
        0,
        0, 
        [leaf_node],
        [parent_change_possesion],
        Dict{String, Tuple{Int, Int}}(),
        Dict{String, Node}()
    )
    push!(leaf_node.visited_children[action], new_node)
    return new_node
end
# TODO: write a testingsuite for the expansion stage (this should be very simple)

"""
Returns the score from the random simulation
"""
function simulation(
    current_state::Node,
    changed_possession::Bool
)::Tuple{Int, Bool}
    # TODO: Make this simulation more random (while still maintaining some randomness)\
    if current_state.seconds_remaining <= 0
        return evaluate_game(leaf_node.state)
    else
        feasible_actions = feasible_actions(current_state)
        random_action = rand(feasible_actions)
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

    node::Node
) # IDK what this is going to return yet
    if length(node.parents) == 0
        # We ahve reached the root node/initial state
        return
    end
    node.times_visited += 1
    
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

    for child in values(node.visited_children)
        child_result = find_node(child, target_state)
        if child_result !== nothing
            return child_result
        end
    end
    # Node not found
    return nothing
end



function test_find_node()
    total_tests = 0
    passed_tests = 0
    """ Initialise Tree """
    # Set up root node
    dummy_root_state = State(2, 1, (1,1), 1, 1, 1, true)
    dummy_root = Node(dummy_root_state, 0, 0, Vector{Node}(), Vector{Bool}(), Dict{String, Tuple{Int, Int}}(), Dict{String, Node}())
    # Set up children
    dummy_child_state_one = State(1, 1, (0,1), 1, 1, 1, true)
    dummy_child_one = Node(dummy_child_state_one, 0, 0, [dummy_root], [false], Dict{String, Tuple{Int, Int}}(), Dict{String, Node}())
    dummy_child_state_two = State(1, 1, (1,0), 1, 1, 1, true)
    dummy_child_two = Node(dummy_child_state_two, 0, 0, [dummy_root], [false], Dict{String, Tuple{Int, Int}}(), Dict{String, Node}())
    dummy_child_state_three = State(1, 1, (0,0), 1, 1, 1, true)
    dummy_child_three = Node(dummy_child_state_three, 0, 0, [dummy_root], [false], Dict{String, Tuple{Int, Int}}(), Dict{String, Node}())
    dummy_child_state_four = State(0, 1, (0,0), 1, 1, 1, true)
    dummy_child_four = Node(dummy_child_state_four, 0, 0, [dummy_child_three], [false], Dict{String, Tuple{Int, Int}}(), Dict{String, Node}())

    visited_children = Dict{String, Node}(
        "one" => dummy_child_one,
        "two" => dummy_child_two,
        "three" => dummy_child_three
    )
    dummy_root.visited_children = visited_children

    dummy_child_three.visited_children = Dict{String, Node}("one" => dummy_child_four)

    # Unknown state
    dummy_unknown_state = State(0, 0, (0, 0), 1, 1, 1, false)

    """ TESTS """
    # Find first child
    child_one_result = find_node(dummy_root, dummy_child_state_one)
    if child_one_result === nothing
        println("Error: Child 1 not found")
    else
        passed_tests += 1
    end
    total_tests += 1
    # Find second child
    child_two_result = find_node(dummy_root, dummy_child_state_two)
    if child_two_result === nothing
        println("Error: Child 2 not found")
    else
        passed_tests += 1
    end
    total_tests += 1
    # Find third child
    child_third_result = find_node(dummy_root, dummy_child_state_three)
    if child_third_result === nothing
        println("Error: Child 3 not found")
    else
        passed_tests += 1
    end
    total_tests += 1
    # Find fourth child
    child_four_result = find_node(dummy_root, dummy_child_state_four)
    if child_four_result === nothing
        println("Error: Child 4 not found")
    else
        passed_tests += 1
    end
    total_tests += 1
    # Search for state not in tree
    unknown_state_result = find_node(dummy_root, dummy_unknown_state)
    if unknown_state_result !== nothing
        println("Error: Found a node for a state not in the tree")
    else
        passed_tests += 1
    end
    total_tests += 1
    """ Print summary """
    println("Test pass rate: ($passed_tests / $total_tests)")
end

test_find_node()
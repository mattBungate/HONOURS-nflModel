include("../util/state.jl")
include("../util/util.jl")
include("MCTS_helper.jl")
include("node.jl")
include("../actions/field_goal_handling.jl")
include("../actions/kneel_handling.jl")
include("../actions/play_handling.jl")
include("../actions/punt_handling.jl")
include("../actions/spike_handling.jl")
include("../actions/timeout_handling.jl")
include("../util/constants.jl")

function initialise_tree()::Node
    # Set up root
    root_state = State(2, 1, (1,1), 1, 1, 1, true)
    root = Node(root_state, 0, 0, Vector{Node}(), Vector{Bool}(), Dict{String, Tuple{Int, Int}}(), Dict{String, Vector{Node}}())
    # Set up children
    child_one_state = State(1, 1, (0,1), 1, 1, 1, true)
    child_one = Node(child_one_state, 0, 0, [root], [false], Dict{String, Tuple{Int, Int}}(), Dict{String, Vector{Node}}())
    child_two_state = State(1, 1, (1, 0), 1, 1, 1, true)
    child_two = Node(child_two_state, 0, 0, [root], [false], Dict{String, Tuple{Int, Int}}(), Dict{String, Vector{Node}}())
    child_three_state = State(1, 1, (0, 0), 1, 1, 1, true)
    child_three = Node(child_three_state, 0, 0, [root], [false], Dict{String, Tuple{Int, Int}}(), Dict{String, Vector{Node}}())
    # Set up grandchildren
    grandchild_one_state = State(0, 1, (0,0), 1, 1, 1, true)
    grandchild_one = Node(grandchild_one_state, 0, 0, [child_three], [false], Dict{String, Tuple{Int, Int}}(), Dict{String, Vector{Node}}())

    # Connect children to root
    visited_children = Dict{String, Vector{Node}}(
        "Hurried Play" => [child_one, child_two],
        "Delayed Play" => [child_three]
    )
    root.visited_children = visited_children

    # Connect grandchildren to children
    visited_grandchildren = Dict{String, Vector{Node}}(
        "Hurried Play" => [grandchild_one]
    ) 
    child_three.visited_children = visited_grandchildren

    return root
end

function test_find_node(root::Node)
    # TODO: Test that it is returning the right node
    """ Initialise Test Variables """
    total_tests = 0
    passed_tests = 0
    
    child_states = [
        State(1, 1, (0,1), 1, 1, 1, true),
        State(1, 1, (1, 0), 1, 1, 1, true),
        State(1, 1, (0, 0), 1, 1, 1, true)
    ]
    grandchild_states = [
        State(0, 1, (0,0), 1, 1, 1, true)
    ]

    unknown_state = State(0, 0, (0, 0), 1, 1, 1, false)

    """ TESTS """
    # Find first child
    child_one_result = find_node(root, child_states[1])
    if child_one_result === nothing
        println("Error: Child 1 not found")
    else
        passed_tests += 1
    end
    total_tests += 1
    # Find second child
    child_two_result = find_node(root, child_states[2])
    if child_two_result === nothing
        println("Error: Child 2 not found")
    else
        passed_tests += 1
    end
    total_tests += 1
    # Find third child
    child_third_result = find_node(root, child_states[3])
    if child_third_result === nothing
        println("Error: Child 3 not found")
    else
        passed_tests += 1
    end
    total_tests += 1
    # Find (first) grandchild
    grandchild_one_result = find_node(root, grandchild_states[1])
    if grandchild_one_result === nothing
        println("Error: Grandchild not found")
    else
        passed_tests += 1
    end
    total_tests += 1
    # Search for state not in tree
    unknown_state_result = find_node(root, unknown_state)
    if unknown_state_result !== nothing
        println("Error: Found a node for a state not in the tree")
    else
        passed_tests += 1
    end
    total_tests += 1
    """ Print summary """
    println("find_node() passed tests: ($passed_tests / $total_tests)")
end

function test_get_feasible_actions()
    println("get_feasible_actions()")
    passed_tests = 0
    total_tests = 0
    
    """ 
    Initialise test variables
    """
    # Punt tests
    punt_tests_expected = [
        ["Field Goal", "Kneel", "Spike", "Timeout", "Delayed Timeout", "Hurried Play", "Delayed Play"],
        ["Field Goal", "Hurried Play", "Delayed Play"],
        ["Punt", "Hurried Play", "Delayed Play"]
    ]
    punt_states = [
        State(20, 0, (1, 1), 60, 1, 10, true),
        State(20, 0, (0, 0), 90, 4, 10, true),
        State(20, 0, (0, 0), 20, 4, 10, true)
    ]
    punt_messages = [
        "Error: 1st down. 60 yard",
        "Error: 4th down. 90 yard",
        "Error: 4th down. 20 yard"
    ]

    # Timeout Tests
    timeout_tests_expected = [
        ["Field Goal", "Kneel", "Spike", "Hurried Play", "Delayed Play"],
        ["Field Goal", "Kneel", "Spike", "Hurried Play", "Delayed Play"],
        ["Field Goal", "Hurried Play", "Delayed Play"]
    ]
    timeout_states = [
        State(20, 0, (0, 0), 60, 1, 10, true),
        State(20, 0, (0, 1), 60, 1, 10, true),
        State(20, 0, (1, 0), 60, 1, 10, false)
    ]
    timeout_messages = [
        "Error: Timeouts: (0, 0), clock ticking",
        "Error: Timeotus: (0, 1), clock ticking",
        "Error: Timeouts: (1, 0), clock stopped"
    ]

    # Kneel & Spike
    ks_tests_expected = [
        ["Field Goal", "Hurried Play", "Delayed Play"],
        ["Field Goal", "Punt", "Hurried Play", "Delayed Play"]
    ]
    ks_states = [
        State(20, 0, (0, 0), 60, 1, 10, false),
        State(20, 0, (0, 0), 60, 4, 10, true)
    ]
    ks_messages = [
        "Error: 1st down. Clock not ticking",
        "Error: 4th down. Clock ticking"
    ]
    # Delayed play & timeout
    delayed_tests_expected = [
        ["Field Goal", "Hurried Play"],
        ["Field Goal", "Kneel", "Spike", "Timeout", "Hurried Play"]
    ]
    delayed_states = [
        State(1, 0, (0, 0), 60, 1, 10, false),
        State(1, 0, (1, 0), 60, 1, 10, true)
    ]
    delayed_messages = [
        "Error: 1 second remaining. 0 Timeouts remaining",
        "Error: 1 second remaining. 1 Timeout reamining"
    ]

    test_categories = ["Punt", "Timeout", "Kneel & Spike", "Delayed (play & timeout)"]
    tests_expected = [punt_tests_expected, timeout_tests_expected, ks_tests_expected, delayed_tests_expected]
    test_states = [punt_states, timeout_states, ks_states, delayed_states]
    test_messages = [punt_messages, timeout_messages, ks_messages, delayed_messages]

    """ Run through tests """
    for category_index in 1:length(test_categories)
        category_passed_tests = 0
        println(test_categories[category_index])
        for test_index in 1:length(tests_expected[category_index])
            test_output = get_feasible_actions(test_states[category_index][test_index])
            if test_output != tests_expected[category_index][test_index]
                println(test_messages[category_index][test_index])
                println("Output: $test_output")
                println("Expected: $(tests_expected[category_index][test_index])\n")
            else
                category_passed_tests += 1
            end
        end
        passed_tests += category_passed_tests
        total_tests += length(test_states[category_index])
        println("Passed tests: $(category_passed_tests) / $(length(test_states[category_index]))\n")
    end
    println("get_feasible_actions() passed tests: $passed_tests / $total_tests\n")
end

function test_select_action(root::Node)
    """ Initialise test variables """
    passed_tests = 0
    total_tests = 0

    test_one_root = deepcopy(root)
    test_one_root.visited_children["Hurried Play"][1].times_visited = 2
    test_one_root.visited_children["Hurried Play"][1].total_score = 7
    
    test_two_root = deepcopy(test_one_root)
    test_two_root.visited_children["Hurried Play"][2].times_visited = 1
    test_two_root.visited_children["Hurried Play"][2].total_score = 1

    test_three_root = deepcopy(test_two_root)
    test_three_root.visited_children["Delayed Play"][1].times_visited = 1
    test_two_root.visited_children["Delayed Play"][1].total_score = 2

    # Create tree
    #root_state = 
end


function test_all()
    test_root = initialise_tree()
    test_find_node(test_root)
    test_get_feasible_actions()
end
test_all()

# Set up a test case to see what selection does on the first run through
test_state = State(26, -4, (2,2), 99, 2, 1, true)
root_node = Node(test_state, 0, 0, [], [], Dict{String, Tuple{Int, Int}}(), Dict{String, Vector{Node}}())
root_feasible = get_feasible_actions(test_state)
for action in root_feasible
    root_node.action_stats[action] = [0,0]
    root_node.visited_children[action] = []
end
println("Starting selection function")
tuple_output = selection(root_node)
println("Starting state: $(root_node.state)")
println("Unexplored state: $(tuple_output[1])")
println("Did we flip possesion: $(tuple_output[3] ? "Y" : "N")")
println("Unexplored state parent: $(tuple_output[2].state)")
leaf_node = expansion(tuple_output[1], tuple_output[2], tuple_output[3], tuple_output[4])
println("\n\n--- Simulation Stage ---\n")
simulation_output = simulation(leaf_node.state, false)
println("Simulation output: $(simulation_output)")

"""
println("\n\n --- Simulation Test ---\n")
simulation_test_state = State(120, 0, (3,3), 25, 1, 10, false)
simulation_output = simulation(simulation_test_state, false)
backpropogation(simulation_output[1], simulation_output[2], leaf_node)
"""

# Check the back propogation worked
println("\n\n--- Backpropogation ---")
backpropogation(simulation_output[1], simulation_output[2], leaf_node)
println("Root: $(root_node.times_visited) $(root_node.total_score)")
for children in values(root_node.visited_children)
    for child in children
        println("Child: $(child.times_visited) $(child.total_score)")
    end
end
for (action, stats) in root_node.action_stats
    println("Action: $(action) | Score: $(stats[1]) - Times visited: $(stats[2])")
end
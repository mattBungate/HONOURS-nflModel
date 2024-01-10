using Distributions
include("../util/state.jl")
include("node.jl")

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

    best_action_score = -Inf
    best_action = ""
    for action in action_space
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
    outcome_space::Vector{State}
)::Tuple{State, Bool}
    # No uncertainty - outcome space is 0 dimensional
    no_uncertainty_actions = ["Kneel", "Spike", "Timeout", "Delayed Timeout"]
    if action in no_uncertainty_actions
        # Only 1 state
        return (outcome_space[1], false)
    end

    # Field goal - 2 dimensional outcome space - 1. Time 2. Made or missed
    if action == "Field Goal"
        """ Field goal random variables """
        # --- TIME ---
        # TODO: factor out these as constants
        FIELD_GOAL_TIME_DIST = Normal(6, 1.5) # TODO: play with these constants
        
        field_goal_duration = round(rand(FIELD_GOAL_TIME_DIST))
        if field_goal_duration < 3
            field_goal_duration = 3 # TODO: factor out this constant
        elseif field_goal_duration > 9
            field_goal_duration = 9 # TODO: factor out this constant
        end

        # --- Making Field Goal ---
        field_goal_made_rand_val = rand() # Number between 0  and 1
        # Get field goal prob
        ball_section_10_yard = Int(ceil(current_state.ball_section / 10))
        col_name = Symbol("T-$(ball_section_10_yard)")
        field_goal_prob = field_goal_df[1, col_name]

        """ Return outcome state """ 
        if field_goal_made_rand_val < field_goal_prob
            # Made the field goal
            return (State(
                current_state.seconds_remaining - field_goal_duration,
                -(current_state.score_diff + FIELD_GOAL_SCORE),
                reverse(current_state.timeouts_remaining),
                TOUCHBACK_SECTION,
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false
            ),
            true)
        else
            # Missed field goal
            if current_state.ball_section < FIELD_GOAL_MERCY_SECTION
                # Behind the mercy section
                return (State(
                    current_state.seconds_remaining - field_goal_duation,
                    -current_state.score_diff,
                    reverse(current_state.timeouts_remaining),
                    flip_field(current_state.ball_section),
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    false
                ),
                true)
            else
                # In front of the mercy section
                return (State(
                    current_state.seconds_remaining - field_goal_duration,
                    -current_state.score_diff,
                    reverse(current_state.timeouts_remaining),
                    TOUCHBACK_SECTION,
                    FIRST_DOWN,
                    FIRST_DOWN_TO_GO,
                    false
                ),
                true)
            end
        end
    end


end

function selection(
    node::Node
)::Node
    
    while true
        # Select the action (using formula)
        action = select_action(node)

        # Generate outcome space of that state given the action
        outcome_space = action_children_functions[action](node.state) # Is this necessary?

        # Randomly select state from the outcome space of that action
        state = random_state(state, action, outcome_space) 
    end

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

"""
MCTS tree node.
"""
mutable struct Node
    state::State
    times_visited::Int
    total_score::Int
    parents::Vector{Node} 
    parent_change_possesion::Vector{Bool}
    action_stats::Dict{String, Vector{Int}} # Action -> (Score, Time visited)
    visited_children::Dict{String, Vector{Node}}
end

# Set up printing node object
function Base.show(io::IO, n::Node)
    print(
        io,
        "Node:
    Ave Score - $(n.total_score / n.times_visited)
    State - $(n.state)
    Times Visited - $(n.times_visited)
    Total Score - $(n.total_score)
    Parents - $(n.parents)
    Action Stats - $(n.action_stats)
    Visited Children - $(n.visited_children)"
    )
end

# Set up printing specific parts of node
function print_node_summary(node::Node)
    best_action, best_action_score = best_node_action(node)
    println("\n\nNode Summary:\n
$(node.state)\n
Best Action - $(best_action)
Best Action Score - $(best_action_score)
Ave Score - $(node.total_score / node.times_visited)
Total Score - $(node.total_score)
Times Visited - $(node.times_visited)\n
Num parents - $(length(node.parents))
Num children - $(total_visited_children(node))\n")
end

function print_node_action_stats(node::Node)
    for (action, action_stats) in node.action_stats
        println("$(action) | $(action_stats[1] / action_stats[2]) | $(action_stats[1]) | $(action_stats[2])")
    end
    println()
end

function best_node_action(node::Node)::Tuple{String, Float64}
    best_action = ""
    best_action_score = -Inf
    for (action, action_stats) in node.action_stats
        if action_stats[2] == 0
            # Skip actions that have not been visited
            continue
        end
        action_ave_score = action_stats[1] / action_stats[2]
        if action_ave_score > best_action_score
            best_action = action
            best_action_score = action_ave_score
        end
    end
    return best_action, best_action_score
end

function total_visited_children(node::Node)
    num_children = 0
    for action_children in values(node.visited_children)
        num_children += length(action_children)
    end
    return num_children
end

function create_child(
    parent_node::Node,
    parent_change_possesion::Bool,
    node_state::State
)
    feasible_actions = get_feasible_actions(node_state)

    action_stats = Dict{String, Vector{Int}}()
    visited_children = Dict{String, Vector{Node}}()
    for action in feasible_actions
        action_stats[action] = [0,0]
        visited_children[action] = []
    end

    return Node(
        node_state,
        0,
        0,
        [parent_node],
        [parent_change_possesion],
        action_stats,
        visited_children
    )
end

function create_root(
    root_state::State
)::Node
    feasible_actions = get_feasible_actions(root_state)
    action_stats = Dict{String, Vector{Int}}()
    visited_children = Dict{String, Vector{Node}}()
    for action in feasible_actions
        action_stats[action] = [0,0]
        visited_children[action] = []
    end
    return Node(
        root_state,
        0, 
        0, 
        [],
        [],
        action_stats,
        visited_children
    )
end
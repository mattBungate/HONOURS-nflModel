

function find_children(
    state::State
)::Dict{String, State}
    children_states = Dict{String, State}()
    for action in action_space
        children_states[action] = action_children_functions[action](state)
    end
    return children_states
end

function create_node(
    state::State, parent_node::Node)
    children_nodes = find_children(state)
    node = Node(
        state,
        0,
        0,
        [parent_node],
        children_nodes,
        {}
    )
end
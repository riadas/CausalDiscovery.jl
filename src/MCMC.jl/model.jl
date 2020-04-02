module Model

include("./grammar.jl")
import Pkg; Pkg.add("Random")
import Pkg; Pkg.add("Distributions")

using .Grammar
using Random
using Distributions

""" ----- STRUCTS ----- """

abstract type Node end

""" Non-Terminal Node Struct """
mutable struct NonTerminalNode <: Node
    tag # binary tuple (i, k) from non_terminal_id (N_i) and production_rule_id (R_ik)
    symbol # string representing grammar symbol
    node_position # tuple representing position of node in parse tree (a_E)
    prob # probability associated with production_rule_id k
    parent # parent node
    children # ordered list of child nodes
end

""" Terminal Node Struct """
mutable struct TerminalNode <: Node
    tag # binary tuple (i, k) from non_terminal_id (N_i) and production_rule_id (R_ik)
    symbol # string representing grammar symbol
    node_position # tuple representing position of node in parse tree (a_E)
    prob # probability associated with terminal distribution
    parent # parent node
    value # value of terminal node
end

""" Empty Node Initializers """
NonTerminalNode() = NonTerminalNode((), (), nothing, 1, nothing, [])
TerminalNode() = TerminalNode((), (), 1, nothing, nothing, :())

""" Tagged Parse Tree Struct """
mutable struct TaggedParseTree
    root_node::NonTerminalNode # root node of tagged parse tree
    node_positions # list of position tuples of nodes (A)
end

""" ----- METHODS ----- """

""" Recursively construct random TaggedParseTree """
function generateTree(rng)
    Random.seed!(rng)
    # initialize tree object and root node object
    node_positions = []
    root = generateTreeHelper(1, "expr", nothing, node_positions)
    tree = TaggedParseTree(root, node_positions)
    tree
end

function generateTree()
    # initialize tree object and root node object
    node_positions = []
    root = generateTreeHelper(1, "expr", nothing, node_positions)
    tree = TaggedParseTree(root, node_positions)
    tree
end

""" Recursive helper function for constructing random TaggedParseTree """
function generateTreeHelper(node_index, symbol, parent_node, node_positions)
    node = isTerminalIndex(node_index) ? TerminalNode() : NonTerminalNode()
    node.parent = parent_node

    # sample production rule
    production_rule_index, prob = getProductionRuleIndexAndProb(node_index)
    node.tag = (node_index, production_rule_index)
    node.symbol = symbol
    node.prob = prob

    if isTerminalIndex(node_index)
        # set terminal value
        node.value = getTerminalValue(node_index, production_rule_index)

        # construct new node_position
        node_position = tuplejoin(parent_node.node_position, node.tag)
        node.node_position = node_position
        push!(node_positions, node_position)
    else
        # construct new node_position
        if (parent_node === nothing)
            node_position = node.tag
        else
            node_position = tuplejoin(parent_node.node_position, node.tag)
        end
        node.node_position = node_position
        push!(node_positions, node_position)

        # construct child nodes
        child_node_symbols = getSymbolsOfProductionRule(node_index, production_rule_index)
        for child_index in 1:length(child_node_symbols)
            child_node_symbol = child_node_symbols[child_index]
            child_node_index = getNodeIndexFromSymbol(child_node_symbol)
            child_node = generateTreeHelper(child_node_index, child_node_symbol, node, node_positions)
            push!(node.children, child_node)
        end
    end
    node
end

""" Compute log probability of sampling TaggedParseTree """
function getPriorLogProb(tree::TaggedParseTree)
    getPriorLogProbHelper(tree.root_node)
end

function getPriorLogProbHelper(node::Node)
    node_index = getNodeIndex(node.symbol)
    log_prob = log(node.prob)
    if (!isTerminalIndex(node_index))
        log_prob = log(node.prob)
        for child in node.children
            log_prob += getPriorLogProbHelper(child)
        end
    end
    log_prob
end

""" Compute probability of sampling TaggedParseTree """
function getPriorProb(tree::TaggedParseTree)
    getPriorProbHelper(tree.root_node)
end

function getPriorProbHelper(node::Node)
    node_index = getNodeIndex(node.symbol)
    prob = node.prob
    if (!isTerminalIndex(node_index))
        for child in node.children
            prob *= getPriorProbHelper(child)
        end
    end
    prob
end

"""Compute conditional probability of transitioning between TaggedParseTrees """
function getConditionalLogProb(tree1::TaggedParseTree, tree2::TaggedParseTree)
    node_positions_1 = tree1.node_positions
    node_positions_2 = tree2.node_positions

    #find the node_positions only in tree2
    tree2_only = setdiff(node_positions_2, node_positions_1)

    sum = 0.0
    #Loop through the node positions in tree2 and calculate the probability of
    #getting the resulting tree from the current node if it is an ancestor of
    #the node that is changed
    for pos in node_positions_2
        if length(pos)<=length(tree1_only[1])
            if pos == tree1_only[1][1:length(pos)]
                node = findNodeWithPosition(tree2.root_node, pos)
                sum += getPriorProbHelper(node)
            end
        end
    end
    return log(sum/length(node_positions_1))
end

function proposeTree(tree::TaggedParseTree)
    copied_tree = deepcopy(tree)
    node_positions = copied_tree.node_positions
    node_position = rand(node_positions)

    if (length(node_position) == 2)
        generateTree()
    else
        # find node with uniformly randomly chosen node position
        node = findNodeWithPosition(copied_tree.root_node, node_position)
        #find the current position of the node so the new node can be inserted at the same location
        node_index = findfirst(map(x->x == node, node.parent.children))

        # remove that node from node.parent.children
        if (node.parent !== nothing)
            filter!(child_node -> child_node.node_position != node_position, node.parent.children)
        end

        filter!(pos -> !(length(pos) >= length(node_position) && pos[1:length(node_position)] == node_position), node_positions)
        # generate new node at node_position
        new_node = generateTreeHelper(node.tag[1], node.symbol, node.parent, node_positions)

        # add new_node to new_node.parent.children
        if (node.parent !== nothing)
            if node_index>1
                store = node.parent.children[1:node_index-1]
            else
                store = []
            end
            append!(append!(store, [new_node]), node.parent.children[node_index:length(node.parent.children)])
            node.parent.children = store

        end
        copied_tree
    end
end

function findNodeWithPosition(node, pos)
    if (node.node_position == pos)
        return node
    else
        if typeof(node) == NonTerminalNode
            for child_node in node.children
                ret_val = findNodeWithPosition(child_node, pos)
                if ret_val !== nothing
                    return ret_val
                end
            end
            return nothing
        else
            return nothing
        end
    end
end


""" Extract native Julia Expr object from TaggedParseTree """
function getExpr(tree::TaggedParseTree)
    expr_tokens = []
    getExprHelper(tree.root_node, expr_tokens)
    lines = split(join(expr_tokens), "\n")
    exprs = map(Meta.parse, lines)
    Expr(:block, exprs...)
end

function getExprHelper(node::TerminalNode, arr)
    str_value = repr(node.value)
    if (str_value[1] == ':')
        push!(arr, str_value[2:length(str_value)])
    else
        push!(arr, str_value)
    end
end

function getExprHelper(node::NonTerminalNode, arr)
    node_index = getNodeIndex(node.symbol)
    rule_index = node.tag[2]
    children = node.children

    if (node_index == 1) # line \n expr | line
        if (rule_index == 1)
            getExprHelper(children[1], arr)
            push!(arr, "\n")
            getExprHelper(children[2], arr)
        elseif (rule_index == 2)
            getExprHelper(children[1], arr)
        end
    elseif (node_index == 2) # exo_line | endo_line
        getExprHelper(children[1], arr)
    elseif (node_index == 3) # bool_var '~' dist | float_var '~' float_dist
        getExprHelper(children[1], arr)
        push!(arr, " ~ ")
        getExprHelper(children[2], arr)
    elseif (node_index == 4) # unary_endo_expr | binary_endo_expr | ternary_endo_expr
        getExprHelper(children[1], arr)
    elseif (node_index == 5) # '!' bool_var | var
        if (rule_index == 1)
            getExprHelper(children[1], arr)
            push!(arr, " = !")
            getExprHelper(children[2], arr)
        elseif (rule_index == 2 || rule_index == 3 || rule_index == 4)
            getExprHelper(children[1], arr)
            push!(arr, " = ")
            getExprHelper(children[2], arr)
        end
    elseif (node_index == 6) # bool_binary_op bool_var bool_var_list | num_binary_op int_var int_var_list | num_binary_op float_var float_var_list
        getExprHelper(children[1], arr)
        push!(arr, " = ")
        getExprHelper(children[2], arr)
        push!(arr, "(")
        getExprHelper(children[3], arr)
        push!(arr, ", ")
        getExprHelper(children[4], arr)
        push!(arr, ")")
    elseif (node_index == 7) # bool_var '?' var ':' var
        getExprHelper(children[1], arr)
        push!(arr, " = ")
        getExprHelper(children[2], arr)
        push!(arr, " ? ")
        getExprHelper(children[3], arr)
        push!(arr, " : ")
        getExprHelper(children[4], arr)
    elseif (node_index == 8 || node_index == 9 || node_index == 10) # bool_var ',' bool_var_list | bool_var
        if (rule_index == 1)
            getExprHelper(children[1], arr)
            push!(arr, ", ")
            getExprHelper(children[2], arr)
        elseif (rule_index == 2)
            getExprHelper(children[1], arr)
        end
    elseif (node_index == 11) # bool_var | int_var | float_var
        getExprHelper(children[1], arr)
    elseif (node_index == 12) # Bernoulli( bernoulli_params )
        push!(arr, "Bernoulli(")
        getExprHelper(children[1], arr)
        push!(arr, ")")
    elseif (node_index == 21)  # Normal ( normal_params ) | Uniform( uniform_params )
        if (rule_index == 1)
            push!(arr, "Normal")
            getExprHelper(children[1], arr)
        elseif (rule_index == 2)
            push!(arr, "Uniform(")
            getExprHelper(children[1], arr)
            push!(arr, ")")
        end
    else
        throw(ArgumentError(""))
    end
end

end

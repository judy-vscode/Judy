
# debug info collection module
module DebugInfo

mutable struct StackInfo
  funcName::AbstractString
  filepath::AbstractString
  lineno::Int64
end

mutable struct VarInfo
  name::AbstractString
  vtype::AbstractString
  value::AbstractString
end

# Tree structure to log variable
Domain = Union{VarInfo, AbstractString}
mutable struct TreeNode
  # var value could be: VarInfo or Module name (at top level)
  content::Domain
  parent::Int64
  children::Array{Int64}
end
mutable struct Tree
  nodes::Array{TreeNode}
end
Tree() = Tree([])
function addRoot!(tree::Tree, node::TreeNode)
  push!(tree.nodes, node)
end
function addChild!(tree::Tree, id::Int64, var::Domain)
  1 <= id <= length(tree.nodes) || throw(BoundsError(tree, id))
  push!(tree.nodes, TreeNode(var, id, []))
  child = length(tree.nodes)
  push!(tree.nodes[id].children, child)
  return length(tree.nodes)
end
children(tree, id) = tree.nodes[id].children
parent(tree,id) = tree.nodes[id].parent

# Vars: Vars[ModuleName] = VarTree
Vars = Tree()
# stack frame
stacks = []


# should be called when hit a breakpoint
# collect stack info, debugger function will be
# deleted at getStackInfo()
function collectStackInfo()
  global stacks
  stacks = []
  for frame in stacktrace()
    funcName = String(frame.func)
    filepath = String(frame.file)
    lineno = frame.line
    stackInfo = StackInfo(funcName, filepath, lineno)
    push!(stacks, stackInfo)
  end
end


# return stack info list (ele: dict)
# Should be called when vs-code request stack
# debugger stack will be removed
function getStackInfo()
  global stacks
  results = []
  cnt = 0
  for frame in stacks
    debugger_file = r"(EventHandler\.jl)|(judy\.jl)|(MsgHandler\.jl)|(DebugInfo\.jl)|(RunTime\.jl)"
    m = match(debugger_file, frame.filepath)
    if !isa(m, RegexMatch)
      cnt += 1
      push!(results, Dict("frameId" => cnt,
                          "name" => frame.funcName,
                          "path" => frame.filepath,
                          "line" => frame.lineno))
    end
  end
  return results
end


# collect variable info
# currently we only collect Main module
function collectVarInfo()
  global Vars
  Vars = Tree()
  addRoot!(Vars, TreeNode("Main", 1, []))
  for var in names(Main)[5:end]
    # collect var name
    var_name = string(var)
    # collect var type
    type_ast = Meta.parse("typeof($(var))")
    vtype = Core.eval(Main, type_ast)
    var_type = string(vtype)
    if var_type == "DataType" || var_type == "Module"
      continue
    end
    # collect var value
    var_value = string(Core.eval(Main, var))
    # collect var ref
    var_info = VarInfo(var_name, var_type, var_value)
    ref = addChild!(Vars, 1, var_info)
    # decomposite var
    if length(fieldnames(vtype)) != 0
      decomposeVar(vtype, var, ref)
    end
  end
end

# decompose var and log them into Vars recursivly
function decomposeVar(vtype::DataType, var::Symbol, parent::Int64)
  global Vars
  for field in fieldnames(vtype)
    var_name = string(field)
    ast = Meta.parse("getfield($(var), :$(field))")
    var_value = string(Core.eval(Main, ast))
    ast = Meta.parse("typeof($(var).$(field))")
    vtype = Core.eval(Main, ast)
    var_type = string(vtype)
    var_info = VarInfo(var_name, var_type, var_value)
    ref = addChild!(Vars, parent, var_info)
    if length(fieldnames(vtype)) != 0
      devar = Core.eval(Main, Meta.parse("$(var).$(field)"))
      decomposeVar(vtype, Symbol(devar), ref)
    end
  end
end

function getVarInfo(ref)
  global Vars
  result = []
  var_refs = children(Vars, ref)
  for ref in var_refs
    var_ref = 0
    if length(children(Vars, ref)) != 0
      var_ref = ref
    end
    var = Vars.nodes[ref].content
    push!(result, Dict("name" => var.name,
                       "value" => var.value,
                       "type" => var.vtype,
                       "variablesReference" => var_ref))
  end
  return result
end
      
end # module DebugInfo

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
  ref::Int64
end

# vars: vars[ModuleName] = [VarInfo, VarInfo, ...]
global_vars = Dict()
local_vars = Dict()
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
    debugger_file = r"(EventHandler\.jl)|(judy\.jl)|(MsgHandler\.jl)|(DebugInfo.jl)|(RunTime.jl)"
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
  global global_vars
  global_vars = Dict()
  module_var = []
  for var in names(Main)[5:end]
    var_name = string(var)
    var_value = string(Core.eval(Main, var))
    type_ast = Meta.parse("typeof($(var))")
    var_type = string(Core.eval(Main, type_ast))
    var_ref = 0
    ##if length(fieldnames(typeof(var))) != 0
    ##  var_ref = ref + 1
    ##end
    var_info = VarInfo(var_name, var_type, var_value, var_ref)
    push!(module_var, var_info)
  end
  global_vars[Main] = module_var
end


function getVarInfo()
  global global_vars
  result = []
  for var in global_vars[Main]
    push!(result, Dict("name" => var.name,
                       "value" => var.value,
                       "type" => var.vtype,
                       "variablesReference" => var.ref))
  end
  return result
end

# collect composite var info
# should only be called by collectVarInfo
# will collect recursivly for composite var
#function collectCompositeVar(var)
#  global global_vars
#  var_name = string(var)
#  var_value = string(Core.eval(Main, var))
#  var_type = string(typeof(a))
#  var_ref = 0
#  if length(filednames(typeof(var))) != 0
#    for member in fieldnames(typeof(var))
      
end # module DebugInfo
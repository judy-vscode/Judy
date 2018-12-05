module EventHandler

asts = []
blocks = []
line = 1

# break points logger
mutable struct BreakPoints
  filepath::AbstractString
  lineno::Array{Int64,1}
end

mutable struct StackInfo
  funcName::AbstractString
  filepath::AbstractString
  lineno::Int64
  isInlined::Bool
end


# variable logger: vars["var_name"] = ("var_value", "var_type")
vars = Dict()
stacks = []
errors = ""
bp = BreakPoints("",[])

struct NotImplementedError <: Exception end
struct BreakPointStop <: Exception end

function readSourceToAST(file)
  global asts
  global blocks
  line = 0
  s = ""
  # recording blocks such as a function
  block_start = 0
  block_end = 0
  open(file) do f
    for ln in eachline(f)
      line += 1
      s *= ln
      ex = parseInputLine(s)
      if (isa(ex, Expr) && ex.head === :incomplete)
        s *= "\n"
        if block_start == 0
          block_start = line
        end
        continue
      else
        if block_start != 0
          # add block line postion
          block_end = line
          push!(blocks, (block_start, block_end))
          block_start = 0
        end
        ast = Meta.lower(Main, ex)
        push!(asts, ast)
        s = ""
      end
    end
  end
end


# run whole program
# return a status contains ast, current_line
function run()
  global asts
  global line
  global bp
  line = 1
  for ast in asts
    try
      Core.eval(Main, ast)
      updateLine()
    catch err
      # if we run to a breakpoint
      # we will catch an exception and collect info
      if err isa BreakPointStop
        Break()
      else
        println(err)
      end
      return
    end
  end
  # exit normally
  return
end

# update info from this point
function Break()
  global line
  println("hit BreakPoint: ", line)
  # collect variable information -- only global variable
  global vars
  vars = Dict()
  for var in names(Main)[5:end]
    var_name = string(var)
    var_value = Core.eval(Main, var)
    vars[var_name] = string(var_value)
  end
  # collect frames
  global stacks
  stacks = []
  for frame in stackframe()
    infoList = split(frame,' ')
    if length(infoList) > 3
      funcName, _, filepath = infoList[1:3]
      filepath, lineno = split(filepath,":")
      stackInfo = StackInfo(funcName, filepath, lineno, false)
    else
      funcName, _, filepath, isInlined = infoList[1:4]
      filepath, lineno = split(filepath,":")
      stackInfo = StackInfo(funcName, filepath, lineno, true)
      push!(stacks, stackInfo)
    end
end


function stepOver()
  global asts
  global line
  ast_index = getAstIndex()
  if ast_index == lastindex(asts) + 1
    return false
  end
  # run next line code
  try
    println(ast_index)
    Core.eval(Main, asts[ast_index])
    updateLine()
  catch err
    # if we meet a breakpoint
    # we just ignore it
    if err isa BreakPointStop
      Break()
      return true
    else
      global errors
      errors = string(err)
      println(errors)
      return false
    end
  end
  # collect information
  Break()
  return true
end

function continous()
  global asts
  global line
  ast_index = getAstIndex()

  res = Dict("allThreadsContinued" => true)

  for ast in asts[ast_index: end]
    try
      Core.eval(Main, ast)
      updateLine()
    catch err
      if err isa BreakPointStop
        Break()
      else
        global errors
        errors = string(err)
        println(errors)
      end
      return res
    end
  end
  # exit normally
  return res
end

function stepIn()
  throw(NotImplementedError("step have not been implemented"))
end

function setBreakPoints(filePath, lineno)
  global bp
  bp.filepath = filePath
  bp.lineno = lineno

  # results for adding breakpoints
  res = []
  id = 1
  for bpline in lineno
    push!(res, Dict("verified" => true,
                    "line" => bpline,
                    "id" => id))
    id += 1
  end
  return res
end

# clear break points
function clearBreakPoints()
  global bp
  bp.filepath = ""
  bp.lineno = []
end

# get stack trace for the current collection
function getStackTrace()
  global stacks
  global bp
  global line
  frame_id = 1
  result = []
  cnt = 0
  for stackInfo in stacks
    cnt += 1
    push!(result, Dict("frameId" => cnt,
                       "name" => stackInfo.funcName,
                       "path" => stackInfo.filepath,
                       "line" => stackInfo.lineno))
  end
  return result
end


function getScopes(frame_id)
  return Dict("name" => "main",
              "variablesReference" => frame_id)
end


function getVariables(ref)
  global vars
  result = []
  for var in vars
    push!(result, Dict("name" => var[1],
                       "value" => var[2],
                       "type" => "notSupportNow",
                       "variablesReference" => 0))
  end
  return result
end

function getStatus(reason)
  global line
  global asts
  if getAstIndex() == lastindex(asts) + 1
    reason == "exited"
    return Dict("exitCode" => 0), "exited"
  end

  description = ""
  if reason == "step"
    description = "step over (ignore breakpoints)"
  elseif reason == "breakpoint"
    description = "hit breakpoint: " * "$(line)"
  end
  result = Dict("reason" => reason,
                "description" => description,
                "text" => " ")
  return result, "stopped"
end


# update line for run/next/continous call
function updateLine()
  global blocks
  global line
  ofs = 1
  for range in blocks
    if line == range[1]
      ofs = range[2] - range[1] + 1
      break
    elseif range[1] > line
      break
    end
  end
  line += ofs
  println("current line:", line)
  if checkBreakPoint(line)
    throw(BreakPointStop())
  end
end

function checkBreakPoint(line)
  global bp
  if line in bp.lineno
    return true
  else
    return false
  end
end

# get AstIndex from current line number
function getAstIndex()
  global blocks
  global line
  global asts
  base = line
  ofs = 0
  for block in blocks
    if block[1] <= line <= block[2]
      base = block[1]
      break
    elseif block[1] > line
      break
    end
    ofs += block[2] - block[1]
  end
  return base - ofs
end
  

function parseInputLine(s::String; filename::String="none", depwarn=true)
  # For now, assume all parser warnings are depwarns
  ex = if depwarn
      ccall(:jl_parse_input_line, Any, (Ptr{UInt8}, Csize_t, Ptr{UInt8}, Csize_t),
            s, sizeof(s), filename, sizeof(filename))
  else
      with_logger(NullLogger()) do
          ccall(:jl_parse_input_line, Any, (Ptr{UInt8}, Csize_t, Ptr{UInt8}, Csize_t),
                s, sizeof(s), filename, sizeof(filename))
      end
  end
  return ex
end

end # module EventHandler
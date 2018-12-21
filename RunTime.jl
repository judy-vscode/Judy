module RunTime

include("DebugInfo.jl")

mutable struct BreakPoints
  filepath::AbstractString
  lineno::Array{Int64,1}
end

mutable struct AstInfo
  asts::Array
  blocks::Array # save struct BlockInfo
end

mutable struct BlockInfo
  BlockType::Symbol
  startline::Int64
  endline::Int64
  raw_code::AbstractString
end

# FileLine["FileName"] = line number
FileLine = Dict()
# FileAst["filename"] = struct AstInfo
FileAst = Dict()
# FileBp["filename"] = [bp line array]
FileBp = Dict()
# run file stack for `include`
RunFileStack = []

errors = ""

struct NotImplementedError <: Exception end
struct BreakPointStop <: Exception end

# entry file for debugging
function setEntryFile(file)
  global RunFileStack
  global FileLine
  push!(RunFileStack, file)
  readSourceToAST(file)
end

function readSourceToAST(file)
  global FileAst
  global FileLine
  asts = []
  blocks = []
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
          blockinfo = BlockInfo(ex.head, block_start, block_end, s)
          push!(blocks, blockinfo)
          block_start = 0
        end
        ast = Meta.lower(Main, ex)
        push!(asts, ast)
        s = ""
      end
    end
  end
  FileAst[file] = AstInfo(asts, blocks)
  if !haskey(FileLine, file)
    FileLine[file] = 1
  end
end

# run whole program
# return a status contains ast, current_line
function run() 
  global FileLine
  global FileAst
  global RunFileStack
  # reset all file line
  for file in FileLine
    FileLine[file[1]] = 1
  end
  RunFileStack = [RunFileStack[end]]
  # start running program
  for ast in FileAst[RunFileStack[end]].asts
    try
      updateLine()
      Core.eval(Main, ast)
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
  # debug info
  global RunFileStack
  global FileLine
  current_line = FileLine[RunFileStack[end]]
  println("hit breakpoint: $(RunFileStack[end]): $(current_line)")
  # collect variable info
  DebugInfo.collectVarInfo()
  # collect stack info
  DebugInfo.collectStackInfo()
end

function stepOver()
  global FileAst
  global FileLine
  global RunFileStack
  current_file = RunFileStack[end]
  asts = FileAst[current_file].asts
  ast_index = getAstIndex(current_file, FileLine[current_file])
  if ast_index == lastindex(asts) + 1
    return false
  end
  # run next line code
  try
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
  global FileAst
  global FileLine
  global RunFileStack
  current_file = RunFileStack[end]
  asts = FileAst[current_file].asts
  ast_index = getAstIndex(current_file, FileLine[current_file])

  res = Dict("allThreadsContinued" => true)

  for ast in asts[ast_index: end]
    try
      println("current line: $(FileLine[current_file]), ast idx: $(ast_index)")
      Core.eval(Main, ast)
      updateLine()
    catch err
      if err isa BreakPointStop
        Break()
      else
        global errors
        errors = string(err)
        println("runtime errors: $(errors)")
      end
      return res
    end
  end
  # exit normally
  return res
end

function stepIn()
  throw(NotImplementedError("step has not been implemented"))
end

function setBreakPoints(filepath, lineno)
  global FileBp
  result = []
  readSourceToAST(filepath)
  FileBp[filepath] = lineno
  for line in lineno
    # here should verify bp correctness
    push!(result, true)
  end
  return result
end

# update line for run/next/continous call
function updateLine()
  global RunFileStack
  global FileLine
  global FileAst
  current_file = RunFileStack[end]
  blocks = FileAst[current_file].blocks
  ofs = 1
  for blockinfo in blocks
    if FileLine[current_file] == blockinfo.startline
      ofs += blockinfo.endline - blockinfo.startline + 1
      break
    elseif blockinfo.startline > FileLine[current_file]
      break
    end
  end
  FileLine[current_file] += ofs
  if checkBreakPoint()
    throw(BreakPointStop())
  end
end

function checkBreakPoint()
  global RunFileStack
  global FileLine
  global FileBp
  current_file = RunFileStack[end]
  current_line = FileLine[RunFileStack[end]]
  if current_line in FileBp[current_file]
    return true
  else
    return false
  end
end

# get AstIndex from current file and line number
function getAstIndex(filepath, lineno)
  global FileAst
  blocks = FileAst[filepath].blocks
  base = lineno
  ofs = 0
  for block in blocks
    if block.startline <= lineno <= block.endline
      base = block.startline
      break
    elseif block.startline > lineno
      break
    end
    ofs += block.endline - block.startline
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

end # module RunTime 
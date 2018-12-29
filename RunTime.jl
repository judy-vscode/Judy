module RunTime

include("DebugInfo.jl")

const kRunTimeOut = Channel{AbstractString}(32)
const kRunTimeIn = Channel{AbstractString}(33)

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
RunBlockStatus = []

EntryFile = ""
errors = ""

struct NotImplementedError <: Exception end
struct BreakPointStop <: Exception end

# entry file for debugging
function setEntryFile(file)
  global RunFileStack
  global FileLine
  global EntryFile
  EntryFile = abspath(file)
  push!(RunFileStack, EntryFile)
  if !haskey(FileAst, EntryFile)
    readSourceToAST(EntryFile)
  end
end

# clear runblockstatus, this should be called
# after collect info for a block
function clearBlockStatus()
  global RunBlockStatus
  RunBlockStatus = []
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
          s = replace(s, "\r" => "")
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
  global EntryFile
  global kRunTimeOut
  # wait until 'launch'
  while take!(kRunTimeIn) != "launch" end
  # reset all file line
  RunFileStack = []
  push!(RunFileStack, EntryFile)
  cd(abspath(joinpath(EntryFile, "../")))
  FileLine = Dict(EntryFile => 1)
  # start running program
  while true
    cmd = take!(kRunTimeIn)
    notFinish = true
    if cmd == "continue"
      notFinish = continous()
    elseif cmd == "stepOver"
      notFinish = stepOver()
    end
    if !notFinish
      break
    end
  end
  return
end

# check whether is `include` call
# if it is & included file has breakpoints,
# we manually run it
function tryRunNewFile(ast, isStepOver = false)
  global RunFileStack
  local isIncludeCall = false
  local filename = ""
  try
    if ast.args[1].code[1].args[1] == (:include)
      filename = abspath(joinpath(RunFileStack[end], "../" * ast.args[1].code[1].args[2]))
      isIncludeCall = true
    end
  catch err
    # we may get bounderror
    return false
  end
  if isIncludeCall
    if !haskey(FileAst, filename)
      readSourceToAST(filename)
    end
    # skip include call (we run it manually)
    updateLine()
    push!(RunFileStack, filename)
    FileLine[filename] = 1
    continous(isStepOver)
  end
  return isIncludeCall
end
    
# go to next line
# if next line is an empty line, 
# we ignore this line and go until it's a valid ast
function stepOver()
  global FileAst
  global FileLine
  global RunFileStack
  current_file = RunFileStack[end]
  asts = FileAst[current_file].asts
  ast_index = getAstIndex(current_file, FileLine[current_file])
  # run next line code
  if asts[ast_index] isa Nothing
    # if we find a blank line, we skip it
    updateLine()
    stepOver()
  end
  # true line
  try
    if !tryRunNewFile(asts[ast_index], true)
      Core.eval(Main, asts[ast_index])
      updateLine()
    else
      throw(BreakPointStop(""))
    end
  catch err
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
  if getAstIndex(current_file, FileLine[current_file]) > lastindex(asts)
    pop!(RunFileStack)
    if length(RunFileStack) == 0
      put!(kRunTimeOut, "finish")
      return false
    end
  end
  Break()
  return true
end

# go until we meet a bp
# if stopOnPopFile is true: we return (withou Break())
# when a file is finished executing
function continous(stopOnPopFile = false)
  global FileAst
  global FileLine
  global RunFileStack
  global kRunTimeOut
  if length(RunFileStack) == 0
    put!(kRunTimeOut, "finish")
    return false
  end
  current_file = RunFileStack[end]
  asts = FileAst[current_file].asts

  ast_index = getAstIndex(current_file, FileLine[current_file])
  while ast_index <= lastindex(asts)
    ast = asts[ast_index]
    try
      if !tryRunNewFile(ast)
        Core.eval(Main, ast)
        updateLine()
      else
        return true
      end
    catch err
      if err isa BreakPointStop
        Break()
        return true
      else
        global errors
        errors = "runtime errors: $(current_file): $(FileLine[current_file]): $(err)"
        println(errors)
        put!(kRunTimeOut, "error")
        return
      end
    end
    ast_index = getAstIndex(current_file, FileLine[current_file])
  end
  # exit normally
  pop!(RunFileStack)
  if !stopOnPopFile
    continous()
  end
  # since only stepOver will make stopOnPopFile true
  # we don't need put!(kRunTimeOut) here
end

function stepIn()
  throw(NotImplementedError("step has not been implemented"))
end

# update info from this point
function Break()
  # debug info
  global RunFileStack
  global FileLine
  global kRunTimeIn
  global kRunTimeOut
  current_line = FileLine[RunFileStack[end]]
  # println("hit breakpoint: $(RunFileStack[end]): $(current_line)")
  # collect variable info
  DebugInfo.collectVarInfo()
  # collect stack info
  DebugInfo.collectStackInfo()
  put!(kRunTimeOut, "collected")
  # wait until get "go on" info
  while take!(kRunTimeIn) != "go on" end
end

function inBlockBreak(file, lineno)
  global RunFileStack
  global FileLine
  global kRunTimeIn
  global kRunTimeOut
  # println("hit breakpoint in block: $(file): $(lineno)")
  # collect variable info
  DebugInfo.collectVarInfo()
  # collect stack info
  DebugInfo.collectStackInfo()
  # set block running info
  push!(RunBlockStatus, Dict(file => lineno))
  put!(kRunTimeOut, "collected")
  # wait until get "go on" info
  while take!(kRunTimeIn) != "go on" end
end

# set breakpoint
# if breakpoint is on blank line,
# it will not be set
function setBreakPoints(filepath, lineno)
  global FileBp
  global FileAst
  result = []
  filepath = abspath(filepath)
  readSourceToAST(filepath)
  FileBp[filepath] = []
  asts = FileAst[filepath].asts
  blocks = FileAst[filepath].blocks
  for line in lineno
    ast_idx = getAstIndex(filepath, line)
    # outside empty line
    if asts[ast_idx] isa Nothing
      push!(result, false)
    else
      ast, res = trySetBpInBlock(filepath, line)
      if res == 0 || res == 1
        push!(FileBp[filepath], line)
        push!(result, true)
        # set modified ast to filepath
        if res == 1
          FileAst[filepath].asts[ast_idx] = ast
        end
      elseif res == 2
        push!(result, false)
      end
    end
  end
  return result
end

# check and set breakpoint inside blocks
# return: 0: line not in block
#         1: line in block and valid
#         2: line in block but not valid
function trySetBpInBlock(filepath, line)
  global FileAst
  blocks = FileAst[filepath].blocks
  # for windows dir
  input_path = replace(filepath, "\\" => "\\\\")
  result = 0
  block_idx = 1
  for block in blocks
    if line <= block.startline
      # means it is not in a block
      # setting bp on the first line of block
      # will only be stopped once
      break
    end
    if block.startline < line <= block.endline
      # means it is in a block
      modified_code = ""
      ofs = 0
      for code_line in split(block.raw_code, "\n")
        if line == block.startline + ofs
          # means we detect the position to set bp
          try
            if Meta.parse(code_line) isa Nothing
              # means bp are set at an empty line, which is not allowed
              result = 2
            else
              result = 1
              code_line = "Judy.EventHandler.RunTime.inBlockBreak(\"$(input_path)\", $(line));" * code_line
            end
          catch err
            # some errors may cause when try to parse like `else`
            result = 2
          end
        end
        modified_code = modified_code * code_line * " \n"
        # save modified raw code since we can have multiple bps in same block
        FileAst[filepath].blocks[block_idx].raw_code = modified_code
        ofs += 1
      end
      ast = Meta.lower(Main, parseInputLine(modified_code))
      return ast, result
    end
    block_idx += 1
  end
  ast = Meta.lower(Main, parseInputLine(""))
  return ast, result
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
  ofs = ofs > 1 ? ofs - 1 : ofs
  FileLine[current_file] += ofs
  # continue update until we meet a not empty line
  idx = getAstIndex(current_file, FileLine[current_file])
  if idx <= lastindex(FileAst[current_file].asts)
    if FileAst[current_file].asts[idx] isa Nothing
      updateLine()
    end
  end
  if checkBreakPoint()
    throw(BreakPointStop())
  end
end

# check whether current line meets a bp
function checkBreakPoint()
  global RunFileStack
  global FileLine
  global FileBp
  current_file = RunFileStack[end]
  current_line = FileLine[RunFileStack[end]]
  if !haskey(FileBp, current_file)
    return false
  end
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
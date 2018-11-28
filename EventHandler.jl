module EventHandler

asts = []
blocks = []
line = 0

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
  global blocks
  for ast in asts
    try
      updateLine()
      Core.eval(Main, ast)
    catch err
      # if we run to a breakpoint
      # we will catch an exception and collect info
      return
    end
  end
  # exit normally
  return ([], 0)
end

function next()
  global asts
  global line
  ast_index = getAstIndex()
  if ast_index == lastindex(asts)
    return false
  end

  while true
    try
      updateLine()
      ast_index = getAstIndex()
      Core.eval(Main, asts[ast_index])
    catch err
      # if we meet a breakpoint
      # we just ignore it
      println("Error in next")
      return false
      #continue
    end
    break
  end
  return true
end

function continous(status)
  global asts
  global line
  ast_index = getAstIndex()
  for ast in asts[ast_index + 1 : end]
    try
      updateLine()
      Core.eval(Main, ast)
    catch err
      # catch breakpoint
      return
    end
  end
  # exit normally
  return
end

# update line for run/next/continous call
function updateLine()
  global blocks
  global line
  for range in blocks
    if line == range[1]
      line += range[2] - range[1] + 1
      return
    elseif range[1] > line
      break
    end
  end
  line += 1
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
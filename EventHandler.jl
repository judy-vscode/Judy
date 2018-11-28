module EventHandler

asts = []
blocks = []
line = 0

function readSourceToAST(file)
  global asts
  global blocks
  global line
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
        if block_start != 0
          block_start = 0
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
  for ast in asts
    try
      line += 1
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
  if line == lastindex(asts)
    return
  end

  while true
    try
      line += 1
      Core.eval(Main, asts[line])
    catch err
      # if we meet a breakpoint
      # we just ignore it
      continue
    end
    break
  end
  return (asts, line + 1)
end

function continous(status)
  global asts
  global line
  for ast in asts[line + 1 : end]
    try
      line += 1
      Core.eval(Main, ast)
    catch err
      # catch breakpoint
      return
    end
  end
  # exit normally
  return
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
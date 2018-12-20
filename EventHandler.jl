module EventHandler

include("RunTime.jl")


function getRealPos(filepath, bpline)
  global FileAst
  global RunFileStack
  asts = FileAst[filepath].asts
  blocks = FileAst[filepath].blocks
    #check if exists bp in block
    #The key to insert the point is when we revise a copy of function's ast,
    #and then eval the ast, we update the definition of the function
    #Another thing is we should make the mapping from original code pos to insert offset
    #considering blank line  
  for blockinfo in blocks
    if blockinfo.startline <= bpline <= blockinfo.endline
      ast = parseInputLine(blockinfo.raw_code)
      codelines = split(blockinfo.raw_code,"\n")
      # for codeline in codelines:
      #   if isempty(strip(codeline))
      nonBlankLine = 0
      firstNonBlankLine = 0
      for i in range(1, stop = blockinfo.endline - blockinfo.startline + 1)
        if isempty(strip(codelines[i]))
          continue
        end
        if i >= bpline - blockinfo.startline + 1
          firstNonBlankLine = i
          break
        end
        nonBlankLine += 1  #nonBlankLine before bp line
      end
      push!(ast.args[2].args, Nothing)
      if nonBlankLine == 0
        ofs = 1
      elseif bpline == blockinfo.endline
        firstNonBlankLine = blockinfo.endline - blockinfo.startline + 1
        ofs = length(ast.args[2].args)
      else
        ofs = 2 * nonBlankLine - 1
      end
      realLineno = firstNonBlankLine + blockinfo.startline - 1
      return ast, ofs, realLineno
    #not in a block
    end
  end

  firstNonBlankLine = bpline
  while true
    ast_index = getAstIndex(firstNonBlankLine)
    if ast_index > length(asts)
      firstNonBlankLine = bpline
      break
    end
    if isa(asts[ast_index], Nothing)
      firstNonBlankLine += 1
    else
      break
    end
  end
  return Nothing, Nothing, firstNonBlankLine
end   


# get stack trace for the current collection
function getStackTrace()
  return RunTime.DebugInfo.getStackInfo()
end


function getScopes(frame_id)
  return Dict("name" => "main",
              "variablesReference" => frame_id)
end


function getVariables(ref)
  return RunTime.DebugInfo.getVarInfo()
end

function getStatus(reason)
  asts = FileAst[currentFile].asts
  line = FileLine[currentFile]
  if RunTime.getAstIndex() == lastindex(asts) + 1
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
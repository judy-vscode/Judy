module EventHandler

include("RunTime.jl")


function init(file)
  RunTime.setEntryFile(file)
end

function setBreakPoints(filepath, lineno)
  return RunTime.setBreakPoints(filepath, lineno)
end

# get stack trace for the current collection
function getStackTrace()
  return RunTime.DebugInfo.getStackInfo()
end


function getScopes(frame_id)
  return Dict("name" => "main",
              "variablesReference" => 1000 + frame_id)
end


function getVariables(ref)
  if ref >= 1000
    ref = 1
  end
  return RunTime.DebugInfo.getVarInfo(ref)
end

function getStatus(reason)
  # detect if program is at end
  if length(RunTime.RunFileStack) == 0
    reason == "exited"
    return Dict("exitCode" => 0), "exited"
  end

  current_file = RunTime.RunFileStack[end]
  line = RunTime.FileLine[current_file]
  description = ""
  if reason == "step"
    description = "step over (ignore breakpoints)"
  elseif reason == "breakpoint"
    description = "hit breakpoint at: " * "$(line)"
  end
  result = Dict("reason" => reason,
                "description" => description,
                "text" => " ")
  return result, "stopped"
end

end # module EventHandler
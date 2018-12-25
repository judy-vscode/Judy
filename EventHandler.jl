module EventHandler

include("RunTime.jl")

function handleEvent(method, params)

  result = Dict()
  event = ""
  event_method = ""

  if method == "initialize"
    event = Dict()
    event_method = "initialized"

  elseif method == "launch"
    EventHandler.init(params["program"])
    put!(RunTime.kRunTimeIn, "launch")
    @async EventHandler.RunTime.run()
    if !haskey(params, "stopOnEntry")
      put!(RunTime.kRunTimeIn, "continue")
      finish_sig = take!(RunTime.kRunTimeOut)
      event, event_method = EventHandler.getStatus("breakpoint")
    else
      event_method = "stopped"
      event = Dict("reason" => "entry",
                   "description" => "stop on entry",
                   "text" => " ")
    end

  elseif method == "setBreakPoints"
    filePath = params["path"]
    lineno = params["lines"]
    result = EventHandler.setBreakPoints(filePath, lineno)

  elseif method == "configurationDone"
    result = Dict()

  elseif method == "continue"
    put!(RunTime.kRunTimeIn, "go on")
    put!(RunTime.kRunTimeIn, "continue")
    finish_sig = take!(RunTime.kRunTimeOut)
    println("EventHandler: recv $(finish_sig)")
    event, event_method = EventHandler.getStatus("breakpoint")
    result = Dict("allThreadsContinued" => true)

  elseif method == "next"
    put!(RunTime.kRunTimeIn, "go on")
    put!(RunTime.kRunTimeIn, "stepOver")
    finish_sig = take!(RunTime.kRunTimeOut)
    event, event_method = EventHandler.getStatus("step")

  elseif method == "stackTrace"
    result = EventHandler.getStackTrace()

  elseif method == "scopes"
    frame_id = params["frameId"]
    result = EventHandler.getScopes(frame_id)

  elseif method == "variables"
    var_ref = params["variablesReference"]
    result = EventHandler.getVariables(var_ref)

  else
    # throw(MsgHandler.UnKnownMethod("$(method) can't be called"))
    result = "$method can't be called"
  end
  return result, event, event_method
end



function init(file)
  RunTime.setEntryFile(file)
end

function setBreakPoints(filepath, lineno)
  return RunTime.setBreakPoints(filepath, lineno)
end

# get stack trace for the current collection
function getStackTrace()
  #return RunTime.DebugInfo.getStackInfo()
  info = RunTime.DebugInfo.getStackInfo()
  results = []
  path = ""
  if length(RunTime.RunFileStack) != 0
    path = RunTime.RunFileStack[end]
  else
    return info
  end
  push!(results, Dict("frameId" => 0,
                      "name" => "top",
                      "path" => path,
                      "line" => RunTime.FileLine[path]))
  for frame in info
    push!(results, frame)
  end
  return results
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
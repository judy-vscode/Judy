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
  res = RunTime.setBreakPoints(filepath, lineno)
  result = []
  id = 1
  for idx in collect(1:1:length(lineno))
    if res[idx]
      push!(result, Dict("verified" => true,
                         "line" => lineno[idx],
                         "id" => id))
      id += 1
    else
      push!(result, Dict("verified" => false))
    end
  end
  return result
end

# get stack trace for the current collection
function getStackTrace()
  #return RunTime.DebugInfo.getStackInfo()
  info = RunTime.DebugInfo.getStackInfo()
  results = []
  path = ""
  line = 1
  if length(RunTime.RunBlockStatus) != 0
    path = collect(keys(RunTime.RunBlockStatus[end]))[1]
    line = RunTime.RunBlockStatus[end][path]
    # clear status since it will be set next break time
    RunTime.clearBlockStatus()
  elseif length(RunTime.RunFileStack) != 0
    path = RunTime.RunFileStack[end]
    line = RunTime.FileLine[path]
  else
    return info
  end
  push!(results, Dict("frameId" => 0,
                      "name" => "top",
                      "path" => path,
                      "line" => line))
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

  path = ""
  line = 1
  if length(RunTime.RunBlockStatus) != 0
    path = collect(keys(RunTime.RunBlockStatus[end]))[1]
    line = RunTime.RunBlockStatus[end][path]
  elseif length(RunTime.RunFileStack) != 0
    path = RunTime.RunFileStack[end]
    line = RunTime.FileLine[path]
  end

  description = ""
  if reason == "step"
    description = "step over (ignore breakpoints)"
  elseif reason == "breakpoint"
    description = "hit breakpoint: $(path): $(line)"
  end
  result = Dict("reason" => reason,
                "description" => description,
                "text" => " ")
  return result, "stopped"
end

end # module EventHandler
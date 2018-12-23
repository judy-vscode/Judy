
module Connecter

using Sockets
import JSON

include("EventHandler.jl")
include("MsgHandler.jl")

function run()
  server = listen(8000)
  sock = accept(server)
  client = connect(18001)

  while isopen(sock)
    # get events
    msg = MsgHandler.msgRecv(sock)
    result = Dict()
    event = ""
    event_method = ""

    # handle events
    id, method, params = MsgHandler.msgParse(msg)

    if method == "initialize"
      event = Dict()
      event_method = "initialized"

    elseif method == "launch"
      EventHandler.init(params["program"])
      if !haskey(params, "stopOnEntry")
        EventHandler.RunTime.run()
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
      result = EventHandler.RunTime.continous()
      event, event_method = EventHandler.getStatus("breakpoint")

    elseif method == "next"
      EventHandler.RunTime.stepOver()
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

    # prepare respond
    response = MsgHandler.msgCreate(id, result)

    # send response
    print(client, response)

    # prepare and send events (if have)
    if event isa Dict
      event = MsgHandler.eventCreate(event_method, event)
      print(client, event)
    end
  end

end 

end   # module debugger

Connecter.run()
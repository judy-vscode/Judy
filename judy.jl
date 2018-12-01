using Sockets
import JSON

include("EventHandler.jl")
include("MsgHandler.jl")

server = listen(8000)
sock = accept(server)
client = connect(18001)

while isopen(sock)

  # get events
  msg = MsgHandler.msgRecv(sock)
  
  result = ""

  # handle events
  id, method, params = MsgHandler.msgParse(msg)
  if method == "continue"
    EventHandler.continous()

  elseif method == "step"
    EventHandler.step()

  elseif method == "setBreakPoints"
    filePath = param["path"]
    lineno = param["lines"]
    EventHandler.setBreakPoints(filePath, lineno)

  elseif method == "initialize"
    EventHandler.readSourceToAST(ARGS[1])
    event = MsgHandler.eventCreate(Dict("method" => "initialize"))
    print(client, event)

  elseif method == "launch"
    if !haskey(params, "stopOnEntry")
      EventHandler.run()
    end
    event = MsgHandler.eventCreate(Dict("method" => "stopOnEntry",
                             "thread" => 1))
    print(client, event)

  elseif method == "clearBreakPoints"
    EventHandler.clearBreakPoints()

  else
    # throw(MsgHandler.UnKnownMethod("$(method) can't be called"))
    result = "$method can't be called"
  end

  # prepare respond
  response = MsgHandler.msgCreate(id, result)

  # send events
  write(sock, response)
end
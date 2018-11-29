using Sockets
import JSON

include("EventHandler.jl")
include("MsgHandler.jl")

server = listen(8000)
while true
    sock = accept(server)
    while isopen(sock)

      # get events
      msg = MsgHandler.msgRecv(sock)

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
      elseif method == "launch"
        EventHandler.readSourceToAST(ARGS[1])
        EventHandler.run()
      elseif method == "clearBreakPoints"
        EventHandler.clearBreakPoints()
      else
        throw(MsgHandler.UnKnownMethod("$(method) can't be called"))
      end

      # prepare respond
      response = MsgHandler.msgCreate(id, "result")

      # send events
      write(sock, response)
    end
end
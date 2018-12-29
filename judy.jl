
module Judy

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

    # handle msgs
    id, method, params = MsgHandler.msgParse(msg)
    # handle events
    result, event, event_method = EventHandler.handleEvent(method, params)
    # prepare respond
    response = MsgHandler.msgCreate(id, result)
    # send response
    print(client, response)

    # prepare and send events (if have)
    if event isa Dict
      event = MsgHandler.eventCreate(event_method, event)
      print(client, event)
    end
    flush(stdout)
  end

end 

end   # module debugger

Judy.run()
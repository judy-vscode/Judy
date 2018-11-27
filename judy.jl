using Sockets
import JSON

include("EventHandler.jl")
include("MsgHandler.jl")

server = listen(8000)
while true
    sock = accept(server)
    while isopen(sock)

      # get events
      recv = readline(sock, keep=true)

      # handle events
      len, id, method, params = MsgHandler.msgParse(recv)
      println("recv: len: $(len), id: $(id), method: $(method), params: $(params)")

      asts = EventHandler.readSourceToAST(ARGS[1])
      EventHandler.run(asts)

      # prepare respond
      response = MsgHandler.msgCreate(id, "result")

      # send events
      write(sock, response)
    end
end
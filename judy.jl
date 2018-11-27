using Sockets
import JSON

include("EventHandler.jl")

server = listen(8000)
while true
    sock = accept(server)
    while isopen(sock)

      # get events
      recv = readline(sock, keep=true)

      # handle events
      #require = JSON.parse(recv)
      #println(require)
      asts = EventHandler.readSourceToAST(ARGS[1])
      EventHandler.run(asts)
      ##print(ast)

      # prepare respond
      respond = Dict("res" => "return results")
      respond = JSON.json(respond)

      # send events
      write(sock, respond)
      @show recv
    end
end
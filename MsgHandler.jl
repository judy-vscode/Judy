module MsgHandler

import JSON
include("EventHandler.jl")

struct UnKnownMethod <: Exception end 

# recieve message from server
# for test: 00000064{"jsonrpc": "2.0", "id": 1, "method": "launch", "params": "abc"}
function msgRecv(sock)
  # read comming message length
  len = read(sock, 8)
  len_str = ""
  for num in len
    len_str = len_str * "$num"
  end
  len = parse(Int, len_str)
  msg = read(sock, len)
  return msg
end

# handle comming msg
# return msg length, id, method, params
function msgParse(msg)

  json_obj = JSON.parse(msg)

  # get msg id
  id = json_obj["id"]
  method = json_obj["method"]
  params = json_obj["params"]
  # len, id, method, params = MsgHandler.msgParse(recv)
  println("recv: len: $(len), id: $(id), method: $(method), params: $(params)")

  return (len, id, method, params)

end

function msgCreate(id, result)
  json_obj = Dict("jsonrpc" => "2.0",
                  "id" => id,
                  "result" => result)
  # to string
  msg = JSON.json(json_obj)
  len = "$(length(msg))"
  msg = ("0" ^ (8 - length(len))) * len * msg
  return msg
end

struct NewBreakPoints
  filepath::AbstractString
  lines::AbstractVector{Integer}
end

function msgHandle(msg)
  try
    len, id, method, params = msgParse(msg)
  catch
    println("Error msg: $(msg) | Not a json rpc format")
    return
  end

  # call debugger
  if method == "continue":
    EventHandler.continous()
  elseif method == "step":
    EventHandler.step()
  elseif method == "setBreakPoints":
    filePath = param["path"]
    lineno = param["lines"]
    EventHandler.setBreakPoints(filePath, lineno)
  elseif method == "launch":
    EventHandler.run()
  elseif method == "clearBreakPoints":
    EventHandler.clearBreakPoints()
  else:
    throw(UnKnownMethod("$(method) can't be called"))
  end

  return
end

end # MsgHandler Module
module MsgHandler

import JSON
include("EventHandler.jl")

# handle comming msg
# return msg length, id, method, params
function msgParse(msg)
  # get first 8 charaters as msg length
  SubString(msg, 1, 8)
  len = parse(Int, SubString(msg, 1, 8))

  true_msg = SubString(msg, 9, lastindex(msg))
  json_obj = JSON.parse(true_msg)

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

struct NewBreakPoints{
  filepath::AbstractString
  lines::AbstractVector{Integer}
}

function msgHandle(msg)
  len, id, method, params = msgParse(msg)
  if method == "continue":
    EventHandler.continue()
  elseif method == "step":
    EventHandler.step()
  elseif method == "setBreakPoints":
    filePath = param["path"]
    lineno = param["lines"]
    EventHandler.setBreanPoints(filePath, lineno)
  elseif method == "launch":
    EventHandler.run()
  elseif method == "clearBreakPoints":
    EventHandler.clearBreakPoints()
  else:
    ErrorMsg = "Undefined Message Method"
    EventHandler.Exception(ErrorMsg)
  return

end
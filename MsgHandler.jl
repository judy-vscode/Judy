module MsgHandler

import JSON

struct UnKnownMethod <: Exception end 

event_id = 0

# recieve message from server
function msgRecv(sock)
  # read comming message length
  len = read(sock, 8)
  len_str = ""
  for num in len
    len_str = len_str * string(Char(num))
  end
  len = parse(Int, len_str)
  # read message
  msg_array = read(sock, len)
  msg = ""
  for ch in msg_array
    msg = msg * Char(ch)
  end
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

  # println("recv id: $(id), method: $(method)")

  return (id, method, params)

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

# create event to notify adapter
function eventCreate(method, params)
  global event_id
  event_id += 1
  json_obj = Dict("jsonrpc" => "2.0",
                  "method" => method,
                  "params" => params)
  msg = JSON.json(json_obj)
  len = "$(length(msg))"
  msg = ("0" ^ (8 - length(len))) * len * msg
  return msg
end


end # MsgHandler Module
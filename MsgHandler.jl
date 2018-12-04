module MsgHandler

import JSON

struct UnKnownMethod <: Exception end 

event_id = 0

# recieve message from server
# for test: 00000064{"jsonrpc": "2.0", "id": 1, "method": "launch", "params": "abc"}
function msgRecv(sock)
  # read comming message length
  # print("msgRecv",curPos)
  # prev_msg = read(sock, curPos)
  # println("prev_msg",prev_msg)
  # dilim = read(sock,1) #eliminate redundant 0x0a
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
  # len, id, method, params = MsgHandler.msgParse(recv)
  println("id: $(id), method: $(method), params: $(params)")

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
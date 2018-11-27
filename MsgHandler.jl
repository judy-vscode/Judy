module MsgHandler

import JSON

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
  




end
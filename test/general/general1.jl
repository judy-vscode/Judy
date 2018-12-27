
include("general2.jl")

# composite type
mutable struct A
  a1::Int64
  a2::Int64
end

mutable struct B
  b1::Int64
  b2::A
end

mutable struct C
  c1::A
  c2::B
end

a1 = A(2, 3) #
a2 = A(3, 4)
b = B(5, a1) #
c = C(a2, b)

function getMax(arr)
  max = arr[1]
  for ele in arr
    if max < ele
      max = ele #
    end
  end
  return max #
end

function getMaxMin(arr)
  result = []
  for sub_arr in arr
    sub_max = getMax(sub_arr)
    push!(result, sub_max) #
  end
  min = getMin(result) #
  return min
end

cnt = 1
query_arr = [] #
while cnt <= 4
  global cnt
  global query_arr
  sub_arr = [cnt, cnt + 1, cnt + 2, cnt + 3] #
  push!(query_arr, sub_arr)
  cnt += 1
end

res = getMaxMin(query_arr) #
println(res)
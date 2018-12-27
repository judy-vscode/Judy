
f = 4

include("file2.jl")

b = 4

d = 3

function f1(x, y)
  n = 3 * x
  m = 2 * y
  return n + m
end

k = f2(a, d)

k = f1(a, d)

println(k) # should be 33


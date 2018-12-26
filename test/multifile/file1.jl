
f = 4

include("file2.jl")

b = 4

d = 3

function f1(x, y)
  2x + y
end

k = f2(f, d)

println(k) # should be 33


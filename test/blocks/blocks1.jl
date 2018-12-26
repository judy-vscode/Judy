
function f1(x, y)
  m = 3 * x
  n = 2 * y
  d = m + n
  return d
end

res = f1(1, 1)
if res < 10
  println("Here1")
else
  println("Here2")
end

s = [1,2,3,4,5,6]

for num in s
  k = num + 1
  println(k)
end
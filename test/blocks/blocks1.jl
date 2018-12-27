
function f1(x, y)
  m = 0
  n = 2

  if x > 10
    m = x - 10
    println("OK")
  else
    m = 3 * x
  end

  while y < 3
    y += 1
    n = 2 * y
  end

  d = m + n
  return d
end

res = f1(1, 1) # should be 9
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
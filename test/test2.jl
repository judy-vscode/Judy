function b1(x, y)
  m = 2 * x
  n = 3 * y
  k = m + n
  return k
end

res = b1(3, 4)
if res > 10
  println("True")
else
  println("False")
end

arr = [1, 2, 3, 4, 5, 6]
for ele in arr
  out = ele * 2
  println(out)
end

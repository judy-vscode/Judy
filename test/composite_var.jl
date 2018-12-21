
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

a1 = A(2, 3)
a2 = A(3, 4)
b = B(5, a1)
c = C(a2, b)

println(c)
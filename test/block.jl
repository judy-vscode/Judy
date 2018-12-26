#ast.head :call
function (a,b)
    c = a + b
    return c
end

#ast.head for
for i in range(4)
    for j in range(3)
        print(i)
    end
end

#ast.head :struct

mutable struct BreakPoints
    filepath::AbstractString
    lineno::Array{Int64,1}
end

#ast.head :if

a = 3
b = 4
if a == b
    if a == 3
        a = 1
    end
else
    if b == 3

        b = 1
    else
        b = 0
    end

end

while a == b begin
        a = 3
    end

end
#[if else]: three args: if (condition) (statement) else (statement)
#[for]: two args: for (condition) (statement)
#[function] :two args : (argument) (body)
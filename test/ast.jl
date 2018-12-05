x = 1

function test1()
	println(1)
	println(2)
	println(3)
	println(4)
end

function test_func(y,z)
    global x
    t = x + y
    z = x + x
    z = z + t
    return z
end

function Breakpoint()
    print('hit breakpoint')
end

a = 1
print(test_func(1,2,3))
b = 1


struct test_struc
    x :: Int64
    y :: AbstractString
end


Channel blockSignal

function wait()
  global blockSignal
  data = take!(blockSignal)  #The function will Block here until blockSignal is not empty
  #Analyze data to get instruction

end



function SetBreakinFunc(codeBlock::AbstractString, offset::Int64)
  ast = Meta.parse(codeBlock)
  Mainblock = ast.args[2]
  ex = Expr(:call, Break, ast)
  Mainblock[2 * offset - 1] = ex
  eval(ast)
end

function helloworld()
  print("helloworld")
end

function testReviseSelf(ast)
  ast.args[2].args[5] = Expr(:call, helloworld)
end

function inter()
  global ast
  testReviseSelf(ast)
end


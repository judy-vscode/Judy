
function testStackTrace()
	c = 3 + 4
	varinf = 2
	fm.f()
	print(names)
	return c
end



varinf = 1
function f()
	varinsb = 2
	gm.g()
end

module gm
	function g()
		varing = 1
		print("sb")
	end
end





# println(testStackTrace())
println("fm",names(fm,all=true))
println("gm",names(gm,all=true))
println("Main",names(Main))

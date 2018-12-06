function g()
	varing = 1
end
function f()
	varinf = 2
	g()
end

function testStackTrace()
	c = 3 + 4
	varinf = 2
	f()
	return c
end

println(testStackTrace())
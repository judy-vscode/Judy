function testStackTrace()
	c = 3 + 4
	#for frame in stacktrace()
	#	println(frame
	#end
	varinf = 2
	# println("vars in testStackTrace()")
	# println(names(Main)[4:end])
	InteractiveUtils.varinfo()
	# println(code_warntype(g))
	return c
end

module fmodule
function f()
	varinf = 2
	# println("vars in f()")
	# println(names(Main)[4:end])
	g()
end
end

function g()
	varing = 1
	# println("vars in g()")
	# println(names(Main)[4:end])
end
module EventHandler

# parse all file into ast, line by line
function readSourceToAST(file)
  asts = []
  open(file) do f
    for ln in eachline(f)
      ex = Meta.parse(ln)
      ast = Meta.lower(Main, ex)
      push!(asts, ast)
    end
  end
  return asts
end

# run whole program
function run(asts)
  line = 0
  for ast in asts
    try
      Core.eval(Main, ast)
    catch err
      # if we run to a breakpoint
      # we will catch an exception and collect info
      return
    end
  end
end



end
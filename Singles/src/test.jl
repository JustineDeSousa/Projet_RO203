include("resolution.jl")

function test(filename)
	x = readInputFile(filename)
	displayGrid(x)
	y, isOptimal, resolutionTime = cplexSolve(x)
	displaySolution(x,y)
end

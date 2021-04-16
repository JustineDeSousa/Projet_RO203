include("resolution.jl")

filename = "./data/instance_t4_2.txt"
nord,sud,ouest,est = readInputFile(filename)
displayGrid(nord,sud,ouest,est)
x, isOptimal, resolutionTime = cplexSolve(nord,sud,ouest,est)
displaySolution(x,nord,sud,ouest,est)
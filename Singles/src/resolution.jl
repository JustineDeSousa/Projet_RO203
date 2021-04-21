#======= Lancer le programme =======#
# path = "D:/M1/" A SPECIFIER
# cd( path * "Projet_RO203/Singles" )
# include("src/resolution.jl")

# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("heuristique.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(x)
	n = size(x,1)
	isOptimal = false
	isGrapheConnexe = true
	it = 0
	
	start = time()
	
	singles = Model(CPLEX.Optimizer)
	
	@variable(singles,y[1:n,1:n],Bin)	# == 1 ssi (i,j) blanche
	@objective(singles,Max,y[1,1])
	
	#Chiffres différents sur une ligne, zero mis à part
	@constraint(singles, lin[k in 1:n, i in 1:n], sum(y[i,j] for j in 1:n if x[i,j] == k) <= 1 )
	#Chiffres différents sur une colonne, zero mis à part
	@constraint(singles, col[k in 1:n, j in 1:n], sum(y[i,j] for i in 1:n if x[i,j]==k) <= 1)

	#pas deux cases voisines noires
	@constraint(singles, black[i in 1:n-1, j in 1:n], y[i,j]+y[i+1,j] >= 1)
	@constraint(singles, black_[j in 1:n-1, i in 1:n], y[i,j]+y[i,j+1] >= 1)

	# Solve the model
	optimize!(singles)
	println("\nJuMP.primal_status(singles) = ", JuMP.primal_status(singles), "\n")
	displaySolution(x,y)
	
	if !is_graph_connexe(y)
		y_m = JuMP.value.(y)
		
		#contraintes de connexité
		@constraint(singles, connexite, sum( y[i,j] for i in 1:n for j in 1:n if y_m[i,j] == 0 ) >= 1)
		
	end

	optimize!(singles)
	println("\n",singles)
	println("JuMP.primal_status(singles) = ", JuMP.primal_status(singles) )

    return y, JuMP.primal_status(singles) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
end

"""
tries many times heuristicSolve1. if solved, prints the grid, else prints:not solved
"""
function heuristicSolve(grille)
	b=0
	n=size(grille,1)
	y=ones(Int,n,n)
	k=0
	while b==0 && k<=10*n
		k=k+1
		b,y=heuristicSolve1(grille)
	end
	if b==0
		println("not solved")
	else
	displaySolution(grille,y)
	end
end

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "data/"
    resFolder = "res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        x = readInputFile(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # Solve it and get the results
                    y, isOptimal, resolutionTime = cplexSolve(x)
                    
                    # If a solution is found, write it
                    if isOptimal
						writeSolution(fout,y)
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            #include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end

x = readInputFile("./data/instance_t3.txt")
displayGrid(x)
y, isOptimal, resolutionTime = cplexSolve(x)
if isOptimal
	displaySolution(x,y)
end
#solveDataSet()
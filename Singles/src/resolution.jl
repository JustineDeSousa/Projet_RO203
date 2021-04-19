# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(x)
	n = size(x,1)
	y_ = zeros(Int,n,n)
	it = 0
	y_mem=[]
	
	# Start a chronometer
	start = time()
		
	while !is_graph_connexe(y_) && it < 10
		println("it=",it)
		# Create the model
		m = Model(CPLEX.Optimizer)
		
		@variable(m,y[1:n,1:n],Bin)	# ==1 ssi (i,j) blanche
		
		#Chiffres différents sur une ligne, zero mis à part
		@constraint(m, [k in 1:n, i in 1:n], sum(y[i,j] for j in 1:n if x[i,j]==k) <= 1)
		#Chiffres différents sur une colonne, zero mis à part
		@constraint(m, [j in 1:n, k in 1:n], sum(y[i,j] for i in 1:n if x[i,j]==k) <= 1)


		#pas deux cases voisines noires
		@constraint(m,[i in 1:n-1, j in  1:n], y[i,j]+y[i+1,j]>=1)
		@constraint(m,[j in 1:n-1, i in 1:n], y[i,j]+y[i,j+1]>=1)

		
		#contrainte de connexité à réfléchir
		println("y_mem=", y_mem)
		for y_m in y_mem
			@constraint(m, sum( 1  for i in 1:n for j in 1:n if (y[i,j] != y_m[i,j]) ) >= 1)
		end
		
		@objective(m,Max,y[1,1])
		
		

		# Solve the model
		optimize!(m)
		
		y_ = JuMP.value.(y)
		push!(y_mem,y)
		println(y_mem)
		isOptimal = JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT
		println("isOptimal= ",isOptimal)
		
		displaySolution(x,map(x->round(Int64,x),y_) )
		it += 1
	end
    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
	# for i in 1:n
		# for j in 1:n
			# print(JuMP.value(y[i,j]))
			# print("  ")
		# end
		# println("")
	# end
    return y_, isOptimal, time() - start
    
    
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
y, isOptimal, resolutionTime = cplexSolve(x)
#displaySolution(x,map(x->round(Int64,x),y) )
#solveDataSet()
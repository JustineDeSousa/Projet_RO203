# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(nord,sud,ouest,est)
	n = size(nord,1)
    # Create the model
    m = Model(CPLEX.Optimizer)

	@variable(m,x[1:n,1:n,1:n],Bin)
	@variable(m,yn[1:n,1:n],Bin)
	@variable(m,ys[1:n,1:n],Bin)
	@variable(m,ye[1:n,1:n],Bin)
	@variable(m,yo[1:n,1:n],Bin)
	
	#Une seule valeur par case
	@constraint(m, [i in 1:n, j in 1:n], sum(x[i,j,k] for k in 1:n) == 1)
	#Chiffres différents sur une ligne
	@constraint(m, [i in 1:n, k in 1:n], sum(x[i,j,k] for j in 1:n) == 1)
	#Chiffres différents sur une colonne
	@constraint(m, [j in 1:n, k in 1:n], sum(x[i,j,k] for i in 1:n) == 1)

	#nb tours visibles respecté
	
	#Nord
	@constraint(m, [j in 1:n], sum(yn[i,j] for i in 1:n)==nord[j])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], yn[i,j]<=1-sum(x[i_,j,k_] for i_ in 1:i-1 for k_ in k:n)/(2*n)+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yn[i,j]>=1-sum(x[i_,j,k_] for i_ in 1:i-1 for k_ in k:n)-2*n*(1-x[i,j,k]))
	
	#Sud
	@constraint(m, [j in 1:n], sum(ys[i,j] for i in 1:n)==sud[j])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], ys[i,j]<=1-sum(x[i_,j,k_] for i_ in i+1:n for k_ in k:n)/(2*n)+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], ys[i,j]>=1-sum(x[i_,j,k_] for i_ in i+1:n for k_ in k:n)-2*n*(1-x[i,j,k]))
	
	#Est
	@constraint(m, [i in 1:n], sum(ye[i,j] for j in 1:n)==est[i])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], ye[i,j]<=1-sum(x[i,j_,k_] for j_ in j+1:n for k_ in k:n)/(2*n)+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], ye[i,j]>=1-sum(x[i,j_,k_] for j_ in j+1:n for k_ in k:n)-2*n*(1-x[i,j,k]))
	
	
	#Ouest
	@constraint(m, [i in 1:n], sum(yo[i,j] for j in 1:n)==ouest[i])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], yo[i,j]<=1-sum(x[i,j_,k_] for j_ in 1:j-1 for k_ in k:n)/(2*n)+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yo[i,j]>=1-sum(x[i,j_,k_] for j_ in 1:j-1 for k_ in k:n)-2*n*(1-x[i,j,k]))
	
	
	#@constraint(m, [j in 1:n], sum(x[i,j,k] for i in 1:n for k in 1:n if isVisible(x,i,j,k,"nord")) == nord[j])
	#@constraint(m, [j in 1:n], sum(x[i,j,k] for i in 1:n for k in 1:n if isVisible(x,i,j,k,"sud")) == sud[j])
	#@constraint(m, [i in 1:n], sum(x[i,j,k] for j in 1:n for k in 1:n if isVisible(x,i,j,k,"ouest")) == ouest[i])
	#@constraint(m, [i in 1:n], sum(x[i,j,k] for j in 1:n for k in 1:n if isVisible(x,i,j,k,"est")) == est[i])
	
	@objective(m,Max,1)
	
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)
	
	println(JuMP.value.(x))

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
	println("yo",JuMP.value.(yo))
	println("ye",JuMP.value.(ye))
	println("ys",JuMP.value.(ys))
    return x,yo,JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    
end

function isVisible(x,i,j,k,bord)
	if bord == "nord"
		for i_ in 1:i-1
			for k_ in k+1:size(x,1)
				if x[i_,j,k_] == 1
					return false
				end
			end
		end
	elseif bord == "sud"
		for i_ in i+1:size(x,1)
			for k_ in k+1:size(x,1)
				if x[i_,j,k_] == 1
					return false
				end
			end
		end
	elseif bord == "ouest"
		for j_ in 1:j-1
			for k_ in k+1:size(x,1)
				if x[i,j_,k_] == 1
					return false
				end
			end
		end
	elseif bord == "est"
		for j_ in j:size(x,1)
			for k_ in k+1:size(x,1)
				if x[i,j_,k_] == 1
					return false
				end
			end
		end
	end
	return true	
end


"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

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
        readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
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
                    
                    # TODO 
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve()
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout") 
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
                
                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end

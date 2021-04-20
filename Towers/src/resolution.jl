#Pour executer le code:
#include("./src/generation.jl")
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

	@variable(m,x[1:n,1:n,1:n],Bin) # ==1 ssi (i,j) contient k
	@variable(m,yn[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis le nord
	@variable(m,ys[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis le sud
	@variable(m,yo[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis l'ouest
	@variable(m,ye[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis l'est
	
	
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
	
	@objective(m,Max,x[1,1,1])
	
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)
	
    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return x,JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    
end


"""
Heuristically solve an instance
"""
function heuristicSolve(nord,sud,ouest,est)
	n = size(nord,1)
	t = Array{Int64,2}(zeros(n,n))
	initialize(t,nord,sud,ouest,est)

    gridFilled = false
    gridStillFeasible = true
	checkFeasibility = true
	
	#Tant que la grille n'est pas remplie et qu'elle est toujours valide
    while !gridFilled && gridStillFeasible
        mcCell = [-1 -1]	# Coordinates of the most constrained cell
        values = nothing	# Values which can be assigned to the mcCell
		
        l = ceil.(Int, n * rand())
        c = ceil.(Int, n * rand())
        
		id = 1
        # For each cell of the grid, while a cell with 0 values has not been found
        while id <= n*n && (values == nothing || size(values, 1)  != 0)
			#Si on n'a pas déjà visité cette case
			if t[l, c] == 0
                cValues = possibleValues(t, l, c, nord, sud, ouest, est)
                #Si c'est la 1ère case ou si on a trouvé une most constrained cell
                if values == nothing || size(cValues, 1) < size(values, 1)
                    values = cValues
					mcCell = [l c]
                end 
            end
			l,c = nextCell(l,c,n)
            id += 1
		end
		
		# If all the cells have a value
        if values == nothing
            gridFilled = true
            gridStillFeasible = true
        else
            # If a cell cannot be assigned any value
            if size(values, 1) == 0
                gridStillFeasible = false
            else# Else assign a random value to the most constrained cell
				newValue = ceil.(Int, rand() * size(values, 1))
                if checkFeasibility
                    gridStillFeasible = false
                    id = 1
                    while !gridStillFeasible && id <= size(values, 1)
                        t[mcCell[1], mcCell[2]] = values[rem(newValue, size(values, 1)) + 1]
                        if isGridFeasible(t, nord, sud, ouest, est)
                            gridStillFeasible = true
                        else
                            newValue += 1
                        end
                        id += 1
                        
                    end
                else
                    t[mcCell[1], mcCell[2]] = values[newValue]
                end
            end 
        end
	end
    return t, gridStillFeasible
end

"""
put the easy values in t
"""
function initialize(t,nord,sud,ouest,est)
	#println("----- Initialization -----")
	n = size(t,1)
	for i in 1:n
		if ouest[i] == n
			for j in 1:n
				t[i,j] = j
			end
		elseif ouest[i] == 1
			t[i,1] = n
			if est[i] == 2
				t[i,n] = n-1
			end
		end
		if est[i] == n
			for j in 1:n
				t[i,j] = n-j+1
			end
		elseif est[i] == 1
			t[i,n] = n
			if ouest[i] == 2
				t[i,1] = n-1
			end
		end
		if nord[i] == n
			for j in 1:n
				t[j,i] = j
			end
		elseif nord[i] == 1
			t[1,i] = n
			if sud[i] == 2
				t[n,i] = n-1
			end
		end
		if sud[i] == n
			for j in 1:n
				t[j,i] = n-j+1
			end
		elseif sud[i] == 1
			t[n,i] = n
			if nord[i] == 2
				t[1,i] = n-1
			end
		end
	end
end

function nextCell(l,c,n)         
	if c < n
		c += 1
	else
		if l < n
			l += 1
			c = 1
		else
			l = 1
			c = 1
		end
	end
	return l,c
end

function possibleValues(t::Array{Int, 2}, l::Int64, c::Int64, nord, sud, ouest, est)
	values = nothing
    for v in 1:size(t, 1)
        if isValid(t, l, c, v, nord, sud, ouest, est)
			if values == nothing
				values = [v]
			else
				values = append!(values, v)
			end
		end
    end 
    return values
end

"""
Test if cell (l, c) can be assigned value v

Arguments
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
- l, c: considered cell
- v: value considered

Return: true if t[l, c] can be set to v; false otherwise
"""
function isValid(t::Array{Int64, 2}, l::Int64, c::Int64, v::Int64, nord, sud, ouest, est)
	n = size(t, 1)
    isValid = true
	
    # Test if v appears in column c
    i = 1
    while isValid && i <= n
        if t[i, c] == v
            isValid = false
        end
        i += 1
    end

    # Test if v appears in line l
    j = 1
    while isValid && j <= n
        if t[l, j] == v
            isValid = false
        end
        j += 1
    end
	
    # Test if the add of v still fits the constraints
	t[l,c] = v
	
	nordSum = 0
	towerMax = 0
	for i in 1:n
		if t[i,c] > towerMax
			nordSum += 1
			towerMax = t[i,c]
		end
	end

	sudSum = 0
	towerMax = 0
	for i in n:-1:1
		if t[i,c] > towerMax
			sudSum += 1
			towerMax = t[i,c]
		end
	end

	ouestSum = 0
	towerMax = 0
	for i in 1:n
		if t[l,i] > towerMax
			ouestSum += 1
			towerMax = t[l,i]
		end
	end

	estSum = 0
	towerMax = 0
	for i in n:-1:1
		if t[l,i] > towerMax
			estSum += 1
			towerMax = t[l,i]
		end
	end

	if nordSum > nord[c] || sudSum > sud[c] || ouestSum > ouest[l] || estSum > est[l]
		isValid = false
	end
	if !isValid
		t[l,c] = 0
	end
    return isValid 
end

function isGridFeasible(t::Array{Int64, 2}, nord, sud, ouest, est)
    n = size(t, 1)
    isFeasible = true
    l = 1
    c = 1
    while isFeasible && l <= n
        if t[l, c] == 0
            feasibleValueFound = false
            v = 1
            while !feasibleValueFound && v <= n
                if isValid(t, l, c, v, nord, sud, ouest, est)
                    feasibleValueFound = true
                end
                v += 1
            end
            if !feasibleValueFound
                isFeasible = false
            end 
        end 
        
		# Go to the next cell
        if c < n
            c += 1
        else
            l += 1
            c = 1
        end
    end
    return isFeasible
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
    #resolutionMethod = ["cplex"]
    resolutionMethod = ["cplex", "heuristique"]

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
        nord,sud,ouest,est = readInputFile(dataFolder * file)
        
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
                    x, isOptimal, resolutionTime = cplexSolve(nord,sud,ouest,est)
                    
                    # If a solution is found, write it
                    if isOptimal
						writeSolution(fout,x)
					end

                # If the method is one of the heuristics
                else
                    isSolved = false
                    solution = []

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        print(".")

                        solution, isOptimal  = heuristicSolve(nord,sud,ouest,est)

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal
                        writeSolution(fout,x)
						println(fout)
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end

solveDataSet()
performanceDiagram("D:/M1/RO203/Projet_RO203/Towers/diagramme.jpg")

#filename = "./data/instance_t4_2.txt"
#nord,sud,ouest,est = readInputFile(filename)
# nord,sud,ouest,est = generateInstance(9)
# displayGrid(nord,sud,ouest,est)
# x, isOptimal, resolutionTime = cplexSolve(nord,sud,ouest,est)
# println("====== Solution avec CPLEX ======")
# displaySolution(x,nord,sud,ouest,est)
# t, isOptimal = heuristicSolve(nord,sud,ouest,est)
# println("== Solution avec l'heuristique ==")
# displaySolution(x,nord,sud,ouest,est)
# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
#using Plots
#import GR

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)
	
	n = length(split(data[1], ","))
    towers = Array{Int64}(undef, n, n, n)
	
	nord= 	map(x->parse(Int64,x),split(data[1],","))
	sud = 	map(x->parse(Int64,x),split(data[2],","))
	ouest = map(x->parse(Int64,x),split(data[3],","))
	est = 	map(x->parse(Int64,x),split(data[4],","))
	
	return nord, sud, ouest, est

end

"""
Display a grid represented by a 2-dimensional array

Argument:
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
"""
function displayGrid(nord,sud,ouest,est)

    n = size(nord, 1)
    
	print("    ")
	for j in 1:n
		print(nord[j]," ")
	end
	println()
    println("   ", "-"^(2*n+1)) 
    
	for i in 1:n
		print(ouest[i]," | ")
		for j in 1:n
			print("  ")
		end
		println("| ",est[i])
	end
	println("   ", "-"^(2*n+1)) 
	print("    ")
	for j in 1:n
		print(sud[j]," ")
	end
	println()
    
end

"""
Display cplex solution

Argument
- x: 3-dimensional variables array such that x[i, j, k] = 1 if cell (i, j) has value k
"""
function displaySolution(x::Array{VariableRef,3}, nord, sud, ouest, est)

    n = size(x, 1)
	t = Array{Int64,2}(zeros(n,n))
	
	#On récupère le tableau t
	for i in 1:n
		for j in 1:n
			for k in 1:n
				t[i,j] += k*round(JuMP.value(x[i,j,k]))
			end
		end
	end
	displaySolution(t,nord,sud,ouest,est)
end
"""
Display heuristic solution

Argument
- t: 2-dimensional variables array such that t[i, j] = k if cell (i, j) has value k
"""
function displaySolution(t, nord, sud, ouest, est)

    n = size(t, 1)
	
	#On écrit
	print("    ")
	for j in 1:n
		print(nord[j]," ")
	end
	println()
    println("   ", "-"^(2*n+1)) 
    
	for i in 1:n
		print(ouest[i]," | ")
		for j in 1:n
			print(t[i,j]," ")
		end
		println("| ",est[i])
	end
	println("   ", "-"^(2*n+1)) 
	print("    ")
	for j in 1:n
		print(sud[j]," ")
	end
	println()
end

"""
Save a grid in a text file

Argument
- t: 2-dimensional array of size n*n
- outputFile: path of the output file
"""
function saveInstance(nord, sud, ouest, est, outputFile::String)

    n = size(nord, 1)

    # Open the output file
    writer = open("./data/"*outputFile, "w")

	for i in 1:n
		print(writer,nord[i])
		if(i<n)
			print(writer,",")
		end
	end
	println(writer)
	for i in 1:n
		print(writer,sud[i])
		if(i<n)
			print(writer,",")
		end
	end
	println(writer)
	for i in 1:n
		print(writer,ouest[i])
		if(i<n)
			print(writer,",")
		end
	end
	println(writer)
	for i in 1:n
		print(writer,est[i])
		if(i<n)
			print(writer,",")
		end
	end
    close(writer)
    
end 

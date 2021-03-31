# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid

Argument
- n: size of the grid
"""
function generateInstance(n::Int64)
	println("in generateInstance")
    towers = Array{Int64}(zeros(n,n))
	
	filledCases = 0
	
			
	while(filledCases < n*n)
		i=Int64(floor(filledCases/n)+1)
		j=rem(filledCases,n)+1
		println("i=",i,"j=",j)
		valTested = Array{Int64}(zeros(0))
		v = ceil.(Int, n * rand())
		push!(valTested,v)
		while !isNumberValuable(towers,i,j,v) && size(valTested,1) < n
			v = ceil.(Int, n * rand())
			if !(v in valTested)
				push!(valTested,v)
			end
			#println(towers)
		end
		
		towers[i,j] = v
		filledCases += 1
		if size(valTested,1) >= n
			towers = Array{Int64}(zeros(n,n))
			filledCases = 0
		end
		
	end
	println("towers= ",towers)
	
	nord = Array{Int64}(zeros(n))
	for j in 1:n
		for i in 1:n
			if isVisible(towers,i,j,"nord")
				#println("isVisible", i, " ", j)
				nord[j]+=1
			end
			
		end
	end

	sud = Array{Int64}(zeros(n))
	for j in 1:n
		for i in 1:n
			if isVisible(towers,i,j,"sud")
				sud[j]+=1
			end
		end
	end
	
	ouest = Array{Int64}(zeros(n))
	for i in 1:n
		for j in 1:n
			if isVisible(towers,i,j,"ouest")
				println("isVisible(",i," ",j,") =", isVisible(towers,i,j,"ouest"))
				ouest[i]+=1
			end
		end
	end
	
    est = Array{Int64}(zeros(n))
	for i in 1:n
		for j in 1:n
			if isVisible(towers,i,j,"est")
				est[i]+=1
			end
		end
	end
	
	
	
	return towers, nord, sud, ouest, est
end

function isNumberValuable(t,i,j,k)
	for i_ in 1:size(t,1)
		if t[i_,j] == k
			return false
		end
	end
	for j_ in 1:size(t,1)
		if t[i,j_] == k
			return false
		end
	end
	return true	
end

function isCellFree(t,i,j)
	if t[i,j] == 0
		return true
	end
	return false
end

function isVisible(t,i,j,bord)
	if bord == "nord"
		for i_ in 1:i
			if t[i_,j] > t[i,j]
				return false
			end
		end
	elseif bord == "sud"
		for i_ in i:size(t,1)
			if t[i_,j] > t[i,j]
				return false
			end
		end
	elseif bord == "ouest"
		for j_ in 1:j
			if t[i,j_] > t[i,j]
				return false
			end
		end
	elseif bord == "est"
		for j_ in j:size(t,1)
			if t[i,j_] > t[i,j]
				return false
			end
		end
	end
	return true	
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end



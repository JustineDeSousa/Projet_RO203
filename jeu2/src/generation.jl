# This file contains methods to generate a data set of instances (i.e., sudoku grids)
#include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64)
	y =[[1 for i=1:n] for i=1:n]
	x =Array{Int64}(zeros(n,n))
	filledCases = 0
	cases_noires=choix_cases_noires(y,n)
	while(filledCases < n*n)
		i = Int64(floor(filledCases/n)+1)
		j = rem(filledCases,n)+1
		if y[i][j]==0
			filledCases+=1
		else
			valTested = Array{Int64}(zeros(0))
			v = ceil.(Int, n * rand())
			push!(valTested,v)
			
			while !isNumberValuable(x,i,j,v) && size(valTested,1) < n
				v = ceil.(Int, n * rand())
				if !(v in valTested)
					push!(valTested,v)
				end
			end
			x[i,j] = v
			filledCases += 1
			
			if size(valTested,1) >= n
				x = Array{Int64}(zeros(n,n))
				filledCases = 0
			end
		end
	end 
	for i=1:n
		for j=1:n
			if x[i,j]==0
				x[i,j]=ceil.(Int, n * rand())
			end
		end
	end
	println("x:",x)
	println("y:",y)
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

generateInstance(3)

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end
function case_entouree_de_case_blanche(y,i::Int64, j::Int64, n::Int64)
	b=1
	if i-1>=1
		if y[i-1][j]==0
			b=0
		end
	end
	if i+1<=n
		if y[i+1][j]==0
			b=0
		end
	end
	if j-1>=1
		if y[i][j-1]==0
			b=0
		end
	end
	if j+1<=n
		if y[i][j+1]==0
			b=0
		end
	end
	return b

end

function voisins_blancs(y,i::Int64, j::Int64, n::Int64)
	v=Tuple{Int64,Int64}[]
	if i-1>=1
		if y[i-1][j]==1
			push!(v,(i-1,j))
		end
	end
	if i+1<=n
		if y[i+1][j]==1
			push!(v,(i+1,j))
		end
	end
	if j-1>=1
		if y[i][j-1]==1
			push!(v,(i,j-1))
		end
	end
	if j+1<=n
		if y[i][j+1]==1
			push!(v,(i,j+1))
		end
	end
	return v

end
function liste_sommets_blancs(y,n)
	liste_sommets_blancs=Tuple{Int64,Int64}[]
	for i in 1:n
		for j in 1:n
			if y[i][j]==1
				push!(liste_sommets_blancs,(i,j))
			end
		end
	end
	return liste_sommets_blancs
end

function arbre_connexe(y,n)
	sommets_a_voir=Tuple{Int64,Int64}[]
	sommets_visites=Tuple{Int64,Int64}[]
	if y[1][1]==1
		push!(sommets_a_voir,(1,1))
	else
		push!(sommets_a_voir,(1,2))
	end
	while sommets_a_voir!=[]
		sommet_traite=sommets_a_voir[1]
		deleteat!(sommets_a_voir,1)
		if !(sommet_traite in sommets_visites)
			i,j=sommet_traite
			push!(sommets_visites,sommet_traite)
			voisins=voisins_blancs(y,i,j,n)
			for l in voisins
				if !(l in sommets_visites)
					if !(l in sommets_a_voir)
						push!(sommets_a_voir,l)
					end
				end
			end
		end
	end
	return sommets_visites
end

function is_graph_connexe(y,n)
	i=size(arbre_connexe(y,n))
	j=size(liste_sommets_blancs(y,n))
	return i==j
end

function choix_cases_noires(y,n)
	liste_cases_admissibles=Tuple{Int64,Int64}[]
	cases_noires=Tuple{Int64,Int64}[]
	for i=1:n
		for j=1:n
			if y[i][j]==1
				if case_entouree_de_case_blanche(y,i,j,n)==1
					push!(liste_cases_admissibles,(i,j))
				end
			end
		end
	end
	while liste_cases_admissibles!=[]
		s=size(liste_cases_admissibles,1)
		r=ceil.(Int, s * rand())
		i,j=liste_cases_admissibles[r]
		y[i][j]=0
		deleteat!(liste_cases_admissibles,r)
		for e in voisins_blancs(y,i,j,n)
			supprimer_doublons(e,liste_cases_admissibles)
		end
		if is_graph_connexe(y,n)
			push!(cases_noires,(i,j))
		else
			y[i][j]=1	
		end
	end
	return cases_noires
end

"y=[[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1]]"
function supprimer_doublons(e,liste)
	s=size(liste,1)
	for i=1:s
		if liste[i]==e
			deleteat!(liste,i)
			break
		end
	end
	return liste
end



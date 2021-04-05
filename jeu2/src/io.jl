

using JuMP
using Plots
import GR

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

    # For each line of the input file
    for line in data

        # TODO
        println("In file io.jl, in method readInputFile(), TODO: read a line of the input file")

    end

end


"""
Create a pdf file which contains a performance diagram associated to the results of the ../res folder
Display one curve for each subfolder of the ../res folder.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""

function displayGrid(x,y)

    n = size(x, 1)
    
	
	println(" ","-"^(2*n+1)) 
	for i in 1:n
		print("| ")
		for j=1:n
			if y[i][j]==1
				print(x[i,j]," ")
			else
				print("* ")
			end
		end
		println("|")
	end
	
    println(" ","-"^(2*n+1))
end
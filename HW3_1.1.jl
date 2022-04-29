using LinearAlgebra
c = float([-3, -4, -5])
b = float([14, 12, 14, 6])
A = [1 2 2.5;1 2 1.33;4 2 5;2 3 1]

basic_variable = [string("x_", string(i)) for i = 1+size(A)[2]:size(A)[1]+size(A)[2]]
all_variables = [string("x_", string(i)) for i = 1:size(A)[1]+size(A)[2]]
eps = 1e-10
OG_working_matrix = vcat(hcat(1, c', zeros(size(A)[1])'), hcat(zeros(size(A)[1]), A, I(size(A)[1])))
OG_rhs = vcat(0,b)
cb = zeros(size(A)[1])'
B = Matrix(float(I(size(A)[1])))
working_matrix = Matrix(OG_working_matrix)
rhs = OG_rhs

function find_min_nonnegative(rhs,column_matrix)
    index = 0 
    minimum_value = rhs[1]/column_matrix[1]
    for i in 1:length(rhs)
        if rhs[i]/column_matrix[i] > 0 && rhs[i]/column_matrix[i] < minimum_value
            index = i
        elseif column_matrix[i] == 0 && rhs[i] > 0
            index = i
        end
    end
    return index
end

counter = 1
while round(minimum(working_matrix[1,:])) < 0
    print("\nOn Iteration ", counter, " B Matrix is:\n")
    display(B)
    print("\nOn Iteration ", counter, " cb Matrix is:\n")
    display(cb)
    # Calculate B inv and Multiplier matrix
    B_inv = inv(B)
    multiplier_matrix = vcat(hcat(1, -cb*B_inv), hcat(zeros(size(B)[1]),B_inv))
    # print("\nOn Iteration ", counter, " Multiplier Matrix is:\n")
    # display(multiplier_matrix)

    # Use the multiplier_matrix to get new working matrix
    working_matrix = round.(multiplier_matrix*OG_working_matrix; sigdigits = 4)
    rhs = round.(multiplier_matrix*OG_rhs; sigdigits = 4)
    working_matrix[abs.(working_matrix) .<= eps] .= 0
    rhs[abs.(rhs) .<= eps] .= 0

    # display(working_matrix)
    # print("\nOn Iteration ", counter, " RHS Matrix is:\n")
    # display(rhs)
    print("\nOn Iteration ", counter, " xb is:\n")
    display(basic_variable)
    print("\nOn Iteration ", counter, " Objective is:\n")
    display(-rhs[1])
    #Find position of minimum negative value or entering variable
    index_min = findall(x-> x==minimum(working_matrix[1,:]) && x!=0, working_matrix[1,:])    
    if length(index_min) == 0
        break
    else       
        # On the column find the row that has least ratio Or leaving variable
        index_min_element = find_min_nonnegative(rhs[2:end], working_matrix[2:end,index_min[1]])
        # print("\nOn Iteration ", counter, " Minimum Index row is:\n")
        # display(index_min_element)
        if index_min_element == 0 || minimum(working_matrix[1,:]) == 0
            break
        else
            # leaving variable
            basic_variable[index_min_element] = string("x_", string(index_min[1]-1))
            B[:,index_min_element] = OG_working_matrix[2:end, index_min[1]]
            cb[1,index_min_element] = OG_working_matrix[1, index_min[1]]
        end
        counter = counter + 1
    end
end

display(working_matrix)
display(rhs)

print("\nFinal objective value is ", rhs[1])
for i = 1:length(basic_variable)
    print("\nValue of variable ", basic_variable[i], " is ", rhs[i+1])
end
for i = length(basic_variable)+1:length(all_variables)
    print("\nValue of variable ", union(basic_variable,all_variables)[i], " is 0")
end
for i = length(basic_variable)+1:length(all_variables)+1
    print("\nShadow price for variable x_",i-1, " is ", working_matrix[1,i])
end
max_shadow = argmax(working_matrix[1,length(basic_variable)+1:length(all_variables)+1])
print("\nMost influential constraint is for is x_",(max_shadow+length(basic_variable)-1), " and the shadow price is " , maximum(working_matrix[1,length(basic_variable)+1:length(all_variables)+1]))
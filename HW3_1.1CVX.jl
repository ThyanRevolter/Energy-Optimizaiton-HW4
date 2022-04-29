using Convex, LinearAlgebra, ECOS

c = float([-3, -4, -5])

b = float([14, 12, 14, 6])

A = [1 2 2.5;1 2 1.33;4 2 5;2 3 1]

x = Variable(3)

objective = minimize(c'*x)

objective.constraints += A*x <= b
objective.constraints += x >= 0
solve!(objective, ECOS.Optimizer())
evaluate(x)
objective.optval

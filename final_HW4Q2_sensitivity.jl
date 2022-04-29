using LinearAlgebra, Plots, JuMP, Clp

include("HW3_2.1 Data.jl")

wind_power = hcat(wind_A, wind_B, wind_C)
# Set of purchased power types
wind_plants = ["wind_A", "wind_B", "wind_C"]
NumPower = length(wind_plants)

# Set of time steps
TimeStart = 1
TimeEnd = 432
TIME = collect(TimeStart:1:TimeEnd) # Collect into a vector
NumTime = length(TIME)

# Data
C_cap = 250000
Lc = 3000
W = 0.0645

# Amount of power in storage at model start [MWh]
InitialStorage = 0


storage_limit_array = [i for i = 0:100:1000]

max_profit = zeros(length(storage_limit_array))
for i = 1:length(storage_limit_array)
    # Maximum amount of power in stroage at any time step [MWh]
    StorageLimit = storage_limit_array[i]

    m = Model(Clp.Optimizer)

    ####################################
    ######## Decision variables ########
    ####################################
    @variable(m, PowerSold[1:NumTime] >= 0)
    @variable(m, Qin[1:NumTime] >= 0)
    @variable(m, Qout[1:NumTime] >= 0)
    @variable(m, SOC[1:NumTime+1] >= 0)

    @objective(m, Max, PowerSold'*price_power - (C_cap/(Lc))*sum(Qout))

    ######################################
    ############# Constraints ############
    ######################################

    # Storage conservation of energy constraint

    @constraint(m, PowerSold .== (wind_A + wind_B + wind_C)./6 + (1-W) .*Qout - Qin)
    @constraint(m, SOC .<= StorageLimit)
    @constraint(m, SOC[1] == 0)
    @constraint(m, Qout .<= 10)
    @constraint(m, SOC[2:end] .== SOC[1:end-1] + Qin[1:end] - Qout[1:end])
    @constraint(m, Qout .<= SOC[1:end-1])


    optimize!(m)

    max_profit[i]  = objective_value(m);
end

plot(storage_limit_array,max_profit, xlabel="Battery capacity MWh", ylabel="Maximum Profit", label ="Sensitivity to Capacity",)
savefig("Sensitivity.png")
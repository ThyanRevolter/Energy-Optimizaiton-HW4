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

# Maximum amount of power in stroage at any time step [MWh]
StorageLimit = 200

m = Model(Clp.Optimizer)

####################################
######## Decision variables ########
####################################
@variable(m, PowerSold[1:NumTime] >= 0)
@variable(m, Qin[1:NumTime] >= 0)
@variable(m, Qout[1:NumTime] >= 0)
@variable(m, SOC[1:NumTime+1] >= 0)

@objective(m, Max, PowerSold'*price_power - (C_cap*StorageLimit/(Lc*StorageLimit))*sum(Qout))

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

Max_profit  = objective_value(m);
Optimal_Qin = value.(Qin);
Optimal_Qout = value.(Qout);
Optimal_SOC = value.(SOC);
Optimal_PowerSold = value.(PowerSold)

plot(Optimal_Qin, label = "Charging Rate Vs Time", xlabel="Time", ylabel="Charging MHh")
savefig("Charging_rate_limit.png")
plot(Optimal_Qout, label = "Discharging Rate Vs Time", xlabel="Time", ylabel="Discharge MHh")
savefig("Discharging_rate_limit.png")
plot(Optimal_SOC, label = "State of Charge Vs Time", xlabel="Time", ylabel="State of Charge MHh")
savefig("SOC_limit.png")
plot(Optimal_PowerSold, label = "Total Power sold Vs Time", xlabel="Time", ylabel="Power Sold MHh")
savefig("PowerSold_limit.png")

using CSV, Tables

# CSV.write("results_limit.csv", Tables.table(hcat(Optimal_Qin,Optimal_Qout,Optimal_SOC[1:end-1],Optimal_PowerSold)), writeheader=false)

print(Max_profit)
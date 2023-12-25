using Pkg
Pkg.activate("./venv_DFT1D")
# Pkg.instantiate()

include("../src/modules/DFT1D.jl")
using .DFT1D

begin
    time_horizon = 3.0f0
    sampling_rate = 48_000.0 # nyquist...
    time = range(0.0f0, time_horizon, Int(round(sampling_rate*time_horizon)))

    input = "toy" 
    # input = "voice"

    if input == "voice" # custom input signal
        signal, sampling_rate = record(time_horizon)
    elseif input == "toy"
        signal = map(time) do t
            # sin(2π * 40 * t) + 0.01f0sin(2π * 4000 * t) # denoising
            # sin(2π * 0.2 * t) + 0.5cos(2π * 0.7 * t) # educational, not periodic
            sin(2π * t/time_horizon) + 0.5cos(2π * 3 * t/time_horizon) # educational, periodic
        end
    end
end

fig = animate_DFT_1D(
    (; signal, sampling_rate, time_horizon, time)
)
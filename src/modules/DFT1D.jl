module DFT1D
    using FFTW: fft, ifft
    using GLMakie
    using Sound: sound, soundsc, record

    include("../figure.jl")
    include("../signal_processing.jl")
    include("../animation.jl")

    export animate_DFT_1D
end # module LVDemo
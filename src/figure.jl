function make_figure()
    fig = Figure(size=(1_200, 1_000))

    sg = SliderGrid(fig[1, 3][1, 1], 
        (label=L"SE", range=1:100:20_001, startvalue=1),
        (label=L"CT~(%)", range=10.0.^range(-14.0f0, 2.0f0 , 500), format="{:.2E}", startvalue=0.0f0),
        width=200,
        tellheight=false
    )
    one_sample_every = sg.sliders[1].value
    compression_threshold = sg.sliders[2].value # percent

    button_signal = Button(fig[1, 3][2, 1], label="Signal", width=200, tellheight=false)
    button_compressed = Button(fig[1, 3][3, 1], label="Compressed", width=200, tellheight=false)

    sliders = (; one_sample_every, compression_threshold)
    buttons = (; signal=button_signal, compressed=button_compressed)
    return (fig, sliders, buttons)
end

function add_plots!(fig::Figure, plots::NamedTuple)
    # time
    ax11, _ = lines(fig[1, 1], plots.signal, color=:black, alpha=0.9, label="signal", axis=(; xlabel="time (s)", title=plots.title11))
    stem!(ax11, plots.signal_sampled, color=:red, stemcolor=:red, markersize=plots.markersize, stemwidth=plots.stemwidth, label="samples")
    axislegend(ax11)

    ax21, _ = lines(fig[2, 1], plots.signal, color=:black, alpha=0.9, label="signal", axis=(; xlabel="time (s)", title=plots.title21))
    stem!(ax21, plots.signal_compressed, color=:blue, stemcolor=:blue, markersize=plots.markersize, stemwidth=plots.stemwidth, label="compressed")
    axislegend(ax21)

    # fourier
    ax12, _ = stem(fig[1, 2], plots.signal_dft_real, color=:red, stemcolor=:red, markersize=plots.markersize, stemwidth=plots.stemwidth, 
        label=L"\mathrm{real}(\hat{F}_k)/||\hat{F}||_\infty", axis=(; xlabel="frequency (Hz)", title="signal DFT")
    )
    stem!(ax12, plots.signal_dft_imag, color=:blue, stemcolor=:blue, markersize=plots.markersize, stemwidth=plots.stemwidth, label=L"\mathrm{imag}(\hat{F}_k)/ ||\hat{F}||_\infty")
    axislegend(ax12)

    ax22, _ = stem(fig[2, 2], plots.signal_dft_weight, color=:purple, stemcolor=:purple, markersize=plots.markersize, stemwidth=plots.stemwidth, label=L"|\hat{F}_k|^2/|\hat{F}|^2", 
        axis=(; xlabel="frequency (Hz)", title="relative energy (log-scale)")
    )
    hlines!(plots.threshold, color=:green, linewidth=2, label=L"CT")
    axislegend(ax22)

    m = minimum(log10.(to_value(plots.signal_dft_weights)))
    M = last(to_value(plots.fourier_frequencies))
    xlims!(ax12, (-0.05f0 * M, 1.05f0 * M))
    xlims!(ax22, (-0.05f0 * M, 1.05f0 * M))
    ylims!(ax22, (m, 0))

    on(plots.fourier_frequencies) do ff
        M = last(ff)
        xlims!(ax12, (-0.05f0 * M, 1.05f0 * M))
        xlims!(ax22, (-0.05f0 * M, 1.05f0 * M))
    end
    on(plots.signal_dft_weights) do w
        m = minimum(log10.(w))
        ylims!(ax22, (m, 0))
    end

    display(fig)
    return fig
end
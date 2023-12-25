function process_signal(signal::NamedTuple, sliders::NamedTuple, buttons::NamedTuple)
    # time domain
    sample_indices = lift(sliders.one_sample_every) do every
        1:every:length(signal.signal)
    end
    samples = lift(sample_indices) do indices
        signal.time[indices]
    end
    signal_sampled = lift(sample_indices) do indices
        signal.signal[indices]
    end
    n_samples = lift(length, samples)

    # DFT processing
    fourier_frequencies = lift(n_samples) do N 
        [n/signal.time_horizon for n in 0:N-1]
    end
    signal_dft = lift(fft, signal_sampled)
    signal_dft_weights = lift(signal_dft) do x
        energy = sum(abs2, x)
        abs2.(x) ./ energy .+ eps(real(eltype(x)))
    end
    signal_compressed = lift(signal_dft, sliders.compression_threshold) do coefficients, threshold
        energy = sum(abs2, coefficients)
        weights = abs2.(coefficients) ./ energy

        signal_dft_compressed = [(100*w > threshold) ? c : zero(c) for (c, w) in zip(coefficients, weights)]
        real(ifft(signal_dft_compressed))
    end

    # compression summary
    max_compression_error = lift(signal_compressed, signal_sampled) do sc, ss
        error = maximum(sc - ss)
        isapprox(error, zero(error)) ? 0 : error/maximum(abs.(ss))*100
    end
    compression_rate = lift(n_samples, signal_dft_weights, sliders.compression_threshold) do N, weights, threshold
        keep = sum(weights) do w 
            (100*w > threshold) ? 1 : 0
        end
        (N - keep)/N * 100
    end

    # axes labels and attributes
    title11 = lift(n_samples) do N
        "signal: $(N) samples"
    end
    title21 = lift(compression_rate, max_compression_error) do cr, mce
        val = round.([cr, mce], digits=2)
        "compression rate: $(val[1])%, relative error $(val[2])%"
    end
    markersize = lift(sliders.one_sample_every) do ose
        (ose - 1)/(1_000 - 1) + 4
    end
    stemwidth = lift(sliders.one_sample_every) do ose
        0.08*(ose - 1)/(1_000 - 1) + 0.0015
    end

    # to avoid synchronization problems
    signal_scale = maximum(abs.(signal.signal))
    plot_signal = [Point2f(t, s/signal_scale) for (t, s) in zip(signal.time, signal.signal)]
    plot_signal_sampled = lift(samples, signal_sampled) do sample, signal_sample
        [Point2f(t, s/signal_scale) for (t, s) in zip(sample, signal_sample)]
    end
    plot_signal_compressed = lift(samples, signal_compressed) do sample, signal_compress
        [Point2f(t, s/signal_scale) for (t, s) in zip(sample, signal_compress)]
    end
    plot_signal_dft_real = lift(fourier_frequencies, signal_dft) do frequencies, signal_fourier
        m = maximum(abs.(signal_fourier))
        [Point2f(ν, real(s)/m) for (ν, s) in zip(frequencies, signal_fourier)]
    end
    plot_signal_dft_imag = lift(fourier_frequencies, signal_dft) do frequencies, signal_fourier
        m = maximum(abs.(signal_fourier))
        [Point2f(ν, imag(s)/m) for (ν, s) in zip(frequencies, signal_fourier)]
    end
    plot_signal_dft_weights = lift(fourier_frequencies, signal_dft_weights) do frequencies, signal_weights
        [Point2f(ν, log10(c)) for (ν, c) in zip(frequencies, signal_weights)]
    end
    threshold = lift(sliders.compression_threshold) do ct
        log10(ct / 100)
    end

    # buttons
    on(buttons.signal.clicks) do _
        @sync soundsc(to_value(signal_sampled), signal.sampling_rate)
    end
    on(buttons.compressed.clicks) do _ 
        @sync soundsc(to_value(signal_compressed), signal.sampling_rate)
    end

    plots = (;
        signal=plot_signal,
        signal_sampled=plot_signal_sampled,
        signal_compressed=plot_signal_compressed,
        signal_dft_real=plot_signal_dft_real,
        signal_dft_imag=plot_signal_dft_imag,
        signal_dft_weight=plot_signal_dft_weights,
        threshold,
        fourier_frequencies,
        signal_dft_weights,
        title11,
        title21,
        markersize,
        stemwidth
    )
    return plots
end
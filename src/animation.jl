function animate_DFT_1D(signal::NamedTuple)
    fig, sliders, buttons = make_figure()
    plots = process_signal(signal, sliders, buttons)
    add_plots!(fig, plots)
end
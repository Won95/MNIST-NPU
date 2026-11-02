# KLayout batch rendering of the actual final GDSII file.
require 'fileutils'
input = $infile || 'physical_design/results/nangate45/mnist_npu/exp_arith_tree_ks/6_final.gds'
output = $outfile || 'portfolio/gds_final.png'
FileUtils.mkdir_p(File.dirname(output))
app = RBA::Application.instance
mw = app.main_window
raise 'No KLayout application main window' if mw.nil?
mw.load_layout(input, 1)
view = mw.current_view
raise 'Failed to load GDS into KLayout' if view.nil?
view.max_hier
view.zoom_fit
view.save_image(output, 1500, 1250)
raise 'GDS render missing' unless File.exist?(output) && File.size(output) > 10000
puts "GDS_RENDER_OK #{File.size(output)} #{output}"

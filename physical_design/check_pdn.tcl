read_db /home/skdml/MNIST-NPU/physical_design/results/nangate45/mnist_npu/5ns_cap_margin25/2_4_floorplan_pdn.odb

puts "\n========== CHECK VDD =========="
check_power_grid -net VDD

puts "\n========== CHECK VSS =========="
check_power_grid -net VSS

read_db /home/skdml/MNIST-NPU/physical_design/results/nangate45/mnist_npu/5ns_cap_margin25/2_2_floorplan_macro.odb

set block [ord::get_db_block]
set dbu [[ord::get_db_tech] getDbUnitsPerMicron]
set core [$block getCoreArea]

puts "CORE_WIDTH_UM: [expr {double([$core dx]) / $dbu}]"
puts "CORE_HEIGHT_UM: [expr {double([$core dy]) / $dbu}]"

set rows [$block getRows]
puts "ROW_COUNT: [llength $rows]"

foreach row [lrange $rows 0 9] {
    puts "ROW: [$row getName] | ORIGIN: [$row getOrigin] | SITE: [[$row getSite] getName]"
}

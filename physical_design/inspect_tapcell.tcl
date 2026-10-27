read_db /home/skdml/MNIST-NPU/physical_design/results/nangate45/mnist_npu/5ns_cap_margin25/2_2_floorplan_macro.odb

set block [ord::get_db_block]
set dbu [[ord::get_db_tech] getDbUnitsPerMicron]
set core [$block getCoreArea]

puts "CORE_XMIN: [expr {double([$core xMin])/$dbu}]"
puts "CORE_XMAX: [expr {double([$core xMax])/$dbu}]"

set row [lindex [$block getRows] 0]
set site [$row getSite]

puts "SITE_WIDTH: [expr {double([$site getWidth])/$dbu}]"
puts "SITE_HEIGHT: [expr {double([$site getHeight])/$dbu}]"

foreach lib [ord::get_db] {
    # Library inspection is performed separately below.
}

set db [ord::get_db]
foreach lib [$db getLibs] {
    foreach master [$lib getMasters] {
        if {[string match "*TAP*" [$master getName]] ||
            [string match "*tap*" [$master getName]]} {
            puts "TAP_MASTER: [$master getName]"
            puts "WIDTH: [expr {double([$master getWidth])/$dbu}]"
            puts "HEIGHT: [expr {double([$master getHeight])/$dbu}]"
        }
    }
}

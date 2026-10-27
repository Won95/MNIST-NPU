set base "/home/skdml/MNIST-NPU/physical_design"
set variant "5ns_cap_margin25"

read_db "$base/results/nangate45/mnist_npu/$variant/2_2_floorplan_macro.odb"

set db [ord::get_db]
set block [ord::get_db_block]
set tech [ord::get_db_tech]
set dbu [$tech getDbUnitsPerMicron]

set core [$block getCoreArea]
set xmin [$core xMin]
set xmax [$core xMax]
set width [expr {$xmax - $xmin}]

# Locate TAPCELL_X1.
set tap_master ""
foreach lib [$db getLibs] {
    set master [$lib findMaster "TAPCELL_X1"]
    if {$master ne "NULL" && $master ne ""} {
        set tap_master $master
        break
    }
}

if {$tap_master eq ""} {
    error "TAPCELL_X1 master not found"
}

set tap_w [$tap_master getWidth]
set tap_h [$tap_master getHeight]

puts "Core width: [expr {double($width)/$dbu}] um"

# Four target columns at 20%, 40%, 60%, 80%.
set targets {}
for {set i 1} {$i <= 4} {incr i} {
    set x [expr {$xmin + round(double($width)*$i/5.0)}]
    lappend targets $x
    puts "Column $i target X: [expr {double($x)/$dbu}] um"
}

# Collect macro bounding boxes.
set macros {}
foreach inst [$block getInsts] {
    set master [$inst getMaster]
    if {[$master isBlock]} {
        lappend macros [$inst getBBox]
    }
}

set count 0

foreach row [$block getRows] {
    set site [$row getSite]
    set site_w [$site getWidth]

    set origin [$row getOrigin]
    set row_x [lindex $origin 0]
    set row_y [lindex $origin 1]

    set row_box [$row getBBox]
    set row_xmin [$row_box xMin]
    set row_xmax [$row_box xMax]
    set row_ymin [$row_box yMin]
    set row_ymax [$row_box yMax]

    foreach target $targets {
        # Snap to the row's placement-site grid.
        set steps [expr {round(double($target-$row_x)/$site_w)}]
        set x [expr {$row_x + $steps*$site_w}]

        if {$x < $row_xmin || ($x+$tap_w) > $row_xmax} {
            continue
        }

        # Skip SRAM macro overlaps.
        set overlap 0
        foreach bbox $macros {
            if {$x < [$bbox xMax] &&
                ($x+$tap_w) > [$bbox xMin] &&
                $row_ymin < [$bbox yMax] &&
                $row_ymax > [$bbox yMin]} {
                set overlap 1
                break
            }
        }

        if {$overlap} {
            continue
        }

        set name "FIXED_TAP_${count}"
        set inst [odb::dbInst_create $block $tap_master $name]

        $inst setOrient [$row getOrient]
        $inst setLocation $x $row_y
        $inst setPlacementStatus FIRM

        incr count
    }
}

puts "Inserted tapcells: $count"

set output "$base/results/nangate45/mnist_npu/$variant/2_3_floorplan_tapcell_4cols_test.odb"
write_db $output

puts "Saved: $output"

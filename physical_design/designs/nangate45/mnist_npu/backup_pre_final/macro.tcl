# ============================================================
# Manual SRAM Macro Placement
# Nangate45 / fakeram45_512x64
#
# Left  column : SRAM0 ~ SRAM2 (3 macros)
# Right column : SRAM3 ~ SRAM6 (4 macros)
#
# Orientation:
#   Left  : MY  (signal pins face center)
#   Right : R0  (signal pins face center)
#
# Placement rules:
#   1. Left/right core boundary margin = 30 um
#   2. Top/bottom core boundary margin = 20 um
#   3. Equal vertical spacing within each column
#   4. Remaining horizontal space allocated between columns
#   5. Automatic core sizing by ORFS
# ============================================================


# ------------------------------------------------------------
# 1. SRAM dimensions (um)
# ------------------------------------------------------------

set sram_w 152.57
set sram_h 113.40

# Core boundary margins
set margin_x 30.0
set margin_y 20.0

# Minimum spacing constraints
set min_gap_x 30.0
set min_gap_y 0.0

# SRAM orientations
set left_orient  MY
set right_orient R0


# ------------------------------------------------------------
# 2. Read actual core dimensions from OpenDB
# ------------------------------------------------------------

set block [ord::get_db_block]
set dbu [$block getDbUnitsPerMicron]
set core [$block getCoreArea]

set xmin [expr {double([$core xMin]) / $dbu}]
set ymin [expr {double([$core yMin]) / $dbu}]
set xmax [expr {double([$core xMax]) / $dbu}]
set ymax [expr {double([$core yMax]) / $dbu}]

set core_w [expr {$xmax - $xmin}]
set core_h [expr {$ymax - $ymin}]

puts "=================================================="
puts " SRAM Manual Macro Placement"
puts "=================================================="
puts "Core X range : $xmin ~ $xmax um"
puts "Core Y range : $ymin ~ $ymax um"
puts "Core width   : $core_w um"
puts "Core height  : $core_h um"


# ------------------------------------------------------------
# 3. Horizontal placement
#
# Core boundary
#
# |--30--| SRAM(MY) |---- gap ----| SRAM(R0) |--30--|
#
# Left/right boundary margins are fixed.
# Remaining horizontal space becomes the center gap.
# ------------------------------------------------------------

set left_x [expr {
    $xmin + $margin_x
}]

set right_x [expr {
    $xmax - $margin_x - $sram_w
}]

set gap_x [expr {
    $right_x - ($left_x + $sram_w)
}]

# Check horizontal feasibility
if {$gap_x < $min_gap_x} {
    error "Insufficient horizontal space: gap_x=$gap_x um, minimum=$min_gap_x um"
}

puts ""
puts "----- Horizontal Placement -----"
puts "Left SRAM X        : $left_x um"
puts "Right SRAM X       : $right_x um"
puts "Left boundary gap  : $margin_x um"
puts "Right boundary gap : $margin_x um"
puts "Center SRAM gap    : $gap_x um"


# ------------------------------------------------------------
# 4. Vertical placement
#
# Left column  : 3 SRAMs, 2 equal gaps
# Right column : 4 SRAMs, 3 equal gaps
#
# Both columns have equal top/bottom margins.
# ------------------------------------------------------------

set usable_h [expr {
    $core_h - 2.0*$margin_y
}]

# Left column: 3 SRAMs
set gap_left [expr {
    ($usable_h - 3.0*$sram_h)/2.0
}]

# Right column: 4 SRAMs
set gap_right [expr {
    ($usable_h - 4.0*$sram_h)/3.0
}]

# Check vertical feasibility
if {$gap_left < $min_gap_y} {
    error "Insufficient height for left SRAM column: gap=$gap_left um"
}

if {$gap_right < $min_gap_y} {
    error "Insufficient height for right SRAM column: gap=$gap_right um"
}

# Top SRAM bottom-left Y coordinate
set top_y [expr {
    $ymax - $margin_y - $sram_h
}]

puts ""
puts "----- Vertical Placement -----"
puts "Top boundary margin    : $margin_y um"
puts "Bottom boundary margin : $margin_y um"
puts "Left column SRAM gap   : $gap_left um"
puts "Right column SRAM gap  : $gap_right um"


# ------------------------------------------------------------
# 5. Place left column
#
# SRAM0 : MY
# SRAM1 : MY
# SRAM2 : MY
#
# Signal pins face right (toward center)
# ------------------------------------------------------------

puts ""
puts "----- Left Column (3 SRAMs, MY) -----"

for {set i 0} {$i < 3} {incr i} {

    set macro_name [format {u_weight_memory.GEN_SRAM\[%d\].u_sram} $i]

    set x $left_x

    set y [expr {
        $top_y - $i*($sram_h + $gap_left)
    }]

    puts "Placing $macro_name at ($x, $y), orientation=$left_orient"

    place_macro \
        -macro_name $macro_name \
        -location [list $x $y] \
        -orientation $left_orient
}


# ------------------------------------------------------------
# 6. Place right column
#
# SRAM3 : R0
# SRAM4 : R0
# SRAM5 : R0
# SRAM6 : R0
#
# Signal pins face left (toward center)
# ------------------------------------------------------------

puts ""
puts "----- Right Column (4 SRAMs, R0) -----"

for {set i 3} {$i < 7} {incr i} {

    set macro_name [format {u_weight_memory.GEN_SRAM\[%d\].u_sram} $i]

    set row [expr {$i - 3}]

    set x $right_x

    set y [expr {
        $top_y - $row*($sram_h + $gap_right)
    }]

    puts "Placing $macro_name at ($x, $y), orientation=$right_orient"

    place_macro \
        -macro_name $macro_name \
        -location [list $x $y] \
        -orientation $right_orient
}


# ------------------------------------------------------------
# 7. Summary
# ------------------------------------------------------------

puts ""
puts "=================================================="
puts " SRAM Manual Placement Completed"
puts "=================================================="
puts "Total SRAM macros : 7"
puts "Left column       : 3 ($left_orient)"
puts "Right column      : 4 ($right_orient)"
puts "Center gap        : $gap_x um"
puts "Left vertical gap : $gap_left um"
puts "Right vertical gap: $gap_right um"
puts "=================================================="

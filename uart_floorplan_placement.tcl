# -----------------------------------------------------------------------
# Floorplan + pad ring placement for uart_top_padded
# (No PDN commands here — pure die/core geometry + pad placement.)
#
# Generic, illustrative OpenROAD-style TCL. Adapt cell names, layer
# names, and site/track info to your actual PDK before use.
# -----------------------------------------------------------------------

# --- 1. Die / core geometry -------------------------------------------
# Die is the full chip outline; core is the placeable area inside the
# pad ring. Leave a "pad ring keepout" gap between them.
set die_lx   0
set die_ly   0
set die_ux   1600   ;# south side: pads span 300-1300 + margin
set die_uy   2400   ;# east/west sides: pads span 300-2100 + margin

set core_margin 150   ;# space reserved for the pad ring itself
set core_lx [expr {$die_lx + $core_margin}]
set core_ly [expr {$die_ly + $core_margin}]
set core_ux [expr {$die_ux - $core_margin}]
set core_uy [expr {$die_uy - $core_margin}]

initialize_floorplan \
    -die_area  "$die_lx $die_ly $die_ux $die_uy" \
    -core_area "$core_lx $core_ly $core_ux $core_uy" \
    -site your_pdk_site

# --- 2. Pad ring placement ----------------------------------------------
# Pads are placed one per side, evenly spaced, in a fixed order around
# the periphery. Power/ground pads are interspersed with signal pads
# (a common rule of thumb: one VDD/VSS pad pair every 4-8 signal pads,
# tune to your library's IR-drop / current spec).

set pad_pitch 200   ;# center-to-center spacing between adjacent pads
set start_loc 300   ;# starting offset for the first pad on each side

# Bottom side: clock + control inputs
place_pad -row IO_SOUTH -location 300  -master ipad  ipad_clk
place_pad -row IO_SOUTH -location 500  -master ipad  ipad_rst
place_pad -row IO_SOUTH -location 700  -master padvdd padvdd_0
place_pad -row IO_SOUTH -location 900  -master padvss padvss_0
place_pad -row IO_SOUTH -location 1100 -master ipad  ipad_wr_en
place_pad -row IO_SOUTH -location 1300 -master ipad  ipad_rdy_clr

# Right side: data_in[7:0]
set x $start_loc
foreach i {0 1 2 3} {
    place_pad -row IO_EAST -location $x -master ipad "ipad_data_in_$i"
    incr x $pad_pitch
}
place_pad -row IO_EAST -location $x -master padvdd padvdd_1
incr x $pad_pitch
place_pad -row IO_EAST -location $x -master padvss padvss_1
incr x $pad_pitch
foreach i {4 5 6 7} {
    place_pad -row IO_EAST -location $x -master ipad "ipad_data_in_$i"
    incr x $pad_pitch
}

# Top side: rdy / busy outputs
place_pad -row IO_NORTH -location 300  -master opad  opad_rdy
place_pad -row IO_NORTH -location 700  -master opad  opad_busy
place_pad -row IO_NORTH -location 1100 -master padvdd padvdd_2
place_pad -row IO_NORTH -location 1300 -master padvss padvss_2

# Left side: data_out[7:0]
set x $start_loc
foreach i {0 1 2 3} {
    place_pad -row IO_WEST -location $x -master opad "opad_data_out_$i"
    incr x $pad_pitch
}
place_pad -row IO_WEST -location $x -master padvdd padvdd_3
incr x $pad_pitch
place_pad -row IO_WEST -location $x -master padvss padvss_3
incr x $pad_pitch
foreach i {4 5 6 7} {
    place_pad -row IO_WEST -location $x -master opad "opad_data_out_$i"
    incr x $pad_pitch
}

# Corner fillers (required to close the ring physically/electrically)
place_corner_pad -master pad_corner -location [list SW SE NW NE]

# --- 3. Sanity check -------------------------------------------------------
check_placement -verbose

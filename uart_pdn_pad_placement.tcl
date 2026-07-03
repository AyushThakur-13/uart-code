# -----------------------------------------------------------------------
# Pad-ring placement + PDN generation for uart_top_padded
#
# Generic, illustrative OpenROAD-style TCL. Adapt cell names, layer
# names, and site/track info to your actual PDK before use. If you're
# on Cadence Innovus / Synopsys ICC2 the *concepts* (ring, pad spacing,
# straps, vias) are the same but the command syntax differs.
# -----------------------------------------------------------------------

# --- 1. Die / core geometry -------------------------------------------
# Die is the full chip outline; core is the placeable area inside the
# pad ring. Leave a "pad ring keepout" gap between them.
set die_lx   0
set die_ly   0
set die_ux   2000
set die_uy   2000

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

# Bottom side: clock + control inputs
place_pad -row IO_SOUTH -location 200  -master ipad  ipad_clk
place_pad -row IO_SOUTH -location 400  -master ipad  ipad_rst
place_pad -row IO_SOUTH -location 600  -master padvdd padvdd_0
place_pad -row IO_SOUTH -location 800  -master padvss padvss_0
place_pad -row IO_SOUTH -location 1000 -master ipad  ipad_wr_en
place_pad -row IO_SOUTH -location 1200 -master ipad  ipad_rdy_clr

# Right side: data_in[7:0]
set x 200
foreach i {0 1 2 3} {
    place_pad -row IO_EAST -location $x -master ipad "ipad_data_in_$i"
    incr x 200
}
place_pad -row IO_EAST -location $x -master padvdd padvdd_1
incr x 200
place_pad -row IO_EAST -location $x -master padvss padvss_1
incr x 200
foreach i {4 5 6 7} {
    place_pad -row IO_EAST -location $x -master ipad "ipad_data_in_$i"
    incr x 200
}

# Top side: rdy / busy outputs
place_pad -row IO_NORTH -location 400  -master opad  opad_rdy
place_pad -row IO_NORTH -location 800  -master opad  opad_busy
place_pad -row IO_NORTH -location 1200 -master padvdd padvdd_2
place_pad -row IO_NORTH -location 1400 -master padvss padvss_2

# Left side: data_out[7:0]
set x 200
foreach i {0 1 2 3} {
    place_pad -row IO_WEST -location $x -master opad "opad_data_out_$i"
    incr x 200
}
place_pad -row IO_WEST -location $x -master padvdd padvdd_3
incr x 200
place_pad -row IO_WEST -location $x -master padvss padvss_3
incr x 200
foreach i {4 5 6 7} {
    place_pad -row IO_WEST -location $x -master opad "opad_data_out_$i"
    incr x 200
}

# Corner fillers (required to close the ring physically/electrically)
place_corner_pad -master pad_corner -location [list SW SE NW NE]

# --- 3. PDN: core power rings/straps -----------------------------------
# Standard 2-layer grid: horizontal straps on one metal, vertical on
# another, tied together at intersections with vias, and stitched out
# to the IO ring's padvdd/padvss cells.

pdn::add_global_connection -net VDD -pin_pattern "^VDD$" -power
pdn::add_global_connection -net VSS -pin_pattern "^VSS$" -ground

set_voltage_domain -name CORE -power VDD -ground VSS

# Core-level ring hugging the placeable area, just inside the pads
pdngen::define_pdn_grid -name core_grid -voltage_domains CORE
pdngen::add_pdn_ring    -grid core_grid -layers {metal5 metal6} \
    -widths 5 -spacings 2 -core_offsets 4

# Horizontal/vertical strap mesh across the core
pdngen::add_pdn_stripe  -grid core_grid -layer metal5 -direction horizontal \
    -width 2 -pitch 60 -offset 20
pdngen::add_pdn_stripe  -grid core_grid -layer metal6 -direction vertical \
    -width 2 -pitch 60 -offset 20

# Connect the mesh layers together and down to standard-cell rails
pdngen::add_pdn_connect -grid core_grid -layers {metal5 metal6}
pdngen::add_pdn_connect -grid core_grid -layers {metal1 metal5}

# Tie the core ring out to the pad ring's padvdd/padvss cells so power
# actually reaches the pads (and from there, the package/bond wires).
pdngen::connect_pads_to_ring -ring core_grid \
    -vdd_pads {padvdd_0 padvdd_1 padvdd_2 padvdd_3} \
    -vss_pads {padvss_0 padvss_1 padvss_2 padvss_3}

pdngen::generate_pdn

# --- 4. Sanity checks ----------------------------------------------------
check_placement -verbose
check_pdn

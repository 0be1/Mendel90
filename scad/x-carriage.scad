//
// Mendel90
//
// GNU GPL v2
// nop.head@gmail.com
// hydraraptor.blogspot.com
//
// X carriage, carries the extruder
//

include <conf/config.scad>
use <bearing-holder.scad>
use <extruder.scad>

hole = extruder_hole(extruder);
width = hole[1] + 2 * bearing_holder_width(X_bearings);

extruder_width = extruder_width(extruder);
function nozzle_x_offset() = extruder_x_offset(extruder);                // offset from centre of the extruder

infinity=200;
length = extruder_length(extruder) + 1;
top_thickness = 2.8;
min_top_thickness = 2;                                                  // recesses for probe and fan screws
rim_thickness = 8;
nut_trap_thickness = 8;
corner_radius = 5;
wall = 2;

nut_flat_rad = squeeze ? nut_trap_flat_radius(M3_nut) : nut_radius(M3_nut);     // bodge for backwards compatibility

base_offset = nozzle_x_offset();      // offset of base from centre
bar_offset = ceil(max(bearing_rod_dia(X_bearings) / 2 + rim_thickness + 1,      // z offset of carriage origin from bar centres
				 nut_flat_rad * 2 + belt_thickness(X_belt) + pulley_inner_radius + 6 * layer_height));

mounting_holes = [[-25, 0], [25, 0]];

function x_carriage_offset() = bar_offset;
function x_bar_spacing() = hole[1] + bearing_holder_width(X_bearings);
function x_carriage_width() = width;
function x_carriage_length() = length;
function x_carriage_thickness() = rim_thickness;
function x_carriage_top_thickness() = top_thickness;
function x_carriage_min_top_thickness() = min_top_thickness;

bar_y = x_bar_spacing() / 2;
bar_x = (length - bearing_holder_length(X_bearings)) / 2;

tooth_height = belt_thickness(X_belt) / 2;
tooth_width = belt_pitch(X_belt) / 2;

lug_width = max(2.5 * belt_pitch(X_belt), 2 * (M3_nut_radius + 2));
lug_depth = X_carriage_clearance + belt_width(X_belt) + belt_clearance + M3_clearance_radius + lug_width / 2;
lug_screw = -(X_carriage_clearance + belt_width(X_belt) + belt_clearance + M3_clearance_radius);
slot_y =  -X_carriage_clearance - (belt_width(X_belt) + belt_clearance) / 2;

function x_carriage_belt_gap() = length - lug_width;

clamp_thickness = 3;
dowel = 5;
dowel_height = 2;

tension_screw_pos = 8;
tension_screw_length = 25;

function x_carriage_lug_width() = lug_width;
function x_carriage_lug_depth() = lug_depth;
function x_carriage_dowel() = dowel;

module belt_lug(motor_end) {
	height = motor_end ? x_carriage_offset() - pulley_inner_radius:
						 x_carriage_offset() - ball_bearing_diameter(X_idler_bearing) / 2;

	height2 = motor_end ? height + clamp_thickness : height;
	width = lug_width;
	depth = lug_depth;
	extra = 0.5;            // extra belt clearance

	union() {
		difference() {
			union() {
				translate([width / 2, -depth + width / 2])
					cylinder(r = width / 2, h = height2 + (motor_end ? M3_nut_trap_depth : 0));
				translate([0, -(depth - width / 2)])
					cube([width, depth - width / 2, height2]);
			}

			translate([width / 2, slot_y, height - belt_thickness(X_belt) / 2 + 2 * eta])                   // slot for belt
				cube([width + 1, belt_width(X_belt) + belt_clearance, belt_thickness(X_belt)], center = true);

			translate([width / 2, lug_screw, height2 + M3_nut_trap_depth + eta])
				nut_trap(M3_clearance_radius, M3_nut_radius, M3_nut_trap_depth);

			// slot to join screw hole
			translate([width / 2,  -(X_carriage_clearance + belt_width(X_belt) + belt_clearance),
					   height - belt_thickness(X_belt) / 2 + extra /2])
				cube([M3_clearance_radius * 2, M3_clearance_radius * 2, belt_thickness(X_belt) + extra], center = true);

			if(motor_end) {
				translate([width, slot_y, (height - belt_thickness(X_belt)) / 2])                       // tensioning screw
					rotate([90, 0, 90])
						nut_trap(M3_clearance_radius, M3_nut_radius, M3_nut_trap_depth, true);

				translate([width / 2, slot_y, height - (belt_thickness(X_belt) - extra) / 2 - eta])                 // clearance slot for belt
					cube([width + 1, belt_width(X_belt) + extra, belt_thickness(X_belt) + extra], center = true);
			}
		}
		if(motor_end)
			//
			// support membrane
			//
			translate([width / 2, lug_screw, height + extra + layer_height / 2 - eta])
				cylinder(r = M3_clearance_radius + 1, h = layer_height, center = true);
		else
			for(i = [-1:1])                                                                                 // teeth to grip belt
				translate([width / 2 + i * belt_pitch(X_belt), slot_y, height- belt_thickness(X_belt) + tooth_height / 2 - eta ])
					cube([tooth_width, belt_width(X_belt) + belt_clearance + eta, tooth_height], center = true);

	}
}

loop_dia = x_carriage_offset() - pulley_inner_radius - belt_thickness(X_belt);
loop_straight = tension_screw_length + wall - loop_dia / 2 - tension_screw_pos - lug_width / 2;
belt_end = 15;

module belt_loop() {
	height = loop_dia + 2 * belt_thickness(X_belt);
	length = loop_straight + belt_end;

	color(belt_color)
	translate([loop_dia / 2, 0, 0])
		linear_extrude(height = belt_width(X_belt), convexity = 5, center = true)
			difference() {
				union() {
					circle(r = height / 2, center = true);
					translate([0, -height / 2])
						square([length, height]);
				}
				union() {
					circle(r = loop_dia / 2, center = true);
					translate([0, -loop_dia / 2])
						square([length, loop_dia]);
				}
				translate([loop_straight, -height])
					square([100, height]);
			}
}

function x_belt_loop_length() = PI * loop_dia / 2 + loop_straight * 2 + belt_end;

module x_belt_clamp_stl()
{
	height = clamp_thickness;
	width = lug_width;
	depth = lug_depth;

	stl("x_belt_clamp");
	union() {
		difference() {
			union() {
				translate([width / 2, -depth + width / 2])
					cylinder(r = width / 2, h = height + M3_nut_trap_depth);
				translate([0, -(depth - width / 2)])
					cube([width, depth - width / 2, height]);
			}
			translate([width / 2, lug_screw, height + M3_nut_trap_depth])
				nut_trap(M3_clearance_radius, M3_nut_radius, M3_nut_trap_depth);
		}
   }
}

module x_belt_grip_stl()
{
	height = clamp_thickness + belt_thickness(X_belt);
	width = lug_width;
	depth = lug_depth;

	stl("x_belt_grip");
	union() {
		difference() {
			linear_extrude(height = height, convexity = 5)
				hull() {
					translate([width / 2, -depth + width / 2])
						circle(r = width / 2);
					translate([0, -(depth - width / 2 - dowel)])
						square([width, depth - width / 2]);
				}
			translate([width / 2, lug_screw, -1])
				poly_cylinder(r = M3_clearance_radius, h = height + 2);                                // clamp screw hole

			translate([width / 2,  -(X_carriage_clearance + belt_width(X_belt) + belt_clearance), height])  // slot to join screw hole
				cube([M3_clearance_radius * 2, M3_clearance_radius * 2, 2 * belt_thickness(X_belt)], center = true);

			translate([width / 2, slot_y, height - belt_thickness(X_belt) / 2 + 2 * eta])                   // slot for belt
				cube([width + 1, belt_width(X_belt) + belt_clearance, belt_thickness(X_belt)], center = true);
		}
		translate([width / 2, dowel / 2, eta])
			cylinder(r = dowel / 2 - 0.1, h = height + dowel_height);

		for(i = [-1:1])                                                                                     // teeth
			translate([width / 2 + i * belt_pitch(X_belt), slot_y, height - belt_thickness(X_belt) + tooth_height / 2 - eta ])
				cube([tooth_width, belt_width(X_belt) + belt_clearance + eta, tooth_height], center = true);
	}
}
belt_tensioner_rim = X_carriage_clearance;
belt_tensioner_rim_r = 2;
belt_tensioner_height = belt_tensioner_rim + belt_width(X_belt) + belt_clearance + belt_tensioner_rim;

function x_belt_tensioner_radius() = (x_carriage_offset() - pulley_inner_radius - belt_thickness(X_belt)) / 2;

module x_belt_tensioner_stl()
{
	stl("x_belt_tensioner");

	flat = 1;
	d = 2 * x_belt_tensioner_radius();

	module d(r, w) {
		difference() {
			union() {
				circle(r, center = true);
				translate([0, -r])
					square([w + 1, 2 * r]);
			}
			translate([w, - 50])
				square([100, 100]);
		}
	}

	difference() {
		translate([d / 2, 0, 0]) union() {
			linear_extrude(height = belt_tensioner_height)
				d(d / 2, flat);

			linear_extrude(height = belt_tensioner_rim)
				d(d / 2 + belt_tensioner_rim_r, flat);
		}
		translate([wall, 0, belt_tensioner_height / 2])
			rotate([90, 0, 90])
				teardrop(r = M3_clearance_radius, h = 100);
	}
}

dual_fan_duct_clearance = max(10, top_thickness);

duct_wall = 2 * layer_height;   // Skeinforge always makes two walls, so if this is less than twice the filament width it ends about twice the filament width but more strongly bonded.
duct_bottom_thickness = 3 * layer_height;
duct_top_thickness = 4 * layer_height;
fan_nut_trap_thickness = 4;
fan_bracket_thickness = 3;

fan_screw = fan_screw(part_fan);
fan_nut = screw_nut(fan_screw);
fan_washer = screw_washer(fan_screw);
fan_screw_length = screw_longer_than((fan_is_radial(part_fan) ? 2*fan_depth(part_fan) + dual_fan_duct_clearance + washer_thickness(fan_washer) + 2 * duct_wall: fan_depth(part_fan) + fan_bracket_thickness + fan_nut_trap_thickness) + nut_thickness(fan_nut, true) + washer_thickness(fan_washer));

fan_duct_width = fan_is_radial(part_fan) ? 2* fan_depth(part_fan) + dual_fan_duct_clearance + 4*duct_wall: fan_width(part_fan);
fan_duct_height = fan_duct_height() + 2 * duct_wall;
front_nut_pitch = min((bar_x - bearing_holder_length(X_bearings) / 2 - nut_radius(M3_nut) - 0.3), fan_hole_pitch(part_fan) - 5);
front_nut_width = 2 * nut_radius(M3_nut) + wall + ((2 * front_nut_pitch < 2 * nut_radius(M3_nut) + 3 * wall) ? wall : 0);
front_nut_height = 2 * nut_radius(M3_nut) * cos(30) + wall + top_thickness - min_top_thickness;
front_nut_depth = min(bearing_holder_width(X_bearings) - 2 * wall - nut_thickness(M3_nut, true) - 1, nut_trap_depth(M3_nut) + 6);
front_nut_z = 5;
front_nut_y = width / 2 + hot_end_duct_offset(hot_end)[1];

gap = 6;
taper_angle = 30;
nozzle_height = 6; // 6
nozzle_extra_height = 0; // XXX

duct_height_nozzle = hot_end_duct_height_nozzle(hot_end);   // Thickness on the exit side
ir = hot_end_duct_radius(hot_end);
fan_duct_depth = 15;
fan_duct_nozzle_depth = 3;

or = ir + duct_wall + gap + duct_wall;
skew = nozzle_height * tan(taper_angle);

zip_x = min(length / 2 - lug_width - zipslot_width() / 2 - eta, bar_x);

fan_x = base_offset;
fan_y = -(width / 2  + fan_duct_width/ 2) - (2 * X_carriage_clearance + belt_width(X_belt) + belt_clearance);

fan_x_duct = fan_x - hot_end_duct_offset(hot_end)[0] - fan_duct_width / 2;
fan_y_duct = -fan_y + hot_end_duct_offset(hot_end)[1];

sh = nozzle_length(hot_end) + hot_end_duct_offset(hot_end)[2];

function skew(l, sa) = l / tan(sa);
function neck_y() = front_nut_y;

/*module bearing_clearance() {
translate([bearing_holder_length(X_bearings) / 2, bearing_holder_width(X_bearings) / 2,  bearing_holder_width(X_bearings) / 2])
rotate([180,0,0])
	translate([base_offset, 0, - nozzle_length(hot_end) - exploded * 15] - hot_end_duct_offset(hot_end))
				for(end = [-1, 0, 1])
					translate([end * bar_x, end ? -bar_y : bar_y, bar_offset - hot_end_bodge(hot_end) ] * 1)
						rotate([0, 0, 90])
							cube([bearing_holder_width(X_bearings), bearing_holder_length(X_bearings), bearing_holder_width(X_bearings) ]);


}*/

module fan_duct_nozzle(ir, or, h, sa, t=duct_wall) {
	h2 = skew(or - ir, sa);

	h1 = h - h2;

	difference() {
		hull() {
			union() {
				cylinder(r1 = ir, r2 = or, h = h2);
				translate([0, 0, h2 - eta])
						cylinder(r = or, h = h1);
			}
			translate([-or, or, 0])
				cube([2*or, 2 * eta, h]);
		}

		// nozzle exit slot
		translate([0, 0, -2 * eta])
			difference() {
				union() {
					or = or - t;
					ir = ir - t;
					cylinder(r1 = ir, r2 = or, h = h2);
					hull() {
						translate([0, 0, h2 - 2 * eta])
							cylinder(r = or, h = infinity);
						translate([-or, infinity, h1])
							cube([2 * or, 2 * eta, infinity]);
					}
				}
			}
	}
}

module x_carriage_fan_duct_cap_stl(ir=ir, or=or + skew, h1=duct_height_nozzle - duct_top_thickness, h2=nozzle_height, sa=taper_angle, t=duct_top_thickness, b=duct_wall) {
	stl("x_carriage_fan_duct_cap");

	h = h1 - h2;

	difference() {
		union() {
			// nozzle cover
			hull() {
				cylinder(r = or, h = t);
					translate([-or, or, 0])
				cube([2*or, 2 * eta, t]);
			}
			
			// hot end duct body
			union() {
				ir = ir + b;
				translate([0, 0, -h]) {
					cylinder(r = ir, h = h);
					translate([0,0, -h2])
						cylinder(r2 = ir, r1 = ir - h2*tan(sa), h = h2);
				}
			}
		}
		// hot end duct hole
		union() {
			translate([0, 0, -h]) {
				cylinder(r = ir, h = infinity);
				translate([0, 0, -h2 - 2*eta])
					cylinder(r2 = ir, r1 = ir - h2*tan(sa), h = h2 + 4*eta);
			}
		}
	}
 	intersection() {
		translate([-infinity/2,0,0])
		hull() {
 			translate([0, or, 0])
				cube([infinity, 2 * eta, t]);
			translate([0, neck_y() + fan_duct_depth, fan_duct_height - h1 -b])
				cube([infinity, 2 * eta, t]);
		}
		translate([0,0, -infinity/2])
	 	hull() {
			translate([fan_x_duct, neck_y(), 0])
			    cube([fan_duct_width, 2 * eta , infinity]);
			translate([-or, or, 0])
				cube([2*or, 2 * eta, infinity]);
		}
	}
}


module x_carriage_fan_duct_stl() {
	stl("x_carriage_fan_duct");

	r1 = or;
	r2 = r1 + skew;
	h1 = nozzle_height;

	h = duct_height_nozzle - duct_top_thickness;
	fan_duct_nozzle(r1, r2, h, taper_angle);

	difference() {
	difference() { // shaft
		union() {
			difference() {
				union() {
					difference() {
						union() {                                    
							// neck
							intersection() {
								translate([-infinity/2, 0, 0])
						 		hull() {
									translate([0, neck_y() + fan_duct_depth, 0])
									    cube([infinity, 2 * eta , fan_duct_height - duct_wall]);
									translate([0, r2, 0])
										cube([infinity, 2 * eta, h]);
								}
								translate([0, 0, -infinity/2])
									hull() {
										translate([-r2, r2, 0])
											cube([2*r2, 2 * eta, infinity]);
										translate([fan_x_duct, neck_y(), 0])
											cube([fan_duct_width, 2*eta, infinity]);
									}
							}

							// fan input
								translate([fan_x_duct, neck_y(), 0]) { 
									cube([fan_duct_width, fan_duct_depth + fan_duct_nozzle_depth, fan_duct_height]);
								}

						}

						// neck
						hull() {
							inner_r2 = r2 - duct_wall;
							translate([fan_x_duct + duct_wall, neck_y(), duct_wall])
								cube([fan_duct_width - 2*duct_wall, 2 * eta , infinity]);
							translate([-inner_r2, r2 - 2*eta, h1])
								cube([2*inner_r2, 2 * eta, infinity]);
						}

						// opening
						translate([fan_x_duct + duct_wall, 0, 0]) { 
							l = fan_duct_width - 2 * duct_wall;
							h2 =  fan_duct_height - 2 * duct_wall;
							intersection() {
								translate([0, 0, duct_wall])
									hull() {
										translate([0, neck_y() + fan_duct_depth, 0])
									 		cube([l, 2 * eta , h2]);
								
										translate([0, r2, 0])
											cube([l, 2 * eta, h - duct_wall]);
									}
								translate([0, neck_y(), -infinity/2])	
									cube([l, infinity ,infinity]);
							}
							translate([0, neck_y() + fan_duct_depth, duct_wall])
								cube([l, infinity ,h2]);
						}
				}
			 }
			  //
			  // Cold end cooling vent
			  //
			  rotate([0, 0, atan2(-fan_x, -fan_y)])
				  translate([0, ir + skew, h - 3])
					  rotate([90, 0, 0])
						  teardrop(r = 4.5 / 2, h = 10, center = true);
			}
			// shaft wall
		   translate([fan_x_duct + fan_duct_width / 2, neck_y() + fan_duct_depth + fan_duct_nozzle_depth, nozzle_extra_height]) {
				d = min(fan_duct_depth + fan_duct_nozzle_depth, dual_fan_duct_clearance + 2 * duct_wall);
				depth = fan_duct_depth /2 + fan_duct_nozzle_depth;
				translate([-d/2, -depth, 0]) {
					h = fan_duct_height;
	   
					union() {
						cube([d, depth, h]);
						translate([d/2, 0, 0])
							cylinder(d=d, h=h);
					}
				}
			}
	} // union shaft

	// shaft 
    translate([fan_x_duct + fan_duct_width / 2, neck_y() + fan_bracket_thickness + dual_fan_duct_clearance / 2, duct_wall + nozzle_extra_height]) {
		w = dual_fan_duct_clearance + 2*eta;
		translate([-w/2, 0,0]) {
			d = dual_fan_duct_clearance;
			translate([0, 0, -infinity/2]) {
				cube([w, infinity, infinity]);
				translate([d/2,0,0])
					cylinder(d=d, h=infinity);
			}
		}
	}

	
	} // difference shaft

								intersection() {
									translate([-infinity/2, 0, 0])
										hull() {
#											translate([0, neck_y() + fan_duct_depth, fan_duct_height - duct_wall + duct_top_thickness])
												cube([infinity, 2*eta, infinity]);
											translate([0, r2, duct_height_nozzle])
												cube([infinity, 2*eta, infinity]);
									}
									translate([-infinity/2, neck_y() + fan_bracket_thickness, 0])
										cube([infinity, infinity, infinity]);
								}
	}
	// fan bracket
	translate([fan_x_duct, neck_y(), fan_duct_height]) {
		r2 = sh - fan_duct_height;
		//wall
		difference() {
			cube([fan_duct_width, fan_bracket_thickness, r2]);
			translate([fan_duct_width/2 - front_nut_pitch, 0, r2 - front_nut_z - duct_top_thickness])
				for(side=[0,2]) {
					r = screw_clearance_radius(M3_cap_screw);
					translate([side * front_nut_pitch, 0, 0]) {
						rotate([90,0,0])
							cylinder(r=r, h=infinity, center=true);
						translate([-r, -infinity/2, 0])
							cube([r * 2, infinity, infinity]);
					}
				}
		}

		// bracket
		translate([fan_duct_width /2 , 0, 0])
			difference() {
				inner_d = 4.5;
				outer_d = inner_d + 2 * fan_bracket_thickness;
				fan_hole_y = fan_duct_depth + 7;
				fan_hole_z = 20 - duct_wall;
				
				union() {
					hull() {
						translate([- fan_bracket_thickness/2, 2 + fan_bracket_thickness, r2])  
							rotate([180,0,0])
								cube([fan_bracket_thickness, 2, 2*(r2 - fan_hole_z)]);
						translate([0, fan_hole_y, fan_hole_z])
							rotate([0,90,0])
								cylinder(d=outer_d, h=fan_bracket_thickness, center=true);
					}

					translate([0, fan_hole_y, fan_hole_z])
						rotate([0,90,0])
							cylinder(d=outer_d, h=dual_fan_duct_clearance  + 2 * duct_wall - 4 * eta, center=true);
				}
				translate([0, fan_hole_y, 20])
					rotate([0,90,0])
						cylinder(d=inner_d, h=infinity, center=true);
			}

*		translate([fan_bracket_thickness, fan_bracket_thickness, 0])
			for(side=[0,1])
				translate([side * (fan_duct_width - fan_bracket_thickness), 0, 0])
					rotate([0,-90,0])
						linear_extrude(fan_bracket_thickness)
							polygon([[0,0],[0, fan_duct_depth - fan_bracket_thickness], [r2, 0]]);
				
	}
}


module x_carriage_fan_bracket_stl() {
}

bearing_gap = 5;
bearing_slit = squeeze ? 0.5 : 1;

hole_width = hole[1] - wall - bearing_slit;
hole_offset = (hole[1] - hole_width) / 2;


module base_shape() {
	difference() {
		hull() {
			translate([-length / 2, -width / 2])
				square();

			translate([ length / 2 - 1, -width / 2])
				square();

			translate([bearing_holder_length(X_bearings) / 2 + bearing_gap, width / 2 - corner_radius])
				circle(r = corner_radius, center = true);

			translate([-bearing_holder_length(X_bearings) / 2 - bearing_gap, width / 2 - corner_radius])
				circle(r = corner_radius, center = true);

			translate([-length / 2 + corner_radius, extruder_width / 2 ])
				circle(r = corner_radius, center = true);

			translate([ length / 2 - corner_radius , extruder_width / 2])
				circle(r = corner_radius, center = true);
		}
		translate([0, width / 2 - (bearing_holder_width(X_bearings) + bearing_slit) / 2 + eta])
			square([bearing_holder_length(X_bearings) + 2 * bearing_gap,
					 bearing_holder_width(X_bearings) + bearing_slit ], center = true);
	}
}


module x_carriage_stl(){
	stl("x_carriage");

	translate([base_offset, 0, top_thickness])
		difference(){
			union(){
				translate([0, 0, rim_thickness / 2 - top_thickness]) {
					difference() {
						union() {
							// base plate
							difference() {
								linear_extrude(height = rim_thickness, center = true, convexity = 5)
									base_shape();

								translate([0, 0, top_thickness])
									linear_extrude(height = rim_thickness, center = true, convexity = 5)
										difference() {
											offset(-wall)
												base_shape();

											translate([-base_offset, -hole_offset])
												rounded_square(hole[0] + 2 * wall, hole_width + 2 * wall, hole[2] + wall);
										}
							}
							// ribs between bearing holders
							for(side = [-1,1]) {
								rib_height = bar_offset - X_bar_dia / 2 - 2;
								translate([0, - bar_y + side * (bearing_holder_width(X_bearings) / 2 - (wall + eta) / 2), rib_height / 2 - top_thickness + eta])
									cube([2 * bar_x - bearing_holder_length(X_bearings) + eta, wall + eta, rib_height], center = true);
							}
							// Front nut traps for large fan mount
							for(end = [-1, 1])
								translate([end * (bar_x - bearing_holder_length(X_bearings) / 2 - front_nut_width / 2 + eta) - front_nut_width / 2,
											-width / 2 + wall, -top_thickness - eta])
									 cube([front_nut_width, front_nut_depth, front_nut_height]);
						 }
						//Holes for bearing holders
						translate([0,        bar_y, rim_thickness - top_thickness - eta])
							cube([bearing_holder_length(X_bearings) - 2 * eta, bearing_holder_width(X_bearings) - 2 * eta, rim_thickness * 2], center = true);

						translate([- bar_x, -bar_y, rim_thickness - top_thickness - eta])
							cube([bearing_holder_length(X_bearings) - 2 * eta, bearing_holder_width(X_bearings) - 2 * eta, rim_thickness * 2], center = true);

						translate([+ bar_x, -bar_y, rim_thickness - top_thickness - eta])
							cube([bearing_holder_length(X_bearings) - 2 * eta, bearing_holder_width(X_bearings) - 2 * eta, rim_thickness * 2], center = true);
					}
				}
				//
				// Floating bearing springs
				//
				for(side = [-1, 1])
					translate([0, bar_y + side * (bearing_holder_width(X_bearings) - min_wall - eta) / 2, rim_thickness / 2 - top_thickness])
						cube([bearing_holder_length(X_bearings) + 2 * bearing_gap + 1, min_wall, rim_thickness], center = true);

				// raised section for nut traps
				for(xy = mounting_holes)
					translate([xy[0] - base_offset, xy[1], (nut_trap_thickness - top_thickness) / 2])
						cylinder(r = 7, h = nut_trap_thickness - top_thickness, center = true);

				// belt lugs
				translate([-length / 2, -width / 2 + eta, -top_thickness])
					belt_lug(true);

				translate([ length / 2, -width / 2 + eta, -top_thickness])
					mirror([1,0,0])
						belt_lug(false);

				//Bearing holders
				for(end = [-1, 0, 1])
					translate([end * bar_x, end ? -bar_y : bar_y, bar_offset - top_thickness])
						rotate([0, 0, 90])
							bearing_holder(X_bearings, bar_offset - eta, tie_offset = end * (zip_x - bar_x));

			}
			translate([-base_offset, 0, 0]) {
				// hole to clear the hot end
				translate([0, - hole_offset])
					rounded_rectangle([hole[0], hole_width, 2 * rim_thickness], hole[2]);

				// holes for connecting extruder
				for(xy = mounting_holes)
					translate([xy[0], xy[1], nut_trap_thickness - top_thickness])
						nut_trap(M4_clearance_radius, M4_nut_radius, M4_nut_trap_depth);

			}
			//
			// Belt grip dowel hole
			//
			translate([-length / 2 + lug_width / 2, -width / 2 + dowel / 2, -top_thickness])
				cylinder(r = dowel / 2 + 0.1, h = dowel_height * 2, center = true);
			//
			// Front mounting nut traps for fan assemblies
			//
			for(end = [-1, 1])
				translate([end * front_nut_pitch,
						   -width / 2 + wall + front_nut_depth,
						   front_nut_z - top_thickness])
					rotate([90, 0, 0])
						intersection() {
							nut_trap(screw_clearance_radius(M3_cap_screw), M3_nut_radius, front_nut_depth, true);
							translate([0, 0, -(bearing_holder_width(X_bearings) - 2 * wall - front_nut_depth - 2 * eta)])
								cylinder(r = M3_nut_radius + 1, h = 100);
						}
		}
}

module x_carriage_fan_assembly() {
	assembly("x_carriage_fan_assembly");

	translate([0, exploded * 15, 0]) {
	translate([0, 0, nozzle_length(hot_end)] + hot_end_duct_offset(hot_end))
		rotate([180, 0, 0])
			color(plastic_part_color("lime")) {
				x_carriage_fan_duct_stl();
				translate([0, - 5* exploded, duct_height_nozzle - duct_top_thickness + 5 * exploded])
					x_carriage_fan_duct_cap_stl(h2 = nozzle_height);
			}

   translate([fan_x_duct + 2*duct_wall + fan_depth(part_fan)/2, -width / 2 - fan_width(part_fan) / 2 - fan_duct_depth, sh - 26.8 - duct_wall]) {
		color(fan_color)
		for(side=[0,1])
			translate([0, -10* exploded, 0])
			translate([(fan_depth(part_fan) + dual_fan_duct_clearance + 2 * side * duct_wall )*side , 0, 0])
				fan_sunon_505020();

		translate([2*fan_depth(part_fan) + 2*duct_wall, fan_holes()[1][1],fan_holes()[1][0]])
		rotate([0, 90, 0]) {
			//for(x = [-1, 1])
				//for(y = [-1,1])
//					translate([x * fan_hole_pitch(part_fan), y * fan_hole_pitch(part_fan), fan_depth(part_fan) / 2 + (y < 0 ? fan_bracket_thickness : 0)])
						screw_and_washer(fan_screw, fan_screw_length);
			/*fan_hole_positions(part_fan) group() { */
				rotate([180, 0, 0])
					translate([0, 0, 2* fan_depth(part_fan) + dual_fan_duct_clearance + 30 * exploded + 2* duct_wall])
						nut_and_washer(fan_nut, true);
			// }
		}
	}
}
	end("x_carriage_fan_assembly");
}


module x_carriage_parts_stl() {
	x_carriage_stl();
	translate([fan_x, fan_y - 2, 0]) rotate([0, 0, 180]) x_carriage_fan_bracket_stl();
	//x_belt_clamp_stl();
	//translate([-(lug_width + 2),0,0]) x_belt_grip_stl();
	//translate([6, 8, 0]) rotate([0, 0, -90]) x_belt_tensioner_stl();
}


module x_carriage_fan_ducts_stl() {
	x_carriage_fan_duct_stl();
	translate([80, -fan_y, 0])
		rotate([0, 0, 180])
			x_carriage_fan_duct_cap_stl();

}

module x_carriage_fan_duct_rot90_stl() rotate([0, 0, 90]) x_carriage_fan_duct_stl();

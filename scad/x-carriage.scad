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
        use <vitamins/BezierScad.scad>;

        hole = extruder_hole(extruder);
        width = hole[1] + 2 * bearing_holder_width(X_bearings);

        extruder_width = extruder_width(extruder);
        function nozzle_x_offset() = extruder_x_offset(extruder);                // offset from centre of the extruder

        infinity=100;
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

        fan_duct_w = 20;
        fan_duct_h = 26.8;
        dual_fan_depth = 20;  
        dual_fan_duct_clearance = 10;

        fan_width = 2*fan_duct_w + dual_fan_duct_clearance;
        duct_wall = 1;   // Skeinforge always makes two walls, so if this is less than twice the filament width it ends about twice the filament width but more strongly bonded.
        duct_bottom_thickness = 3 * layer_height;
        duct_top_thickness = 4 * layer_height;
        fan_nut_trap_thickness = 4;
        fan_bracket_thickness = 3;

        fan_screw = fan_screw(part_fan);
        fan_nut = screw_nut(fan_screw);
        fan_washer = screw_washer(fan_screw);
        fan_screw_length = screw_longer_than(fan_depth(part_fan) + fan_bracket_thickness + fan_nut_trap_thickness + nut_thickness(fan_nut, true) + washer_thickness(fan_washer));
        //fan_width = max(2 * fan_hole_pitch(part_fan) + screw_boss_diameter(fan_screw), fan_bore(part_fan) + 2 * wall);
        fan_screw_boss_r = fan_width / 2 - fan_hole_pitch(part_fan);

        front_nut_pitch = min((bar_x - bearing_holder_length(X_bearings) / 2 - nut_radius(M3_nut) - 0.3), fan_hole_pitch(part_fan) - 5);
        front_nut_width = 2 * nut_radius(M3_nut) + wall + ((2 * front_nut_pitch < 2 * nut_radius(M3_nut) + 3 * wall) ? wall : 0);
        front_nut_height = 2 * nut_radius(M3_nut) * cos(30) + wall + top_thickness - min_top_thickness;
        front_nut_depth = min(bearing_holder_width(X_bearings) - 2 * wall - nut_thickness(M3_nut, true) - 1, nut_trap_depth(M3_nut) + 6);
        front_nut_z = 5;
        front_nut_y = width / 2 + hot_end_duct_offset(hot_end)[1];

        gap = 6;
        taper_angle = 30;
        nozzle_height = 6; // 6
        nozzle_extra_height = 15;
        duct_height_nozzle = 20;//hot_end_duct_height_nozzle(hot_end) + nozzle_extra_height;   // Thickness on the exit side
        duct_height_fan = hot_end_duct_height_fan(hot_end); // Thickness on the fan side
        ir = hot_end_duct_radius(hot_end);
        or = ir + duct_wall + gap + duct_wall;
        skew = nozzle_height * tan(taper_angle);
        throat_width = (or + skew) * 2;

        zip_x = min(length / 2 - lug_width - zipslot_width() / 2 - eta, bar_x);


        fan_x = base_offset;
        fan_y = -(width / 2  + fan_width(part_fan) / 2) - (2 * X_carriage_clearance + belt_width(X_belt) + belt_clearance);
        fan_z = nozzle_length(hot_end) + hot_end_duct_offset(hot_end)[2] - duct_height_fan - fan_depth(part_fan) / 2;

        fan_x_duct = fan_x - hot_end_duct_offset(hot_end)[0];
        fan_y_duct = -fan_y + hot_end_duct_offset(hot_end)[1];

        module throat(inner) {
            y = or + skew - duct_wall;
			h = duct_height_nozzle + nozzle_extra_height;
//		translate([0,0, nozzle_extra_height])
            if(inner)
                translate([-throat_width / 2 + duct_wall, y, 0])
                    cube([throat_width - 2 * duct_wall, 2 * eta, h - duct_wall]);
            else
                translate([-throat_width / 2, y, 0])
                    cube([throat_width, 2 * eta, h]);
        }

function start_of_slope() = or + skew - duct_wall;

function truncation_point() = fan_y_duct - fan_bore(part_fan) / 2;
function end_of_slope() = fan_y_duct - fan_hole_pitch(part_fan);      // end of slope before truncation
function inner_nozzle_height() = duct_height_nozzle - duct_top_thickness;
function inner_neck_height() = duct_height_fan - duct_top_thickness;
            //
            // The roof slope is trucated by the fan entrance so need to calculate where it it ends such
            // that it is the correct thickness at the truncation.
            //
function neck_height() = 25; //inner_nozzle_height() + (end_of_slope() - start_of_slope()) * (inner_neck_height()- inner_nozzle_height()) / (truncation_point() - start_of_slope()) - duct_bottom_thickness;


        module neck(inner) {
			translate([0,0, nozzle_extra_height])
            if(inner)
                translate([fan_x_duct - fan_width / 2 + duct_wall, front_nut_y, 0])
                    cube([fan_width - 2*duct_wall, 2 * eta , neck_height()]); 
            else
                translate([fan_x_duct - fan_width / 2, front_nut_y, 0])
                    cube([fan_width, 2 * eta , duct_height_fan]);
        }

        module input_and_neck() {
            union() {
                // fan entrance
                hull() {
                    translate([fan_x_duct, fan_y_duct, duct_height_fan - duct_top_thickness])
                        rotate([180, 0, 0])
                            rounded_cylinder(r = fan_bore(part_fan) / 2, h = duct_height_fan - duct_bottom_thickness - duct_top_thickness, r2 = duct_height_fan / 2);

                    neck(true);
                }
            }
            // neck
            hull() {
                neck(true);
                throat(true);
            }
        }
        module curve(v, span=10, height=0) {
            H = v[1];
            L = v[0];
            alpha = v[2];
            translate([0,-H,0]) {
            BezWall( [
                [0,0],
                [L/2 - H / 2 * tan(alpha), 0],
                [L/2, H/2],
                [L/2 + H / 2 * tan(alpha), H],
                [L,H]
            ] , width = H, height = span, resolution = 4 );
            translate([0, -height + H, 0])
                cube([L,height - H,span]);
            }
        }


module bearing_clearance() {
		translate([bearing_holder_length(X_bearings) / 2, bearing_holder_width(X_bearings) / 2,  bearing_holder_width(X_bearings) / 2])
	rotate([180,0,0])
            translate([base_offset, 0, - nozzle_length(hot_end) - exploded * 15] - hot_end_duct_offset(hot_end))
#                        for(end = [-1, 0, 1])
                            translate([end * bar_x, end ? -bar_y : bar_y, bar_offset - hot_end_bodge(hot_end) ] * 1)
                                rotate([0, 0, 90])
									cube([bearing_holder_width(X_bearings), bearing_holder_length(X_bearings), bearing_holder_width(X_bearings) ]);


}

module fan_duct_nozzle() {
	// nozzle
	difference() {
 	   hull() {
    		union() {
        		cylinder(r1 = or, r2 = or + skew, h = nozzle_height);
            	translate([0, 0, nozzle_height - eta])
            		cylinder(r = or + skew, h = duct_height_nozzle - nozzle_height + nozzle_extra_height);
        	}
	        throat(false);
		}
		

		bearing_clearance();

		inner_r = ir + skew;
		translate([-infinity/2, -2*or, duct_height_nozzle])
			cube([infinity,2*or,2*or]);

	    // hole in the middle
    	translate([0, 0,  -2 * eta])
	    	cylinder(r1 = ir, r2 = inner_r, h = nozzle_height + 4 * eta);
	    translate([0, 0, nozzle_height - 2 * eta])
    		cylinder(r = inner_r, h = infinity);

	    // nozzle exit slot
	    translate([0, 0, -2 * eta])
    	    difference() {
	        	union() {
                	cylinder(r1 = or - duct_wall, r2 = or + skew - duct_wall, h = nozzle_height);
                    hull() {
                    	translate([0, 0, nozzle_height - 2 * eta])
                        	cylinder(r = or + skew - duct_wall, h = duct_height_nozzle - nozzle_height + nozzle_extra_height - 5 * layer_height);
                      	throat(true);
                    }
                }
				
		translate([-infinity/2, -2*or + duct_wall, duct_height_nozzle])
			cube([infinity, 2*or, 2*or]);
				

                translate([0, 0, -2 * eta])
                	cylinder(r1 = ir + duct_wall, r2 = ir + skew + duct_wall, h = nozzle_height + 4 * eta);
                translate([0, 0, nozzle_height - 2 * eta])
	                cylinder(r = ir + skew + duct_wall, h = duct_height_nozzle - nozzle_height + nozzle_extra_height +  4 * eta);
			}
	}
}


        module x_carriage_fan_duct_stl() {
            stl("x_carriage_fan_duct");

            bodge = 54 - 51.2;          // error in length of MK5 J-head
            h = fan_z - fan_depth(part_fan) / 2;
            z_holes_carriage = max(h - top_thickness - front_nut_z - bodge, fan_bracket_thickness + washer_diameter(M3_washer) / 2) + 30;
          
            y = front_nut_y; //fan_y_duct - fan_hole_pitch(part_fan);
            sh = nozzle_length(hot_end) + exploded * 15 + hot_end_duct_offset(hot_end)[2];
            
            inner_h = duct_height_fan - duct_wall - top_thickness;
            fan_duct_nozzle();
            difference() { // shaft
                union() {
                    difference() {
                        union() {
                            difference() {
                                union() {                                    
									// neck
                                    hull() {
                                        neck(false);
                                        throat(false);
                                    }

                                    // fan input
                                    translate([fan_x - fan_width/2 - duct_wall,  y, nozzle_extra_height])
                                        cube([fan_width, dual_fan_depth, fan_duct_h]);

								}

								bearing_clearance();

                                // fan entrance
                                /*hull() {
                                    translate([fan_x, fan_y_duct, duct_wall + duct_height - duct_wall - top_thickness])
                                        rotate([180, 0, 0])
                                            rounded_cylinder(r = fan_bore(part_fan) / 2, h = duct_height - duct_wall - top_thickness, r2 = duct_height / 2);
                                    neck(true);
                                }
                                translate([0, 0, duct_height - duct_wall - top_thickness - 1])
                                    hull() {
                                        translate([fan_x, fan_y_duct, duct_wall])
                                          cylinder(r = fan_bore(part_fan) / 2, h = duct_height - duct_wall - top_thickness);

                                    neck(true);
                                }*/

                                // neck
                                hull() {
                                    neck(true);
                                    throat(true);
                                }

                                // opening
                                translate([fan_x - fan_width/2 - duct_wall, y, nozzle_extra_height]) {
                                     w = fan_width - 2*duct_wall;
                                     h = fan_duct_h - 2*duct_wall;
                                     translate([duct_wall, 0, h + duct_wall])
                                         rotate([90,0, 90])
                                             curve([dual_fan_depth + duct_wall , h - neck_height(), 30], span=w, height=h);
                                }
                        }
                    
                        /* for(side = [-1, 1])
                             translate([fan_x + side * fan_hole_pitch(part_fan), fan_y_duct - fan_hole_pitch(part_fan), 0])
                                 cylinder(r = fan_screw_boss_r, h = duct_height_nozzle); */
                     }
                     //
                     // Fan screw nut traps
                     //
                     /*translate([fan_x, fan_y_duct, -fan_depth(part_fan) / 2])
                         fan_hole_positions(part_fan) group() {
                              nut_trap(screw_clearance_radius(fan_screw), nut_radius(screw_nut(fan_screw)), duct_height - fan_nut_trap_thickness, supported = true);
                              nut_trap(0, nut_radius(screw_nut(fan_screw)) + 0.15, duct_height - fan_nut_trap_thickness - nut_trap_depth(fan_nut));
                          }*/
                      //
                      // Cold end cooling vent
                      //
                      rotate([0, 0, atan2(-fan_x, -fan_y)])
                          translate([0, ir + skew, duct_height_nozzle - top_thickness - 3])
                              rotate([90, 0, 0])
                                  teardrop(r = 4.5 / 2, h = 10, center = true);
                    }
                    translate([fan_x, dual_fan_depth/2 + y, duct_wall + nozzle_extra_height]) {
                        w = dual_fan_duct_clearance + 2*eta;
                        translate([-w/2, 0,0]) {
                            w = dual_fan_duct_clearance + 2*eta;
                            h = fan_duct_h - 2 * duct_wall;
                            depth = dual_fan_depth/2;
                            d = dual_fan_duct_clearance;
               
                            union() {
                                d = d + 2 * duct_wall;
                                w = w + 2 * duct_wall;
                                cube([w, depth, h]);
                                translate([d/2,0,0])
                                    cylinder(d=d, h=h);
                            }
                            /* translate([duct_wall, 0, -infinity/2]) {
                                cube([w, infinity, infinity]);
                                translate([d/2,0,0])
                                    cylinder(d=d, h=infinity);
                            } */
                        }
                    }
            } // union shaft
            translate([fan_x, dual_fan_depth/2 + y, duct_wall + nozzle_extra_height]) {
                w = dual_fan_duct_clearance + 2*eta;
                translate([-w/2, 0,0]) {
                    d = dual_fan_duct_clearance;
                    translate([duct_wall, 0, -infinity/2]) {
                        cube([w, infinity, infinity]);
                        translate([d/2,0,0])
                            cylinder(d=d, h=infinity);
                    }
                }
            }
           // cube([infinity,infinity,infinity]);
           // mirror([0,0,1])
           //  translate([-50,0,-10])
           // cube([infinity,infinity,infinity]);
        } // difference shaft

            /*translate([fan_x - fan_width/2, y, fan_duct_h]) {
                r1 = dual_fan_depth - 2 * duct_wall;
                r2 = sh - fan_duct_h;
                difference() {
                    cube([fan_width, duct_wall * 2, sh - fan_duct_h]);
                        translate([fan_width/2 - front_nut_pitch, 0, sh - fan_duct_h - front_nut_z - top_thickness])
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
           
                #translate([fan_duct_w/2, r1 + 2*duct_wall, r2])
                    for(side=[0,1])
                        translate([side * (fan_width/2), 0, 0]) {
                            difference() {
                                translate([0, 0, 0])
                                    rotate([180,0,0])
                                        cube([2*duct_wall, r1, r2]);
                                translate([-infinity/2,0, 0])
                                    scale([1,1, r2/r1])
                                        rotate([0,90,0])
                                            cylinder(r=r1,h=infinity);
                            }
                        }
            }*/
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

            translate([0, 0, nozzle_length(hot_end) + exploded * 15] + hot_end_duct_offset(hot_end))
                rotate([180, 0, 0])
!                    color(plastic_part_color("lime")) render() x_carriage_fan_duct_stl();

           /* translate([fan_x, fan_y, fan_z]) {
                color(fan_color) render() fan(part_fan);
                rotate([180, 0, 0]) {
                    for(x = [-1, 1])
                        for(y = [-1,1])
                            translate([x * fan_hole_pitch(part_fan), y * fan_hole_pitch(part_fan), fan_depth(part_fan) / 2 + (y < 0 ? fan_bracket_thickness : 0)])
                                screw_and_washer(fan_screw, fan_screw_length);
                    fan_hole_positions(part_fan) group() {
                        rotate([180, 0, 0])
                            translate([0, 0, fan_depth(part_fan) + duct_top_thickness + 30 * exploded])
                                nut(fan_nut, true);
                    }
                    translate([0, 0, fan_depth(part_fan) / 2])
                        color(plastic_part_color("lime")) render() x_carriage_fan_bracket_stl();
                }
            } */
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
                    x_carriage_fan_duct_stl();
        }

        module x_carriage_fan_duct_rot90_stl() rotate([0, 0, 90]) x_carriage_fan_duct_stl();

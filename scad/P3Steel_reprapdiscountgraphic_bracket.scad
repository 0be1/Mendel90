// bracket for mounting the RepRapDiscount graphic LCD
// panel on 8mm rod.
//
// remix of Thingiverse # 287633 by oliasmage drcharlesbell@gmail.com
// for use on P3Steel with 8mm threaded rod top mount
//
//-- todo: add two extra small cubes to create a small grip underneath the lcd pcb

include <conf/config.scad>

$fn=32;
infinity = 100;
  
module bracket(screw=M3_cap_screw, L=65.7, D=M6_clearance_radius * 2, base=true) {
  l = L / sqrt(2);
  
  nut = screw_nut(screw);
  
  h = 2 * nut_radius(nut) * 130/100;
  b = (base ? 2 : 0);
  
  w = h;
  
    echo(h);
  difference() {
    union() {
      cylinder(h=h + b, r=w);
      
      rotate([0,0,-45]) difference() {
          cube([l,l,h]);
          translate([w, w, -infinity/2]) cube([infinity, infinity, infinity]);
      } 
      
      translate([0, -w, 0]) cube([w*2, w*2, h]);
      
      for(i=[-1,1])
        translate([l/sqrt(2), i * (l/sqrt(2) -w/sqrt(2)), 0])
            rotate([90 * (i -1), 0, 0])
                translate([0, 0, h * (i - 1) / 2 - b])
                    cube([w/sqrt(2), w/sqrt(2) * 2, h + 2 * b]); 
    }
    
    translate([0,0,-infinity/2]) cylinder(h=infinity, r=D/2);
    
    for(i=[-1, 1]) 
        translate([l/sqrt(2) + nut_trap_depth(nut), i * l/sqrt(2), h/2]) {
            rotate([0, 90, 0])
                screw_hole(screw);
            rotate([0,-90,0])
                nut_hole(nut);
        }
    }
}

module nut_hole(nut, h=infinity) {
    hull()
        for(z = [-1, 1])
            translate([z * layer_height / 2, 0, 0])
                cylinder(h=h, r=nut_radius(nut), $fn=6);
}

module screw_hole(screw, h=infinity) {
        cylinder(r= screw_clearance_radius(screw) + layer_height /4, h = h, center=true);
}
// http://www.fullermetric.com/products/stainless/din933_931hex_head_cap_screw.aspx
// MX_nut = [d,  ]
M6_hex_screw   = ["HX060", "M6 hex screw", hs_hex,  6, 11.05,  4,  M6_washer, M6_nut, M6_tap_radius,  M6_clearance_radius];



module turnkey(screw=M6_hex_screw, h=20, d = 8.32) {
    nut = screw_nut(screw);
    r = screw_clearance_radius(screw);
     
    
    difference() {
        union() {
            cylinder(r=d, h = h);
            translate([0,0,h]) {
                 hull() {
                    translate([0,0,-h/5 - h/10])
                        cylinder(r=d * 1.2, h = h/5);
                    translate([0,0,- h/10])
                        cylinder(r=d, h = h/10);
                }
                for(i=[1 : 6]) {
                    rotate([0, 0, i * 360/6])
                        translate([r * 3 - 1, 0,  - h/5 ])
                            sphere(r=2, $fn=12);
                }
            }
        }
        screw_hole(screw);
        translate([0,0, h + h/10 - nut_trap_depth(nut)])
            nut_hole(nut);
    }
    
}

turnkey();

for (i=[-1, 1])
    rotate([0, 180, (i -1) * 90]) translate([(i + 1)* 10,0,0]) bracket();
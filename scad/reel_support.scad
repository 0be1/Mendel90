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
  
module bracket(v, screw=M3_cap_screw, r = 4 + .5/2, shaft=true) {
    w = v[0];
    h = v[1];
    d = v[2];
    cr = r; // rounded corner radius
    e = 3 + layer_height; // dibond sheet is 3mm thick
    
    nut = screw_nut(screw);
    
    difference() {
        // main body
        round([w, h, d], radius=cr);
    
        translate([0, h / 4, 0]) {
            hull() {
                translate([0,0, -r])
                cylinder(r = r, h = infinity);
                if (shaft)
                    translate([-r, 0, -r])
                        cube([2*r, infinity, infinity]);
                else
                    translate([0, r/2 , 0])
                        #cylinder(r=r, h =infinity);
            }
        }
    
        if (shaft)
         // rounded corners for shaft
        for(i=[-1,1])
            translate([ i*r, h/2, 0]) {
                difference() {
                    translate([i*cr/2, -cr/2, 0]) 
                        rotate([0,0,180])
                            cube([cr+1,cr+1,0], center=true);
                    translate([i*cr, -cr, 0])
                        cylinder(r=cr,h=infinity,center=true);
                }
            }
        // screw & nuts
        for(i=[-1,1])
            translate([i *( w/4), - (h /4), 0]) {
                screw_hole(screw);
                translate([0,0, d/2 - nut_trap_depth(nut)])
                    nut_hole(nut);
            }
        // groove        
        translate([-infinity/2, 0, - e / 2])
            rotate([0,0,-90])
                cube([infinity, infinity, e]);
    }
}

module round(v, radius, center=true) {
    x = v[0];
    y = v[1];
    z = v[2];
    
    cl = 1;
    
    difference() { 
       cube(v, center=center);
    
       difference() { 
            cube([x + cl, y + cl, z + cl], center=center);
        
            cube([x + cl, y - 2 * radius, z + cl], center=center);
                
            cube([x - 2 * radius, y + cl, z + cl], center=center);
        
            for(i=[-1,1])
                for (j=[-1,1])
                    translate([ i *( x/2 - radius) , j * (y/2- radius)])
                        cylinder(center=true, r=radius, h=infinity);
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
    translate([0, 0, -infinity/2])
        cylinder(r= screw_clearance_radius(screw) + layer_height /4, h = h);
}

for (i=[-1])
    translate([-i * 10, 0, 0])
        rotate([0, 180, (i -1) * 90])
            translate([(i + 1)* 10,0,0])
                bracket([30, 50, 15], shaft=i==-1);
infinity = 100;

sunon50x50x20 = [50, 20, 27, 15,  M3_cap_screw, 17,   10, 100, true];

holes_x = [23, -20];

function fan_duct_height() = 26.8;
function fan_duct_width() = sunon50x50x20[1];

bracket_angle = 42;

function fan_holes() = [for(x=holes_x) [ x, -x * tan(bracket_angle)] ];

module fan_sunon_505020() {
    l = sunon50x50x20[0];
    h = fan_duct_width();
    r1 = 21.6;
    r2 = 26.65;
    
    bracket_radius = 6.5 / 2;
  
    
    rotate([0,-90,0])
    intersection() {
        // assert boundaries
        translate([r2 - l/2, 0, 0]) 
            cube([l, l, h], center=true);
        
        union() {
            // main body
            translate([0, 0, -infinity/2]) {
                linear_extrude(h=infinity)
                    spiral(angle1=90, r1=r1, r2=r2);
                // duct
                cube([fan_duct_height(), 25, infinity]);
            }
            
            // brackets
            for(hole=fan_holes()) {
                difference() {
                    x = hole[0];
                    y = hole[1];
                    union() {
                        translate([x, y, 0])
                            cylinder(r=bracket_radius, h=infinity, center=true);
               
                        rotate([0, 0, 90 * (abs(x) / x - 1) - bracket_angle])
                            translate([0, -bracket_radius, -infinity/2])
                                cube([abs(x) / cos(bracket_angle), bracket_radius * 2, infinity]);
                    }
                    translate([x, -x * tan(bracket_angle), 0])
                        cylinder(r=2, h=infinity, center=true);
                }
            }
        }
    } 
}

module spiral(angle1=0, angle2=360, step=100, r1=0, r2=100) {
    function a(i) = (angle2 - angle1)/step * i + angle1;
    
    function r(i) = (r2 - r1)/step * i + r1;
    
    points = [ for (i = [0:step]) [r(i) * cos(a(i)), r(i)*sin(a(i)) ] ];

    polygon(points=points);
}



//fan_sunon_505020();
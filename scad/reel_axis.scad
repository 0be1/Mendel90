infinity=100;

$fn=100;

/**
 * 
 */
module reel_axis(height=50, inner_diameter=22, outer_diameter=50, inner_thickness=2, wall_thickness=1.5, outer_thickness=3, a=-12, a0=-8, n_wall=8) {



linear_extrude(height=height)
    difference() {
        union() {
            
            difference() {
                circle(d = inner_diameter + inner_thickness * 2);
                circle(d = inner_diameter);
            }

            difference() {
                circle(d = outer_diameter);
                circle(d = outer_diameter - outer_thickness * 2);
                rotate([0,0,a0])
                    polygon(points=[[0,0],[infinity*cos(a/2),infinity*sin(a/2)],[infinity*cos(a/2),-infinity*sin(a/2)]]);
            }

            for(i=[0:n_wall-2])
                rotate([0,0,360/n_wall*i])
                    translate([inner_diameter/2 + inner_thickness/2,
                            -wall_thickness/2,
                            0])
                       square([(outer_diameter - inner_diameter - inner_thickness - outer_thickness)/2, wall_thickness]);
            for(j=[-1,1])
                rotate([0,0,a/2*j + a0])
                    translate([(outer_diameter-outer_thickness)/2,0,0])
                       # circle(d=outer_thickness,$fn=12);
        }
    }
}

module reel_axis_p(a=50) {
     reel_axis(height=a,inner_diameter=a/50*22, outer_diameter=a, inner_thickness=a/50*2, wall_thickness=a/50*1.5, outer_thickness=a/50*3, a=-12, a0=-8, n_wall=8);
    
}

reel_axis(height=60, outer_diameter=52);
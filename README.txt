list team members, document who did what, discuss
anything interesting about your implementation.

Team members: Cassie Zhang xzhan304, Tianai Yue tyue4

Milestone 1
Both Cassie and Tianai did relatively equal amounts of work and effort.
Tianai implemented draw_circle, draw_tile, draw_sprite, and test cases for all the functions.
Cassie implemented draw_pixel, draw_rect, helper functions, and test cases for all the functions.

The interesting thing we found is that the draw_tile function utilizes a direct memory copy method for 
efficiency in regions without blending needs, significantly speeding up the process. Conversely, the 
draw_sprite function introduced alpha value checks to bypass blending for fully transparent pixels, 
enhancing performance by reducing unnecessary computations.
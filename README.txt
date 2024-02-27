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

Milestone 2
Both Cassie and Tianai did relatively equal amounts of work and effort.
Tiana: draw_pixel, set_pixel, blend_components, square, square_dist, and test cases for all the functions.
Cassie: in_bounds, compute_index, blend_colors, get_r/g/b/a, and test cases for all the functions.

The assembly code optimizes register allocation, following established conventions for parameter transmission 
and return values. It meticulously preserves and restores registers such as `%rbp` and `%r12`-`%r15`, ensuring 
their integrity across function invocations. It utilizes control flow directives like `jmp` and conditionals 
(`je`, `jne`) to navigate program flow based on specific conditions, bolstering both code clarity and performance.

Milestone 3
Both Cassie and Tianai did relatively equal amounts of work and effort.
Tiana: draw_rect, draw_tile, and debug for all the functions.
Cassie: draw_circle, draw_sprite, and debug for all the functions.

When implementing this code, especially in situations where caller-saved registers are frequently used, it may lead 
to stack congestion due to the necessity of saving and restoring these registers. To address this, we employ a strategy 
where we utilize local variables stored directly on the stack, like -20(%rbp), -16(%rbp), and so on. By doing so, we 
minimize the need for constant pushing and popping of values onto and off the stack, thereby optimizing stack usage and 
improving overall efficiency.
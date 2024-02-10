// C implementations of drawing functions (and helper functions)

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include "drawing_funcs.h"

////////////////////////////////////////////////////////////////////////
// Helper functions
////////////////////////////////////////////////////////////////////////

// TODO: implement helper functions

// Checks x and y coordinates to determine whether they 
// are in bounds in the specified image
int32_t in_bounds(struct Image *img, int32_t x, int32_t y) {
  if (x >= 0 && x < img->width && y >= 0 && y < img->height) {
    return 1;
  } else {
    return 0;
  }
}

// computes the index of a pixel in an image’s data array 
// given its x and y coordinates
uint32_t compute_index(struct Image *img, int32_t x, int32_t y) {
  if (in_bounds(img, x, y)) {
    return (uint32_t)(y * img->width + x);
  }
  return 0;
}

// Constrains a value so that it is greater than or equal 
// to min and less than or equal to max
int32_t clamp(int32_t val, int32_t min, int32_t max) {\
  if (val < min) {
    return min;
  } else if (val > max) {
    return max;
  } else {
    return val;
  }
}

// Return the red, green, blue, and alpha components of a 
// pixel color value
uint8_t get_r(uint32_t color) {
  // bits 24-31
  return (uint8_t)(color >> 24);
}
uint8_t get_g(uint32_t color) {
  // bits 16-23
  return (uint8_t)(color >> 16);
}
uint8_t get_b(uint32_t color) {
  // bits 8-15
  return (uint8_t)(color >> 8);
}
uint8_t get_a(uint32_t color) {
  // bits 0-7 
  return (uint8_t)color;
}

// blends foreground and background color component values 
// using a specified alpha (opacity) value
uint8_t blend_components(uint32_t fg, uint32_t bg, uint32_t alpha) {
  uint32_t result = (alpha * fg + (255 - alpha) * bg) / 255;
  return (uint8_t)result;
}

// blends foreground and background colors using the 
// foreground color’s alpha value to produce an opaque color. 
// (It will call blend_components.)
uint32_t blend_colors(uint32_t fg, uint32_t bg) {
  uint8_t fg_a = get_a(fg);
  uint8_t blended_r = blend_components(get_r(fg), get_r(bg), fg_a);
  uint8_t blended_g = blend_components(get_g(fg), get_g(bg), fg_a);
  uint8_t blended_b = blend_components(get_b(fg), get_b(bg), fg_a);

  uint32_t blended_color = ((uint32_t)blended_r << 24) | ((uint32_t)blended_g << 16) | ((uint32_t)blended_b << 8) | ((uint32_t)255);
    
  return blended_color;
}

// draws a single pixel to a destination image, blending the 
// specified foregroudn color with the existing background 
// color, at a specified pixel index
void set_pixel(struct Image *img, uint32_t index, uint32_t color) {
  if (index < img->width * img->height) {
    uint32_t bg_color = img->data[index];
    uint32_t blended_color = blend_colors(color, bg_color);
    img->data[index] = blended_color;
  }
}

// returns the result of squaring an int64_t value.
int64_t square(int64_t x) {
  return x * x;
}

// returns the sum of the squares of the x and y distances 
// between two points
int64_t square_dist(int64_t x1, int64_t y1, int64_t x2, int64_t y2) {
  int64_t distance_x = x2 - x1;
  int64_t distance_y = y2 - y1;

  // Return the sum of the squares of the differences
  return square(distance_x) + square(distance_y);
}


////////////////////////////////////////////////////////////////////////
// API functions
////////////////////////////////////////////////////////////////////////

//
// Draw a pixel.
//
// Parameters:
//   img   - pointer to struct Image
//   x     - x coordinate (pixel column)
//   y     - y coordinate (pixel row)
//   color - uint32_t color value
//
void draw_pixel(struct Image *img, int32_t x, int32_t y, uint32_t color) {
  // TODO: implement
  if (in_bounds(img, x, y)) {
    uint32_t index = compute_index(img, x, y);
    set_pixel(img, index, color);
  }
}

//
// Draw a rectangle.
// The rectangle has rect->x,rect->y as its upper left corner,
// is rect->width pixels wide, and rect->height pixels high.
//
// Parameters:
//   img     - pointer to struct Image
//   rect    - pointer to struct Rect
//   color   - uint32_t color value
//
void draw_rect(struct Image *img,
               const struct Rect *rect,
               uint32_t color) {
  // TODO: implement
  int32_t x_start = clamp(rect->x, 0, img->width - 1);
  int32_t y_start = clamp(rect->y, 0, img->height - 1);
  
  int32_t x_end = clamp(rect->x + rect->width, 0, img->width);
  int32_t y_end = clamp(rect->y + rect->height, 0, img->height);

  for (int32_t y = y_start; y < y_end; y++) {
    for (int32_t x = x_start; x < x_end; x++) {
        draw_pixel(img, x, y, color);
    }
  }
}

//
// Draw a circle.
// The circle has x,y as its center and has r as its radius.
//
// Parameters:
//   img     - pointer to struct Image
//   x       - x coordinate of circle's center
//   y       - y coordinate of circle's center
//   r       - radius of circle
//   color   - uint32_t color value
//
void draw_circle(struct Image *img,
                 int32_t x, int32_t y, int32_t r,
                 uint32_t color) {
  // TODO: implement
}

//
// Draw a tile by copying all pixels in the region
// enclosed by the tile parameter in the tilemap image
// to the specified x/y coordinates of the destination image.
// No blending of the tile pixel colors with the background
// colors should be done.
//
// Parameters:
//   img     - pointer to Image (dest image)
//   x       - x coordinate of location where tile should be copied
//   y       - y coordinate of location where tile should be copied
//   tilemap - pointer to Image (the tilemap)
//   tile    - pointer to Rect (the tile)
//
void draw_tile(struct Image *img,
               int32_t x, int32_t y,
               struct Image *tilemap,
               const struct Rect *tile) {
 // TODO: implement
}

//
// Draw a sprite by copying all pixels in the region
// enclosed by the sprite parameter in the spritemap image
// to the specified x/y coordinates of the destination image.
// The alpha values of the sprite pixels should be used to
// blend the sprite pixel colors with the background
// pixel colors.
//
// Parameters:
//   img       - pointer to Image (dest image)
//   x         - x coordinate of location where sprite should be copied
//   y         - y coordinate of location where sprite should be copied
//   spritemap - pointer to Image (the spritemap)
//   sprite    - pointer to Rect (the sprite)
//
void draw_sprite(struct Image *img,
                 int32_t x, int32_t y,
                 struct Image *spritemap,
                 const struct Rect *sprite) {
  // TODO: implement
}

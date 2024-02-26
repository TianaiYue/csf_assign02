/*
 * Tests for the drawing and helper functions in C
 * for basic graphic operations.
 * CSF Assignment 2
 * Tianai Yue, Cassie Zhang
 * tyue4@jhu.edu, xzhan304@jhu.edu
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "image.h"
#include "drawing_funcs.h"
#include "tctest.h"

// add prototypes for your helper functions
int32_t in_bounds(struct Image *img, int32_t x, int32_t y); 
uint32_t compute_index(struct Image *img, int32_t x, int32_t y);
int32_t clamp(int32_t val, int32_t min, int32_t max);
uint8_t get_r(uint32_t color);
uint8_t get_g(uint32_t color);
uint8_t get_b(uint32_t color);
uint8_t get_a(uint32_t color);
uint8_t blend_components(uint32_t fg, uint32_t bg, uint32_t alpha);
uint32_t blend_colors(uint32_t fg, uint32_t bg);
void set_pixel(struct Image *img, uint32_t index, uint32_t color);
int64_t square(int64_t x);
int64_t square_dist(int64_t x1, int64_t y1, int64_t x2, int64_t y2);

// an expected color identified by a (non-zero) character code
typedef struct {
  char c;
  uint32_t color;
} ExpectedColor;

// struct representing a "picture" of an expected image
typedef struct {
  ExpectedColor colors[20];
  const char *pic;
} Picture;

typedef struct {
  struct Image small;
  struct Image large;
  struct Image tilemap;
  struct Image spritemap;
} TestObjs;

// dimensions and pixel index computation for "small" test image (objs->small)
#define SMALL_W        8
#define SMALL_H        6
#define SMALL_IDX(x,y) ((y)*SMALL_W + (x))

// dimensions of the "large" test image
#define LARGE_W        24
#define LARGE_H        20

// create test fixture data
TestObjs *setup(void) {
  TestObjs *objs = (TestObjs *) malloc(sizeof(TestObjs));
  init_image(&objs->small, SMALL_W, SMALL_H);
  init_image(&objs->large, LARGE_W, LARGE_H);
  objs->tilemap.data = NULL;
  objs->spritemap.data = NULL;
  return objs;
}

// clean up test fixture data
void cleanup(TestObjs *objs) {
  free(objs->small.data);
  free(objs->large.data);
  free(objs->tilemap.data);
  free(objs->spritemap.data);

  free(objs);
}

uint32_t lookup_color(char c, const ExpectedColor *colors) {
  for (unsigned i = 0; ; i++) {
    assert(colors[i].c != 0);
    if (colors[i].c == c) {
      return colors[i].color;
    }
  }
}

void check_picture(struct Image *img, Picture *p) {
  unsigned num_pixels = img->width * img->height;
  assert(strlen(p->pic) == num_pixels);

  for (unsigned i = 0; i < num_pixels; i++) {
    char c = p->pic[i];
    uint32_t expected_color = lookup_color(c, p->colors);
    uint32_t actual_color = img->data[i];
    ASSERT(actual_color == expected_color);
  }
}

// prototypes of test functions
void test_draw_pixel(TestObjs *objs);
void test_draw_rect(TestObjs *objs);
void test_draw_circle(TestObjs *objs);
void test_draw_circle_clip(TestObjs *objs);
void test_draw_tile(TestObjs *objs);
void test_draw_sprite(TestObjs *objs);

void test_in_bounds(TestObjs *objs);
void test_compute_index(TestObjs *objs);
void test_blend_components(TestObjs *objs);
void test_set_pixel(TestObjs *objs);
void test_set_pixel_2(TestObjs *objs);
void test_square(TestObjs *objs);

void test_clamp(TestObjs *objs);
void test_get_r(TestObjs *objs);
void test_get_g(TestObjs *objs);
void test_get_b(TestObjs *objs);
void test_get_a(TestObjs *objs);
void test_blend_colors(TestObjs *objs);
void test_square_dist(TestObjs *objs);

int main(int argc, char **argv) {
  if (argc > 1) {
    // user specified a specific test function to run
    tctest_testname_to_execute = argv[1];
  }

  TEST_INIT();

  // add TEST() directives for your helper functions
  TEST(test_draw_pixel);
  TEST(test_draw_rect);
  TEST(test_draw_circle);
  TEST(test_draw_circle_clip);
  TEST(test_draw_sprite);
  TEST(test_draw_tile);

  TEST(test_in_bounds);
  TEST(test_compute_index);
  TEST(test_blend_components);
  TEST(test_set_pixel);
  TEST(test_set_pixel_2);
  TEST(test_square);

  TEST(test_clamp);
  TEST(test_get_r);
  TEST(test_get_g);
  TEST(test_get_b);
  TEST(test_get_a);
  TEST(test_blend_colors);
  TEST(test_square_dist);

  TEST_FINI();
}

void test_draw_pixel(TestObjs *objs) {
  // initially objs->small pixels are opaque black
  ASSERT(objs->small.data[SMALL_IDX(3, 2)] == 0x000000FFU);
  ASSERT(objs->small.data[SMALL_IDX(5, 4)] == 0x000000FFU);

  // test drawing completely opaque pixels
  draw_pixel(&objs->small, 3, 2, 0xFF0000FF); // opaque red
  ASSERT(objs->small.data[SMALL_IDX(3, 2)] == 0xFF0000FF);
  draw_pixel(&objs->small, 5, 4, 0x800080FF); // opaque magenta (half-intensity)
  ASSERT(objs->small.data[SMALL_IDX(5, 4)] == 0x800080FF);

  // test color blending
  draw_pixel(&objs->small, 3, 2, 0x00FF0080); // half-opaque full-intensity green
  ASSERT(objs->small.data[SMALL_IDX(3, 2)] == 0x7F8000FF);
  draw_pixel(&objs->small, 4, 2, 0x0000FF40); // 1/4-opaque full-intensity blue
  ASSERT(objs->small.data[SMALL_IDX(4, 2)] == 0x000040FF);
}

void test_draw_rect(TestObjs *objs) {
  struct Rect red_rect = { .x = 2, .y = 2, .width=3, .height=3 };
  struct Rect blue_rect = { .x = 3, .y = 3, .width=3, .height=3 };
  draw_rect(&objs->small, &red_rect, 0xFF0000FF); // red is full-intensity, full opacity
  draw_rect(&objs->small, &blue_rect, 0x0000FF80); // blue is full-intensity, half opacity

  const uint32_t red   = 0xFF0000FF; // expected full red color
  const uint32_t blue  = 0x000080FF; // expected full blue color
  const uint32_t blend = 0x7F0080FF; // expected red/blue blend color
  const uint32_t black = 0x000000FF; // expected black (background) color

  Picture expected = {
    { {'r', red}, {'b', blue}, {'n', blend}, {' ', black} },
    "        "
    "        "
    "  rrr   "
    "  rnnb  "
    "  rnnb  "
    "   bbb  "
  };

  check_picture(&objs->small, &expected);
}

void test_draw_circle(TestObjs *objs) {
  Picture expected = {
    { {' ', 0x000000FF}, {'x', 0x00FF00FF} },
    "   x    "
    "  xxx   "
    " xxxxx  "
    "  xxx   "
    "   x    "
    "        "
  };

  draw_circle(&objs->small, 3, 2, 2, 0x00FF00FF);

  check_picture(&objs->small, &expected);
}

void test_draw_circle_clip(TestObjs *objs) {
  Picture expected = {
    { {' ', 0x000000FF}, {'x', 0x00FF00FF} },
    " xxxxxxx"
    " xxxxxxx"
    "xxxxxxxx"
    " xxxxxxx"
    " xxxxxxx"
    "  xxxxx "
  };

  draw_circle(&objs->small, 4, 2, 4, 0x00FF00FF);

  check_picture(&objs->small, &expected);
}

void test_draw_tile(TestObjs *objs) {
  ASSERT(read_image("img/PrtMimi.png", &objs->tilemap) == IMG_SUCCESS);

  struct Rect r = { .x = 4, .y = 2, .width = 16, .height = 18 };
  draw_rect(&objs->large, &r, 0x1020D0FF);

  struct Rect grass = { .x = 0, .y = 16, .width = 16, .height = 16 };
  draw_tile(&objs->large, 3, 2, &objs->tilemap, &grass);

  Picture pic = {
    {
      { ' ', 0x000000ff },
      { 'a', 0x52ad52ff },
      { 'b', 0x1020d0ff },
      { 'c', 0x257b4aff },
      { 'd', 0x0c523aff },
    },
    "                        "
    "                        "
    "             a     b    "
    "            a      b    "
    "            a     ab    "
    "           ac      b    "
    "           ac a    b    "
    "      a a  ad  a   b    "
    "     a  a aad  aa ab    "
    "     a  a acd aaacab    "
    "    aa  cdacdaddaadb    "
    "     aa cdaddaaddadb    "
    "     da ccaddcaddadb    "
    "    adcaacdaddddcadb    "
    "   aaccacadcaddccaab    "
    "   aacdacddcaadcaaab    "
    "   aaaddddaddaccaacb    "
    "   aaacddcaadacaaadb    "
    "    bbbbbbbbbbbbbbbb    "
    "    bbbbbbbbbbbbbbbb    "
  };

  check_picture(&objs->large, &pic);
}

void test_draw_sprite(TestObjs *objs) {
  ASSERT(read_image("img/NpcGuest.png", &objs->spritemap) == IMG_SUCCESS);

  struct Rect r = { .x = 1, .y = 1, .width = 14, .height = 14 };
  draw_rect(&objs->large, &r, 0x800080FF);

  struct Rect sue = { .x = 128, .y = 136, .width = 16, .height = 15 };
  draw_sprite(&objs->large, 4, 2, &objs->spritemap, &sue);

  Picture pic = {
    {
      { ' ', 0x000000ff },
      { 'a', 0x800080ff },
      { 'b', 0x9cadc1ff },
      { 'c', 0xefeae2ff },
      { 'd', 0x100000ff },
      { 'e', 0x264c80ff },
      { 'f', 0x314e90ff },
    },
    "                        "
    " aaaaaaaaaaaaaa         "
    " aaaaaaaaaaaaaa         "
    " aaaaaaaaaaaaaa         "
    " aaaaaaabccccccbc       "
    " aaaaacccccccccccc      "
    " aaaacbddcccddcbccc     "
    " aaacbbbeccccedbccc     "
    " aaacbbceccccebbbccc    "
    " aaabbbccccccccbbccc    "
    " aaaabbbcccccccb ccb    "
    " aaaabaaaaabbaa  cb     "
    " aaaaaaaaafffea         "
    " aaaaaaaaaffeea         "
    " aaaaaaacffffcc         "
    "        cffffccb        "
    "         bbbbbbb        "
    "                        "
    "                        "
    "                        "
  };

  check_picture(&objs->large, &pic);
}

void test_in_bounds(TestObjs *objs) {
  {
    //within bounds
    ASSERT(in_bounds(&objs->small, 3, 3) == 1);
  }
  {
    //on edge for small image
    ASSERT(in_bounds(&objs->small, 0, 0) == 1); 
    ASSERT(in_bounds(&objs->small, SMALL_W - 1, SMALL_H - 1) == 1); 
    ASSERT(in_bounds(&objs->small, SMALL_W - 1, 0) == 1); 
    ASSERT(in_bounds(&objs->small, 0, SMALL_H - 1) == 1);
  }
  {
    //outside bounds for small image
    ASSERT(in_bounds(&objs->small, -1, 3) == 0);
    ASSERT(in_bounds(&objs->small, SMALL_W, 3) == 0); 
    ASSERT(in_bounds(&objs->small, 3, -1) == 0);
    ASSERT(in_bounds(&objs->small, 3, SMALL_H) == 0);
  }
  {
    //large image
    ASSERT(in_bounds(&objs->large, 10, 10) == 1);
    ASSERT(in_bounds(&objs->large, LARGE_W, 10) == 0);
    ASSERT(in_bounds(&objs->large, 10, LARGE_H) == 0);
  }
  {
    // Edge cases for small image
    // Right before the edges
    ASSERT(in_bounds(&objs->small, 1, 0) == 1);
    ASSERT(in_bounds(&objs->small, 0, 1) == 1);
    ASSERT(in_bounds(&objs->small, SMALL_W - 2, SMALL_H - 1) == 1);
    ASSERT(in_bounds(&objs->small, SMALL_W - 1, SMALL_H - 2) == 1);
    // Right after the edges
    ASSERT(in_bounds(&objs->small, SMALL_W, 0) == 0);
    ASSERT(in_bounds(&objs->small, 0, SMALL_H) == 0);
    ASSERT(in_bounds(&objs->small, -1, SMALL_H - 1) == 0);
    ASSERT(in_bounds(&objs->small, SMALL_W - 1, -1) == 0);
  }
  {
    // Edge cases for large image
    // Right before the edges
    ASSERT(in_bounds(&objs->large, LARGE_W - 2, LARGE_H - 1) == 1);
    ASSERT(in_bounds(&objs->large, LARGE_W - 1, LARGE_H - 2) == 1);
    // Right after the edges
    ASSERT(in_bounds(&objs->large, LARGE_W, LARGE_H - 1) == 0);
    ASSERT(in_bounds(&objs->large, LARGE_W - 1, LARGE_H) == 0);
  }
}


void test_compute_index(TestObjs *objs) {
{
  //within bounds for small
  ASSERT(compute_index(&objs->small, 0, 0) == 0);
  ASSERT(compute_index(&objs->small, SMALL_W - 1, 0) == SMALL_W - 1);
  ASSERT(compute_index(&objs->small, 0, SMALL_H - 1) == (SMALL_H - 1) * SMALL_W);
  ASSERT(compute_index(&objs->small, SMALL_W - 1, SMALL_H - 1) == SMALL_W * SMALL_H - 1);
  ASSERT(compute_index(&objs->small, 3, 2) == 2 * SMALL_W + 3);
}
{
  //on edges for small
  ASSERT(compute_index(&objs->small, SMALL_W - 1, 1) == 1 * SMALL_W + (SMALL_W - 1));
  ASSERT(compute_index(&objs->small, 1, SMALL_H - 1) == (SMALL_H - 1) * SMALL_W + 1);
}
{
  //out of bounds for small
  ASSERT(compute_index(&objs->small, -1, 0) == -1);
  ASSERT(compute_index(&objs->small, 0, -1) == -8);
  ASSERT(compute_index(&objs->small, SMALL_W, 0) == 8); 
  ASSERT(compute_index(&objs->small, 0, SMALL_H) == 48); 
}
{
  //within bounds for large
  ASSERT(compute_index(&objs->large, 0, 0) == 0);
  ASSERT(compute_index(&objs->large, LARGE_W - 1, 0) == LARGE_W - 1); 
  ASSERT(compute_index(&objs->large, 0, LARGE_H - 1) == (LARGE_H - 1) * LARGE_W); 
  ASSERT(compute_index(&objs->large, LARGE_W - 1, LARGE_H - 1) == LARGE_W * LARGE_H - 1);
  ASSERT(compute_index(&objs->large, LARGE_W / 2, LARGE_H / 2) == (LARGE_H / 2) * LARGE_W + (LARGE_W / 2));
}
{
  //on edges for large
  ASSERT(compute_index(&objs->large, LARGE_W - 1, LARGE_H / 2) == (LARGE_H / 2) * LARGE_W + (LARGE_W - 1));
  ASSERT(compute_index(&objs->large, LARGE_W / 2, LARGE_H - 1) == (LARGE_H - 1) * LARGE_W + (LARGE_W / 2));
}
{
  //out of bounds for large
  ASSERT(compute_index(&objs->large, -1, 0) == -1);
  ASSERT(compute_index(&objs->large, 0, -1) == -24);
  ASSERT(compute_index(&objs->large, LARGE_W, 0) == 24);
  ASSERT(compute_index(&objs->large, 0, LARGE_H) == 480);
}
}

void test_clamp(TestObjs *objs) {
  // less than max
  ASSERT(clamp(SMALL_W / 2, 0, SMALL_W) == SMALL_W / 2);

  // equal to max
  ASSERT(clamp(SMALL_H + 1, 0, SMALL_H) == SMALL_H);

  // equal to min
  ASSERT(clamp(-1, 0, SMALL_W) == 0);

  // value itself, min
  ASSERT(clamp(LARGE_W - 1, 0, LARGE_W) == LARGE_W - 1);

  ASSERT(clamp(10, 0, 100) == 10); // within range
  ASSERT(clamp(-10, 0, 100) == 0); // below range
  ASSERT(clamp(110, 0, 100) == 100); // above range
}

void test_get_r(TestObjs *objs) {
  // only red
  ASSERT(get_r(0xFF000000) == 0xFF);
  // no red
  ASSERT(get_r(0x00EEEEBB) == 0x00);
  // mixed color
  ASSERT(get_r(0x78AFCDEF) == 0x78);
}

void test_get_g(TestObjs *objs) { 
  // only green
  ASSERT(get_g(0x00FF0000) == 0xFF);
  // no green
  ASSERT(get_g(0xFF00BB00) == 0x00);
  // mixed color
  ASSERT(get_g(0x12345678) == 0x34);
}

void test_get_b(TestObjs *objs) {
  // only blue
  ASSERT(get_b(0x0000FF00) == 0xFF);
  // no blue component
  ASSERT(get_b(0xFFEE0000) == 0x00);
  // mixed color
  ASSERT(get_b(0x90ABCD12) == 0xCD);

}

void test_get_a(TestObjs *objs) {
  // fully opacity
  ASSERT(get_a(0xAA00BBFF) == 0xFF);
  // fully transparency
  ASSERT(get_a(0xCC991300) == 0x00);
  // partially transparency
  ASSERT(get_a(0x3248907F) == 0x7F);
}

void test_blend_components(TestObjs *objs) {
{
  //opaque foreground
  ASSERT(blend_components(255, 0, 255) == 255);
  ASSERT(blend_components(0, 255, 255) == 0);
}
{
  //transparent foreground
  ASSERT(blend_components(255, 0, 0) == 0);
  ASSERT(blend_components(0, 255, 0) == 255);
}
{
  //low transparency 
  ASSERT(blend_components(255, 100, 10) == 106);
  ASSERT(blend_components(100, 255, 10) == 248);
  //high transparency 
  ASSERT(blend_components(255, 100, 245) == 248);
  ASSERT(blend_components(100, 255, 245) == 106);
}
{
  //50% transparency
  ASSERT(blend_components(255, 0, 128) == 128);
  ASSERT(blend_components(0, 255, 128) == 127); 
  //approx 40% transparency
  ASSERT(blend_components(100, 200, 100) == 160);
  //approx 80% transparency
  ASSERT(blend_components(100, 200, 200) == 121);
}
{
  //blending with same foreground and background values
  ASSERT(blend_components(123, 123, 255) == 123);
  ASSERT(blend_components(123, 123, 0) == 123);
  ASSERT(blend_components(123, 123, 128) == 123);
}
}

void test_blend_colors(TestObjs *objs) {
  // opaque foreground over transparent background
  ASSERT(blend_colors(0xFF0000FF, 0x00FF0000) == 0xFF0000FF);

  // transparent foreground over opaque background
  ASSERT(blend_colors(0xFF000000, 0x00FF00FF) == 0x00FF00FF);

  // transparent foreground over transparent background
  ASSERT(blend_colors(0x0000FF00, 0x00FF0000) == 0x00FF00FF);

  // color foreground over opaque background
  ASSERT(blend_colors(0x00FFFFFF80, 0xFF00FFFF) == 0xFF80FFFF);

  //color foreground over opaque background
  ASSERT(blend_colors(0xFF0000FE, 0x00FF00FF) == 0xFE0100FF);
  
  // color foreground over color background
  ASSERT(blend_colors(0xFF000001, 0x00FF00EE) == 0x01FE00FF);

  // color foreground over transparent background
  ASSERT(blend_colors(0xEEEEEE80, 0xFFFFFF00) == 0xF6F6F6FF);
}


void test_set_pixel(TestObjs *objs) {
  //small image
  {
    //opaque color
    set_pixel(&objs->small, SMALL_IDX(3, 3), 0xFF0000FF);
    ASSERT(objs->small.data[SMALL_IDX(3, 3)] == 0xFF0000FF);
  }
  {
    //corner pixel
    set_pixel(&objs->small, SMALL_IDX(0, 0), 0xFF0000FF);
    ASSERT(objs->small.data[SMALL_IDX(0, 0)] == 0xFF0000FF);
    //edge pixel
    set_pixel(&objs->small, SMALL_IDX(0, SMALL_H / 2), 0x00FF00FF);
    ASSERT(objs->small.data[SMALL_IDX(0, SMALL_H / 2)] == 0x00FF00FF);
  }
  {
    //transparent color
    uint32_t originalColor = objs->small.data[SMALL_IDX(3, 3)];
    set_pixel(&objs->small, SMALL_IDX(3, 3), 0x00FF0000);
    ASSERT(objs->small.data[SMALL_IDX(3, 3)] == originalColor);
  }
  {
    //out of bounds index
    set_pixel(&objs->small, objs->small.width * objs->small.height, 0x00FF00FF);
    //no alpha blending
    set_pixel(&objs->small, 0, 0xFFFFFFFF);
    ASSERT(objs->small.data[0] == 0xFFFFFFFF);
  }
  {
    //overwrite an existing color with a transparent one
    objs->small.data[SMALL_IDX(1, 1)] = 0xFFFFFFFF;
    set_pixel(&objs->small, SMALL_IDX(1, 1), 0x00000000);
    ASSERT(objs->small.data[SMALL_IDX(1, 1)] == 0xFFFFFFFF);
  }
  {
    // Semi-transparent color over white
    objs->small.data[SMALL_IDX(2, 2)] = 0xFFFFFFFF;
    set_pixel(&objs->small, SMALL_IDX(2, 2), 0xFF000080);
    ASSERT(objs->small.data[SMALL_IDX(2, 2)] == 0xFF7F7FFF);
  }
}

void test_set_pixel_2(TestObjs *objs) {
  //large image
  {
    //corner pixel
    int index = 0;
    set_pixel(&objs->large, index, 0xFF0000FF);
    ASSERT(objs->large.data[index] == 0xFF0000FF);
  }
  {
    //edge pixel
    int index_2 = (LARGE_H / 2) * LARGE_W;
    set_pixel(&objs->large, index_2, 0x00FF00FF);
    ASSERT(objs->large.data[index_2] == 0x00FF00FF);
  }
  {
    //transparent color
    int index_3 = LARGE_W - 1;
    uint32_t originalColor = objs->large.data[index_3];
    set_pixel(&objs->large, index_3, 0x00000000);
    ASSERT(objs->large.data[index_3] == originalColor);
  }
  {
    //last pixel of the image to opaque blue
    int index_4 = LARGE_W * LARGE_H - 1;
    set_pixel(&objs->large, index_4, 0x0000FFFF);
    ASSERT(objs->large.data[index_4] == 0x0000FFFF);
  }
  {
    //semi-transparent color
    int x = LARGE_W / 2;
    int y = LARGE_H / 2;
    int index_5 = y * LARGE_W + x;
    objs->large.data[index_5] = 0xFFFFFFFF;
    set_pixel(&objs->large, index_5, 0xFF000080);
    ASSERT(objs->large.data[index_5] == 0xFF7F7FFF);
  }
}


void test_square(TestObjs *objs) {
  //zero
  ASSERT(square(0) == 0);
  //pos
  ASSERT(square(1) == 1);
  ASSERT(square(12) == 144);
  ASSERT(square(1000) == 1000000);
  //neg
  ASSERT(square(-1) == 1);
  ASSERT(square(-12) == 144);
  ASSERT(square(-1000) == 1000000);
  //edge for int64 limits
  ASSERT(square(3037000499LL) == 9223372030926249001LL);
  ASSERT(square(-3037000499LL) == 9223372030926249001LL);
}

void test_square_dist(TestObjs *objs) {
  // distance within
  ASSERT(square_dist(0, 0, SMALL_W - 1, SMALL_H - 1) == (SMALL_W - 1) * (SMALL_W - 1) + (SMALL_H - 1) * (SMALL_H - 1));
  
  // distance from corner to corner
  ASSERT(square_dist(0, 0, LARGE_W - 1, LARGE_H - 1) == (LARGE_W - 1) * (LARGE_W - 1) + (LARGE_H - 1) * (LARGE_H - 1));
  
  // distance from a point inside to a point outside
  ASSERT(square_dist(SMALL_W - 1, SMALL_H - 1, SMALL_W, SMALL_H) == 1 * 1 + 1 * 1);
  ASSERT(square_dist(LARGE_W - 1, LARGE_H - 1, LARGE_W + 10, LARGE_H + 10) == 11 * 11 + 11 * 11);

  ASSERT(square_dist(0, 0, 3, 4) == 25);
  ASSERT(square_dist(-3, -4, 3, 4) == 100);
}
/* FACE.C - game library: character portraits built from face parts. */
#include "mps.h"
#include "gamelib.h"

extern void far drv_begin_image_grab();
extern void far drv_end_image_grab();
extern int  far drv_get_image();

init_face_parts()
{
    int i;

    drv_begin_image_grab();
    draw_face();
    for (i = 0; i < 16; i++)
        face_part_imgs[i] = drv_get_image(2, i % 8 * 9, i / 8 * 9 + 175, 8, 8);
    drv_end_image_grab();
    face_shown = -1;
}

draw_face_parts(face, x, y)
int face, x, y;
{
    if (face & 1) {
        draw_sprite_a((face & 2) * 2 + 0x48, x + 1, y + 1);
        draw_sprite_a((face >> 4 & 7) + 0x40, x + 1, y + 1);
        draw_sprite_a((face >> 7 & 7) + 0x38, x + 1, y + 1);
        draw_sprite_a((face >> 10 & 7) + 0x30, x + 1, y + 1);
        draw_sprite_a((face >> 13 & 7) + 0x28, x + 1, y + 1);
    } else {
        draw_sprite_a((face & 2) * 2 + 0x20, x + 1, y + 1);
        draw_sprite_a((face >> 4 & 7) + 0x18, x + 1, y + 1);
        draw_sprite_a((face >> 7 & 7) + 0x10, x + 1, y + 1);
        draw_sprite_a((face >> 10 & 7) + 8, x + 1, y + 1);
        draw_sprite_a(face >> 13 & 7, x + 1, y + 1);
    }
    if (video_mode != 'C')
        switch (face >> 2 & 3) {
        case 0:
            drv_recolor_rect(g_gfx, x, y, 32, 35, 11, 14);
            break;
        case 1:
            drv_recolor_rect(g_gfx, x, y, 32, 35, 11, 6);
            break;
        case 3:
            drv_recolor_rect(g_gfx, x, y, 32, 35, 12, 6);
        case 2:
            drv_recolor_rect(g_gfx, x, y, 32, 35, 11, 5);
            break;
        }
    face_shown = -1;
}

draw_portrait(face, x, y)
int face, x, y;
{
    int unused;

    drv_set_color_map(face_colormap, face_colormap);
    gfx_fill_rect(g_gfx, x - 2, y - 2, 54, 56, 7);
    gfx_fill_rect(g_gfx, x - 1, y - 1, 52, 54, 15);
    gfx_fill_rect(g_gfx, x + 2, y + 2, 46, 45, 0);
    if ((face >> 2 & 3) == 3 && video_mode != 'C')
        gfx_fill_rect(g_gfx, x + 3, y + 3, 44, 43, 7);
    else
        gfx_fill_rect(g_gfx, x + 3, y + 3, 44, 43, 3);
    draw_face_parts(face, x + 13, y + 3);
    if (video_mode != 'C') {
        drv_recolor_rect(g_gfx, x, y, 50, 50, 8, 5);
        drv_recolor_rect(g_gfx, x, y, 50, 50, 12, 7);
        drv_recolor_rect(g_gfx, x, y, 50, 50, 14, 15);
        drv_recolor_rect(g_gfx, x, y, 50, 50, 6, 8);
        drv_recolor_rect(g_gfx, x, y, 50, 50, 4, 8);
        drv_recolor_rect(g_gfx, x, y, 50, 50, 1, 8);
        drv_recolor_rect(g_gfx, x, y, 50, 50, 10, 7);
        drv_recolor_rect(g_gfx, x, y, 50, 50, 9, 7);
    }
    draw_sprite_a((face & 1 ? 0x68 : 0x70) + (face & 3), x + 3, y + 28);
    drv_set_color_map(std_colormap, std_colormap2);
}

draw_face()
{
    int dummy, i;

    load_picture(2, "facesf.pic");
    for (i = 0; i < 40; i++)
        faces_f[i] = drv_get_image(2, i % 8 * 32 + 1, i / 8 * 35 + 1, 30, 33);
    for (i = 0; i < 4; i++)
        face_extra_f[i] = drv_get_image(2, 257, i * 20, 44, 18);
    load_picture(2, "faces.pic");
    for (i = 0; i < 40; i++)
        faces_m[i] = drv_get_image(2, i % 8 * 32 + 1, i / 8 * 35 + 1, 30, 33);
    for (i = 0; i < 7; i++)
        face_hair[i] = drv_get_image(2, i * 32 + 96, 174, 32, 26);
    for (i = 0; i < 4; i++)
        face_extra_m[i] = drv_get_image(2, 257, i * 20, 44, 18);
    face_img_a = drv_get_image(2, 73, 175, 21, 22);
    face_img_b = drv_get_image(2, 307, 0, 11, 8);
    face_img_c = drv_get_image(2, 307, 9, 12, 8);
    face_img_d = drv_get_image(2, 257, 160, 26, 14);
}

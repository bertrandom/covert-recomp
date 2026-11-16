/* ROOMVIEW.C - Covert Action building infiltration (TAC.EXE): the room view,
 * the building map and the sprites (draw_room_objects .. load_tac_sprites,
 * image 64F4-6B26).
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas.
 *
 * A separate object from ROOM.C: LINK writes the relocations record by record,
 * and MSC (no /Zd) closes a code record at 0x3B0 bytes, so starting a new
 * object here puts the record breaks at 64F4 and 68A6, inside relocwin.py's
 * windows 64EB-6601 and 688A-68A9; compiled as one file with ROOM.C, a record
 * started at 698B, inside the relocation run 68A9-6B20. */
#include "mps.h"
#include "tac.h"

/* Assembly segment (far) */
extern int far drv_begin_image_grab();
extern int far drv_get_image();
extern int far drv_end_image_grab();
extern int far gate_thunk_b();

/* The room view: floor, objects, frame, room name. */
draw_room_objects(room)
int room;
{
    int i, j, sy, tile;

    fill_rect_xy(0, 0, 172, 200, 1);
    for (j = 0; j < 200; j += 2)
        draw_line(0, j, 172, j, 5);
    draw_line(171, 0, 171, 199, 15);
    draw_line(172, 0, 172, 199, 5);
    view_x0 = -(rooms[room].w * 16 / 2 - 88);
    view_y0 = -(rooms[room].h * 16 / 2 - 108);
    room_right = view_x0 + rooms[room].w * 16 - 1;
    room_bottom = rooms[room].h * 16 + view_y0 - 1;
    for (i = 0; i < rooms[room].w; i++)
        for (j = 0; j < rooms[room].h; j++)
            drv_copy_rect(sprite_page, 0, 112, 16, 16, g_gfx, i * 16 + view_x0, j * 16 + view_y0);
    room_left = rooms[room].x * 16;
    room_top = rooms[room].y * 16;
    room_right = rooms[room].w * 16 + room_left - 1;
    room_bottom = rooms[room].h * 16 + room_top - 1;
    for (j = 0; j < rooms[room].h; j++)
        for (i = 0; i < rooms[room].w; i++) {
            tile = building[rooms[room].x + i][rooms[room].y + j];
            if (tile != -1) {
                sy = obj_types[tile & 0x3f].sy;
                if (tile & 0x80) sy += 16;
                tile &= 0x3f;
                drv_copy_rect(sprite_page, obj_types[tile].sx, sy, 16, 16, g_gfx,
                              i * 16 + view_x0, j * 16 + view_y0);
            }
        }
    draw_rect_outline(view_x0 - 1, view_y0 - 1, rooms[room].w * 16 + 1, rooms[room].h * 16 + 1, 11);
    drv_copy_rect(g_gfx, 0, 0, 172, 200, back_page, 0, 0);
    draw_rect_outline(26, 0, 143, 18, 7);
    gfx_fill_rect(g_gfx, 27, 1, 141, 16, 1);
    draw_text_transparent(tac_mode == 3 ? "Street" : room_types[rooms[cur_room].type].name, 32, 2, 15);
    draw_equipment_panel();
}

/* Redraw the object at a map cell; a door also opens or closes the
 * door cell it faces, with a sound when it is in the current room. */
reveal_rooms(x, y)
int x, y;
{
    int nx, ny, sx, sy, spr_y, tile, n;

    tile = building[x][y];
    if (tile != -1 && room_map[x][y] == cur_room) {
        spr_y = obj_types[tile & 0x3f].sy;
        if (tile & 0x80) spr_y += 16;
        tile &= 0x3f;
        sx = (x - rooms[cur_room].x) * 16 + view_x0;
        sy = (y - rooms[cur_room].y) * 16 + view_y0;
        drv_copy_rect(sprite_page, obj_types[tile].sx, spr_y, 16, 16, g_gfx, sx, sy);
        drv_copy_rect(g_gfx, sx, sy, 16, 16, back_page, sx, sy);
    }
    if (obj_types[tile & 0x3f].flags & 0x10) {
        n = tile & 3;
        nx = door_dx[n] + x;
        ny = door_dy[n] + y;
        building[nx][ny] &= 0x7f;
        building[nx][ny] += building[x][y] & 0x80;
        if (room_map[nx][ny] == cur_room) {
            play_sound(building[nx][ny] & 0x80 ? 13 : 14);
            reveal_rooms(nx, ny);
        }
    }
}

approx_distance(dx, dy)
int dx, dy;
{
    dx = abs(dx);
    dy = abs(dy);
    if (dx > dy)
        return dy / 2 + dx;
    return dx / 2 + dy;
}

draw_sprite_a(n, x, y)
int n, x, y;
{
    gate_thunk_b(g_gfx, x, y, actor_imgs[n]);
}

erase_actor_sprite(n, x, y)
int n, x, y;
{
    gate_thunk_b(g_gfx, x, y, sprite_imgs[n]);
}

load_tac_sprites()
{
    int i, j;

    drv_begin_image_grab();
    if (real_mission) draw_face();
    if (options & 2)
        load_picture_swapped("spritesf.pic", 2);
    else
        load_picture_swapped("sprites.pic", 2);
    switch (cur_org % 3) {
    case 0:
        alarm_color = 14;
        break;
    case 1:
        alarm_color = 11;
        break;
    case 2:
        alarm_color = 15;
        break;
    }
    if (mono_display)
        alarm_color = 14;
    else
        drv_recolor_rect(sprite_page, 0, 0, 320, 200, 14, alarm_color);
    for (i = 0; i < 8; i++)
        for (j = 0; j < 20; j++)
            sprite_imgs[i * 20 + j] = drv_get_image(2, j * 16 + 1, i * 16 + 1, 15, 15);
    for (i = 0; i < 6; i++)
        icon_imgs[i] = drv_get_image(2, i * 16 + 1, 129, 15, 15);
    for (i = 0; i < 8; i++)
        icon2_imgs[i] = drv_get_image(2, i * 16 + 1, 145, 15, 15);
    cursor_img = drv_get_image(2, 97, 129, 15, 15);
    drv_end_image_grab();
}

/* Emitted at the end of the file, after load_tac_sprites' literals. */
int dir_from_sign[3][3] = { { 8, 7, 6 }, { 1, 0, 5 }, { 2, 3, 4 } };
int room_none = -1;

/* CHASE.C - Covert Action car chase (CHASE.EXE): entry point, program hooks and
 * the env block reader.
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "mps.h"
#include "chase.h"

#define FP_SEG(p) (*((unsigned *)&(p) + 1))
#define FP_OFF(p) (*((unsigned *)&(p)))

/* Assembly library / graphics driver entry points (far) */
extern int far link_driver_stubs();
extern int far drv_alloc_page();
extern int far drv_set_page();
extern int far drv_begin_image_grab();
extern int far drv_get_image();
extern int far drv_end_image_grab();
extern int far drv_slot8();
extern int far drv_play_sound();

/* MicroProse C library / MS C runtime */
extern int strcpy();
extern int strcat();
extern int movedata();
extern int read();
extern int int86();
extern int _dos_freemem();

/* Initialized data, held by MSC until the end of main: after main's strings, before
 * DRIVE's. The game library's tables and pages and the color maps (unused by CHASE,
 * as in the other programs), then CHASE's own. */
char persons[64][16] = { 0 };       /* 022A struct Person, Site, Clue in gamelib.h */
char sites[256][12] = { 0 };        /* 062A */
char clues[80][12] = { 0 };         /* 122A */
int jailbreak_person = -1;                         /* 15EA */
RastPort work_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *work_page = &work_rp;                    /* 15FE */
RastPort back_rp = { 1, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *back_page = &back_rp;                    /* 1612 */
char spare_colormaps[2][16] = {                   /* 1614 */
    { 0, 0, 0x01, 0, 0x02, 0, 0, 0x02, 0, 0x01, 0x03, 0x01, 0x02, 0x01, 0, 0x03 },
    { 0, 0x01, 0x11, 0x11, 0x02, 0, 0x02, 0x03, 0x30, 0x11, 0x13, 0x31, 0x22, 0x23, 0x33, 0x33 },
};
char std_colormap[16] = { 0, 0, 0x01, 0, 0x02, 0, 0, 0x02, 0, 0x01, 0x02, 0x03, 0x02, 0x01, 0x01, 0x03 };
char std_colormap2[16] = { 0, 0, 0x11, 0x11, 0x22, 0, 0, 0x22, 0, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33 };
char colormap[64] = {                             /* 1654 */
    0, 0, 0x11, 0x11, 0x22, 0x22, 0x22, 0x22, 0, 0x22, 0x33, 0x33, 0, 0, 0x11, 0x33,
    0, 0x22, 0, 0, 0, 0, 0, 0, 0, 0x22, 0x22, 0, 0, 0, 0x11, 0x33,
    0, 0x12, 0x11, 0x10, 0x11, 0, 0x12, 0x33, 0x22, 0x13, 0x33, 0x11, 0x33, 0x22, 0x33, 0x33,
    0, 0x12, 0, 0, 0x22, 0, 0, 0x13, 0x02, 0x11, 0, 0, 0, 0, 0x33, 0x33,
};
char tele_colors[32] = {                          /* 1694 */
    0, 0x11, 0x11, 0x11, 0x22, 0, 0x22, 0x12, 0, 0x11, 0x11, 0x33, 0x33, 0x22, 0x33, 0x33,
    0, 0x11, 0x11, 0x11, 0x22, 0, 0x22, 0x12, 0, 0x11, 0x11, 0x33, 0x33, 0x22, 0x33, 0x33,
};
char face_colormap[16] = { 0, 0x11, 0x11, 0x01, 0x22, 0, 0x22, 0x22, 0, 0x11, 0x11, 0x33, 0x33, 0x33, 0x33, 0x33 };
char terminal_colormap[16] = { 0, 0, 0x11, 0x11, 0x22, 0, 0, 0x11, 0x22, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33 };
char colormap_16d4[16] = { 0, 0, 0x11, 0x11, 0x22, 0, 0, 0x22, 0, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33 };
char select_palette[16] = { 0, 0, 0x11, 0x11, 0x22, 0, 0, 0x33, 0x22, 0x22, 0x11, 0x33, 0x22, 0x33, 0x22, 0x33 };   /* 16E4 car selection screen */
int chase_mode = 0;                                /* 16F4 */
int game_speed = 1;                                /* 16F6 */
int cur_disk = 2;                                  /* 16F8 */
char chase_palette[17] = { 14, 1, 2, 3, 4, 0, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0 };   /* 16FA 16 colors + border */
Rect car_shape_rect[16] = {                       /* 170C */
    { 5, 84, 53, 116 }, { 8, 117, 50, 145 },
    { 10, 146, 48, 171 }, { 12, 172, 46, 194 },
    { 71, 84, 102, 104 }, { 74, 106, 100, 123 },
    { 75, 126, 99, 142 }, { 77, 143, 97, 156 },
    { 78, 157, 96, 168 }, { 80, 169, 94, 178 },
    { 81, 179, 94, 187 }, { 81, 188, 92, 195 },
    { 60, 169, 68, 175 }, { 61, 176, 68, 180 },
    { 62, 181, 67, 184 }, { 63, 185, 66, 187 },
};
int offscreen_page = 0;                            /* 178C */
char text_palette[17] = { 0, 1, 2, 3, 4, 0, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0 };   /* 178E */
int dir_dx[4] = { 0, 1, 0, -1 };   /* 17A0 */
int dir_dy[4] = { -1, 0, 1, 0 };
unsigned speed_masks[5] = { 0, 1, 9, 21, 27 };   /* 17B0 */
int wall_x[4][2] = { { 2, 7 }, { 8, 8 }, { 2, 7 }, { 0, 0 } };   /* 17BA */
int wall_y[4][2] = { { 0, 0 }, { 2, 7 }, { 8, 8 }, { 2, 7 } };
int cur_car = 1;                                   /* 17DA */
RastPort sprite_rp = { 3, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *sprite_page = &sprite_rp;                /* 17EE */
RastPort scene_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *scene_page = &scene_rp;                  /* 1802 */
RastPort windshield_rp = { 0, 201, 1, 318, 75, 0, 15, 4, 0 };   /* the windshield view */
RastPort *car_sprites = &windshield_rp;           /* 1816 */

main()
{
    int sex, i, hour;

    read_env_params("env.sve");
    switch ((char)ENV[0]) {
    case 3:
    case 14:
        chase_mode = 0;
        break;
    case 5:
        chase_mode = 1;
        break;
    case 6:
        chase_mode = 2;
        break;
    }
    sex = (char)ENV[10];
    ENV[0] = 0xFF;
    ENV[13] = 1;
    game_speed = (env_flags >> 10) & 3;
    difficulty = clamp(difficulty - ((env_flags >> 2) & 3) + 1, 0, 3);
    alert_level = *(int far *)(ENV + 0x48);
    hour = game_time / 60 % 24;
    is_night = (hour < 8 || hour >= 20) ? 1 : 0;
    is_cga = ((video_mode = ENV[0x44]) == 'C') ? 1 : 0;
    link_driver_stubs(*(int far *)(ENV + 0x60));
    link_driver_stubs(*(int far *)(ENV + 0x62));
    link_driver_stubs(*(int far *)(ENV + 0x64));
    drv_set_page(3, offscreen_page = drv_alloc_page(3));
    g_gfx->font = 1;
    g_gfx->fillcolor = 15;
    drv_begin_image_grab();
    load_picture(3, "chase.pic");
    for (i = 0; i < 16; i++)
        car_shapes[i] = drv_get_image(3, car_shape_rect[i].x0, car_shape_rect[i].y0,
                                      car_shape_rect[i].x1 - car_shape_rect[i].x0 + 1,
                                      car_shape_rect[i].y1 - car_shape_rect[i].y0 + 1);
    drv_end_image_grab();
    load_picture(2, "street.pic");
    real_mission = 1;
    randomize();
    drv_set_palette(chase_palette);
    if (chase_mode != 2) car_select_screen();
    g_gfx->font = 2;
    empty_hook();
    generate_city_map();
    init_cars();
    do {
        chase_loop();
        chase_clock++;
        wait_retrace(game_speed == 1 ? 4 : game_speed ? 0 : 8);
    } while (!chase_over);
    play_sound(0);
    if (outcome == 0) {
        if (chase_mode == 0) {
            if (chase_over != 2)
                strcpy(message, "'We've totally lost\ntrack of this guy.\nLet's go back to\nwhere we started.'\n");
            else {
                strcpy(message, (sex & 1) ? "He" : "She");
                strcat(message, " turns the corner\nand dashes into a\ncrowded restaurant.\n");
                strcat(message, "'We'll have to\nbe less obvious\nnext time, Max.'\n");
            }
        }
        if (chase_mode == 2)
            strcpy(message, "You dash into the\nbuilding seconds ahead\nof your pursuers!\n");
    }
    if (outcome == 1) {
        if (chase_mode == 0) {
            strcpy(message, (sex & 1) ? "He" : "She");
            strcat(message, " pulls over\nand walks into\na building as you\nquietly park nearby.\n");
        }
        if (chase_mode == 2)
            strcpy(message, "Your pursuers run\nyou off the road!\n");
    }
    if (outcome == 2) {
        strcpy(message, "You run ");
        strcat(message, (sex & 1) ? "his" : "her");
        strcat(message, " car\noff the road and\nmake the arrest!\n");
    }
    drv_set_palette(text_palette);
    g_gfx->font = 1;
    text_window(message, 100, 80);
    ENV[9] = outcome;
    ENV[10] = clamp(score * 25, 0, 100);
    ENV[0] = (options & 0x20) ? 0x11 : 0;
    ENV[13] = 1;
    ENV[15] = chase_clock / 60;
    env_flags = env_flags & 0xF7FF | game_speed << 10;
    *(int far *)(ENV + 0x4E) = env_flags;
    _dos_freemem(car_shapes[0]);
    set_exit_state(0, 0);
    drv_slot8(3);
    require_disk((options & 0x20) ? 1 : 2, 1L);
}

set_exit_state(flag)
int flag;
{
    if (flag) ENV[0] = 0xFF;
}

play_sound(n)
int n;
{
    if (options & 4) drv_play_sound(n, sound_param);
}

bios_set_page(page)
int page;
{
    bios_regs.h.ah = 5; bios_regs.h.al = page;
    int86(0x10, &bios_regs, &bios_regs);
}

stub0()                             /* unreferenced, as in CODE and BUG */
{
}

draw_status_bar()
{
}

draw_face_parts()
{
}

read_env_params(name)
char *name;
{
    city_id = *(int far *)(ENV + 0x20);
    target_building = *(int far *)(ENV + 0x22);
    options = *(int far *)(ENV + 0x24);
    env26 = *(int far *)(ENV + 0x26);
    env28 = *(int far *)(ENV + 0x28);
    env2a = *(int far *)(ENV + 0x2A);
    env2c = *(int far *)(ENV + 0x2C);
    env2e = *(int far *)(ENV + 0x2E);
    game_time = *(int far *)(ENV + 0x30);
    env32 = *(int far *)(ENV + 0x32);
    env34 = *(int far *)(ENV + 0x34);
    env36 = *(int far *)(ENV + 0x36);
    env38 = *(int far *)(ENV + 0x38);
    difficulty = *(int far *)(ENV + 0x3A);
    env3c = *(int far *)(ENV + 0x3C);
    num_agents = *(int far *)(ENV + 0x3E);
    num_plots = *(int far *)(ENV + 0x40);
    env42 = *(int far *)(ENV + 0x42);
    env44 = *(int far *)(ENV + 0x44);
    env46 = *(int far *)(ENV + 0x46);
    env4a = *(int far *)(ENV + 0x4A);
    env4c = *(int far *)(ENV + 0x4C);
    env_flags = *(int far *)(ENV + 0x4E);
    env_pos = 0x400;
    read_far_block(env_file, player_block, 0x28E);
    read_far_block(env_file, agents, num_agents * 0x30);
    read_far_block(env_file, agent_extra, num_agents * 6);
    read_far_block(env_file, plots, num_plots * 0x2C);
    read_far_block(env_file, cities, 0x220);
    read_far_block(env_file, orgs, 0x240);
}

read_far_block(fd, buf, n)
int fd;
char *buf;
unsigned n;
{
    char far *dst;

    if (env_pos) {
        dst = buf;
        env_cur = ENV + env_pos;
        movedata(FP_SEG(env_cur), FP_OFF(env_cur), FP_SEG(dst), FP_OFF(dst), n);
        env_pos += n;
    } else
        read(fd, buf, n);
}

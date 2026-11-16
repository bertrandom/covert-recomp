/* TAC.C - Covert Action building infiltration (TAC.EXE): entry point and program
 * hooks (main .. draw_status_bar, image 0E98-158E).
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas.
 * Compiled WITHOUT /Zd: under /Zd MSC keeps the add sp,6 before set_dac_color's
 * epilogue, which the original lacks. Its records break at 1215 (99 fixups) and
 * at the object end 158E. The rest of the program's code is BREAKIN.C (/Zd). */
#include "mps.h"
#include "tac.h"

/* Assembly segment (far) */
extern int far link_driver_stubs();
extern int far drv_alloc_page();
extern int far drv_set_page();
extern int far drv_begin_image_grab();
extern int far drv_get_image();
extern int far drv_end_image_grab();
extern int far drv_slot8();
extern int far drv_play_sound();
extern int far drv_call_gate();

/* MicroProse library and MS C runtime */
extern char *itoa();
extern char *strcpy();
extern char *strcat();
extern int int86();

/* Initialized data: held back until the end of main, so it follows main's
 * literals in DGROUP (00B2-1C26). */
struct RoomType room_types[10] = {
    { "Office", 4, 2, 7 },
    { "File Room", 6, 1, 7 },
    { "Computer Room", 8, 4, 7 },
    { "Cafeteria", 2, 4, 7 },
    { "Lounge", 2, 2, 7 },
    { "Cipher Room", 12, 1, 7 },
    { "Bed Room", 6, 2, 0 },
    { "Bathroom", 12, 1, 7 },
    { "Kitchen", 4, 2, 0 },
    { "Storage Room", 4, 4, 7 },
};
struct ObjType obj_types[62] = {
    { "Wall", 0, 0, 0x0, 0x0 },
    { "Wall", 16, 0, 0x0, 0x0 },
    { "Wall", 32, 0, 0x0, 0x0 },
    { "Wall", 48, 0, 0x0, 0x0 },
    { "Wall", 64, 0, 0x0, 0x0 },
    { "Wall", 80, 0, 0x0, 0x0 },
    { "Wall", 96, 0, 0x0, 0x0 },
    { "Wall", 112, 0, 0x0, 0x0 },
    { "Door", 64, 16, 0x12, 0x0 },
    { "Door", 80, 16, 0x12, 0x0 },
    { "Door", 96, 16, 0x12, 0x0 },
    { "Door", 112, 16, 0x12, 0x0 },
    { "Chair", 128, 0, 0x1, 0x219 },
    { "Chair", 144, 0, 0x1, 0x218 },
    { "Chair", 160, 0, 0x1, 0x219 },
    { "Chair", 176, 0, 0x1, 0x218 },
    { "Terminal", 192, 0, 0x201, 0x25 },
    { "Typewriter", 208, 0, 0x5, 0x3 },
    { "Terminal", 224, 0, 0x201, 0x21 },
    { "Typewriter", 240, 0, 0x5, 0x3 },
    { "Chair", 256, 0, 0x1, 0x445 },
    { "Plant", 272, 0, 0x5, 0x451 },
    { "Chair", 288, 0, 0x1, 0x445 },
    { "Plant", 304, 0, 0x5, 0x451 },
    { "Files", 128, 16, 0x12b, 0x207 },
    { "Files", 144, 16, 0x12b, 0x227 },
    { "Files", 160, 16, 0x12b, 0x207 },
    { "Files", 176, 16, 0x12b, 0x227 },
    { "Floor Safe", 192, 16, 0x12b, 0x66 },
    { "Wall Safe", 208, 16, 0x10a, 0x23 },
    { "Picture", 224, 16, 0x106, 0x459 },
    { "Wall Safe", 240, 16, 0x10a, 0x463 },
    { "Table", 64, 48, 0x81, 0x318 },
    { "Table", 80, 48, 0x81, 0x318 },
    { "Desk", 32, 16, 0x4b, 0x1 },
    { "Desk", 48, 16, 0x4b, 0x1 },
    { "Desk", 0, 16, 0x4b, 0x1 },
    { "Desk", 16, 16, 0x4b, 0x1 },
    { "Couch", 96, 48, 0x45, 0x611 },
    { "Couch", 112, 48, 0x45, 0x611 },
    { "Toilet", 0, 64, 0x10b, 0x80 },
    { "Toilet", 16, 64, 0x10b, 0x80 },
    { "Sink", 96, 64, 0x10b, 0x80 },
    { "Sink", 112, 64, 0x10b, 0x80 },
    { "Bathtub", 128, 64, 0x41, 0x80 },
    { "Bathtub", 144, 64, 0x41, 0x80 },
    { "Bed", 192, 48, 0x41, 0x40 },
    { "Bed", 208, 48, 0x41, 0x40 },
    { "Range", 160, 64, 0x101, 0x100 },
    { "Range", 176, 64, 0x101, 0x100 },
    { "Refrigerator", 192, 80, 0x121, 0x100 },
    { "Refrigerator", 208, 80, 0x121, 0x100 },
    { "Stereo", 224, 48, 0x101, 0x650 },
    { "Television", 240, 48, 0x101, 0x440 },
    { "Lamp", 256, 48, 0x101, 0x608 },
    { "Television", 272, 48, 0x101, 0x400 },
    { "Computer", 0, 48, 0x125, 0x24 },
    { "Drawers", 16, 96, 0x10b, 0x440 },
    { "Computer", 32, 48, 0x125, 0x24 },
    { "Drawers", 48, 96, 0x10b, 0x440 },
    { "MacGuffin  ", 0, 96, 0x3, 0x0 },
    { "Local Agent", 256, 16, 0x3, 0x0 },
};
int step_dx[9] = { 0, 0, 2, 3, 2, 0, -2, -3, -2 };
int step_dy[9] = { 0, -3, -2, 0, 2, 3, 2, 0, -2 };
int dir_dx[9] = { 0, 0, 1, 1, 1, 0, -1, -1, -1 };
int dir_dy[9] = { 0, -1, -1, 0, 1, 1, 1, 0, -1 };
int door_dx[5] = { 0, 1, 0, -1, 0 };
int door_dy[5] = { -1, 0, 1, 0, -1 };
RastPort sprite_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *sprite_page = &sprite_rp;
RastPort display_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *display_page = &display_rp;
RastPort work_rp = { 3, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *work_page = &work_rp;

/* The game state loaded from env.sve (the game library's tables) */
struct Person persons[64] = { 0 };
struct Site sites[256] = { 0 };
char clues[80][12] = { 0 };         /* struct Clue in gamelib.h */
int jailbreak_person = -1;
RastPort lib_work_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *lib_work_page = &lib_work_rp;     /* work_page in gamelib.h; unused by TAC */
RastPort back_rp = { 1, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *back_page = &back_rp;

/* Color maps */
char spare_colormaps[2][16] = {
    0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x00, 0x02, 0x00, 0x01, 0x03, 0x01, 0x02, 0x01, 0x00, 0x03,
    0x00, 0x01, 0x11, 0x11, 0x02, 0x00, 0x02, 0x03, 0x30, 0x11, 0x13, 0x31, 0x22, 0x23, 0x33, 0x33,
};
char std_colormap[16] = {
    0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x00, 0x02, 0x00, 0x01, 0x02, 0x03, 0x02, 0x01, 0x01, 0x03,
};
char std_colormap2[16] = {
    0x00, 0x00, 0x11, 0x11, 0x22, 0x00, 0x00, 0x22, 0x00, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33,
};
char colormap[64] = {
    0x00, 0x00, 0x11, 0x11, 0x22, 0x22, 0x22, 0x22, 0x00, 0x22, 0x33, 0x33, 0x00, 0x00, 0x11, 0x33,
    0x00, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x22, 0x22, 0x00, 0x00, 0x00, 0x11, 0x33,
    0x00, 0x12, 0x11, 0x10, 0x11, 0x00, 0x12, 0x33, 0x22, 0x13, 0x33, 0x11, 0x33, 0x22, 0x33, 0x33,
    0x00, 0x12, 0x00, 0x00, 0x22, 0x00, 0x00, 0x13, 0x02, 0x11, 0x00, 0x00, 0x00, 0x00, 0x33, 0x33,
};
char tele_colors[32] = {
    0x00, 0x11, 0x11, 0x11, 0x22, 0x00, 0x22, 0x12, 0x00, 0x11, 0x11, 0x33, 0x33, 0x22, 0x33, 0x33,
    0x00, 0x11, 0x11, 0x11, 0x22, 0x00, 0x22, 0x12, 0x00, 0x11, 0x11, 0x33, 0x33, 0x22, 0x33, 0x33,
};
char face_colormap[16] = {
    0x00, 0x11, 0x11, 0x01, 0x22, 0x00, 0x22, 0x22, 0x00, 0x11, 0x11, 0x33, 0x33, 0x33, 0x33, 0x33,
};
char terminal_colormap[16] = {
    0x00, 0x00, 0x11, 0x11, 0x22, 0x00, 0x00, 0x11, 0x22, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33,
};
char tac_colormap[32] = {
    0x00, 0x00, 0x11, 0x11, 0x22, 0x00, 0x00, 0x22, 0x00, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33,
    0x00, 0x00, 0x11, 0x11, 0x22, 0x00, 0x00, 0x33, 0x22, 0x22, 0x11, 0x33, 0x22, 0x33, 0x22, 0x33,
};
int game_speed = 1;
int room_type_filter = 1;
int cur_disk = 3;
char tune_data[5][17] = {
    { 0, 1, 2, 3, 4, 0, 6, 7, 8, 9, 10, 11, 12, 0, 14, 15, 0 },
    { 0, 1, 2, 15, 4, 0, 6, 7, 8, 9, 10, 11, 12, 0, 14, 15, 0 },
    { 0, 1, 2, 3, 4, 0, 6, 12, 8, 9, 10, 11, 12, 0, 14, 15, 0 },
    { 0, 1, 2, 14, 4, 0, 6, 7, 8, 9, 10, 11, 12, 0, 14, 15, 0 },
    { 0, 1, 2, 0, 4, 0, 6, 7, 8, 9, 10, 11, 12, 0, 14, 15, 0 },
};
int page3 = 0;

main()
{
    int i, loc;

    if (ENV[0] == 7) tac_mode = 1;
    if (ENV[0] == 8) tac_mode = 2;
    if (ENV[0] == 10) tac_mode = 3;
    if (options & 0x20) tac_mode = 0;
    ENV[0] = 0xFF;
    load_env("env.sve");
    game_speed = (env_flags >> 8) & 3;
    orig_difficulty = difficulty;
    difficulty = difficulty - (env_flags & 3) + 1;
    if (tac_mode == 2) difficulty++;
    if (tac_mode == 0) alert_level = *(int far *)(ENV + 0x48);
    if (orig_difficulty)
        difficulty += clamp(alert_level * orig_difficulty / 50, 0, 1);
    else
        difficulty = 0;
    difficulty = clamp(difficulty, 0, 4);
    target_person = -1;
    if (tac_mode == 0)
        for (i = 0; i < n_persons; i++)
            if (persons[i].org == cur_org && persons[i].city == cur_city)
                target_person = i;
    if (persons[target_person].status < 0 && persons[target_person].status != -3)
        target_person = -1;
    if (tac_mode == 2) target_person = (char)ENV[12];
    hour = clock_base / 60 % 24;
    is_night = hour < 8 || hour >= 20;
    real_mission = 1;
    guards_left = difficulty * 4 + 8;
    if (tac_mode == 2) guards_left = orig_difficulty * 2 + 4;
    if (tac_mode == 3) guards_left = orig_difficulty * 2 + 2;
    if (tac_mode == 1) guards_left = difficulty * 3 + 3;
    link_driver_stubs(*(int far *)(ENV + 0x60));
    link_driver_stubs(*(int far *)(ENV + 0x62));
    link_driver_stubs(*(int far *)(ENV + 0x64));
    srand((unsigned)(cur_city + 13) * (cur_org + 7) * 23 + (game_seed & 0x3fff));
    page3 = drv_alloc_page(3);
    drv_set_page(3, page3);
    g_gfx->font = 1;
    g_gfx->fillcolor = 15;
    play_tune(0);
    drv_begin_image_grab();
    load_picture_swapped("camera.pic", 2);
    camera_img = drv_get_image(2, 0, 0, 196, 112);
    camera_img2 = drv_get_image(2, 200, 0, 72, 61);
    drv_end_image_grab();
    load_tac_sprites();
    drv_copy_rect(sprite_page, 0, 160, 320, 40, back_page, 0, 160);
    if (tac_mode != 3)
        load_picture_swapped("guys3.pic", 2);
    else
        load_picture_swapped("guys2.pic", 2);
    drv_copy_rect(back_page, 0, 160, 320, 40, sprite_page, 0, 160);
    generate_building();
    randomize();
    choose_password();
    if ((options & 0x20) || !target_person || (raided_cities & (1 << cur_city)))
        on_alert = 1;
    if (!target_person && difficulty < 4) difficulty++;
    if (on_alert) guards_left += difficulty * 2;
    loc = set_location_known(cur_org, cur_city, 0);
    if (loc != -1)
        for (i = 0; i <= n_rooms; i++)
            if ((1L << i) & sites[loc].rooms_seen)
                rooms[i].flags |= 2;
    if (options & 2)
        load_picture_swapped("equip1.pic", 1);
    else
        load_picture_swapped("equip1m.pic", 1);
    if (tac_mode == 0) drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
    flush_input();
    setup_break_in();
    drv_set_color_map(tac_colormap, tac_colormap);
    KBD_FLAGS |= 0x20;
    /* INT 10h AX=0305h: typematic rate, BH=0 delay, BL=8 rate */
    tac_regs.h.ah = 3; tac_regs.h.al = 5;
    ((unsigned char *)&tac_regs)[3] = 0;
    ((unsigned char *)&tac_regs)[2] = 8;
    int86(0x10, &tac_regs, &tac_regs);
    do {
        update_current_room();
        wait_retrace(game_speed ? (game_speed == 1 ? 4 : 2) : 6);
        update_projectiles(0, 0);
        wait_retrace(game_speed ? (game_speed == 1 ? 4 : 2) : 6);
    } while (!mission_over);
    KBD_FLAGS &= ~0x20;
    mission_end_text();
    ENV[0] = (options & 0x20) ? 0x11 : 0;
    ENV[8] = result_score;
    ENV[9] = violence ? clamp(violence * 10 + 20, 0, guards_left * 10) : 0;
    ENV[10] = mission_flags;
    ENV[11] = wounds;
    ENV[13] = (mission_flags & 4) == 0;
    ENV[15] = frame_count / 60;
    env_flags = env_flags & 0xfcff | game_speed << 8;
    loc = set_location_known(cur_org, cur_city, 0);
    if (loc != -1)
        for (i = 0; i <= n_rooms; i++)
            if (rooms[i].flags & 2)
                sites[loc].rooms_seen |= 1L << i;
    save_env("env.sve");
    play_sound(0);
    set_exit_state(0, 0);
    drv_slot8(3);
    require_disk((options & 0x20) ? 1 : 2, 1L);
}

set_exit_state(flag)
int flag;
{
    KBD_FLAGS &= ~0x20;
    if (flag) ENV[0] = 0xFF;
}

play_sound(n)
int n;
{
    if (options & 4) drv_play_sound(n, sfx_tempo, sfx_variant);
}

bios_set_page(page)
int page;
{
    tac_regs.h.ah = 5; tac_regs.h.al = page;
    int86(0x10, &tac_regs, &tac_regs);
}

/* INT 10h AX=1010h: set one DAC register. */
set_dac_color(color, red, green, blue)
int color, red, green, blue;
{
    union {
        struct { unsigned ax, bx, cx, dx; } x;
        struct { unsigned char al, ah, bl, bh, cl, ch, dl, dh; } h;
        int pad[7];
    } regs;

    regs.h.ah = 0x10;
    regs.h.al = 0x10;
    regs.x.bx = color;
    regs.h.dh = red;
    regs.h.ch = green;
    regs.h.cl = blue;
    int86(0x10, &regs, &regs);
}

sign(n)
int n;
{
    if (n > 0) return 1;
    if (n < 0) return -1;
    return 0;
}

play_tune(n)
int n;
{
    drv_call_gate(tune_data[n]);
}

draw_status_bar()
{
}

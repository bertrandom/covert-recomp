/* FINAL.C - Covert Action end-of-case program (FINAL.EXE): entry point, the
 * game tables (initialized here, as in every Covert Action program), program
 * hooks and the intercept text for the cryptography practice.
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas.
 * (The INT 24h handler at the start of _TEXT, install_int24_handler and
 * restore_int24_handler, is an assembly module, not part of this file.) */
#include "final.h"

/* The game tables, saved in env.sve / the save files (gamelib.h) */
struct Person persons[64] = { 0 };
struct Site sites[256] = { 0 };
struct Clue clues[80] = { 0 };
int jailbreak_person = -1;

RastPort work_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *work_page = &work_rp;
RastPort back_rp = { 1, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *back_page = &back_rp;

/* color maps for drv_set_color_map (CGA) */
char start_colormap[] = { 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x00, 0x02, 0x00, 0x01, 0x03, 0x01, 0x02, 0x01, 0x00, 0x03 };
char start_colormap2[] = { 0x00, 0x01, 0x11, 0x11, 0x02, 0x00, 0x02, 0x03, 0x30, 0x11, 0x13, 0x31, 0x22, 0x23, 0x33, 0x33 };
char std_colormap[] = { 0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x00, 0x02, 0x00, 0x01, 0x02, 0x03, 0x02, 0x01, 0x01, 0x03 };
char std_colormap2[] = { 0x00, 0x00, 0x11, 0x11, 0x22, 0x00, 0x00, 0x22, 0x00, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33 };
char colormap_b2[] = { 0x00, 0x00, 0x11, 0x11, 0x22, 0x22, 0x22, 0x22, 0x00, 0x22, 0x33, 0x33, 0x00, 0x00, 0x11, 0x33 };
char colormap_c2[] = { 0x00, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x22, 0x22, 0x00, 0x00, 0x00, 0x11, 0x33 };
char story_colors[] = { 0x00, 0x12, 0x11, 0x10, 0x11, 0x00, 0x12, 0x33, 0x22, 0x13, 0x33, 0x11, 0x33, 0x22, 0x33, 0x33 };
char title_colors[] = { 0x00, 0x12, 0x00, 0x00, 0x22, 0x00, 0x00, 0x13, 0x02, 0x11, 0x00, 0x00, 0x00, 0x00, 0x33, 0x33 };
char tele_colors[] = { 0x00, 0x11, 0x11, 0x11, 0x22, 0x00, 0x22, 0x12, 0x00, 0x11, 0x11, 0x33, 0x33, 0x22, 0x33, 0x33 };
char colormap_02[] = { 0x00, 0x11, 0x11, 0x11, 0x22, 0x00, 0x22, 0x12, 0x00, 0x11, 0x11, 0x33, 0x33, 0x22, 0x33, 0x33 };
char face_colormap[] = { 0x00, 0x11, 0x11, 0x01, 0x22, 0x00, 0x22, 0x22, 0x00, 0x11, 0x11, 0x33, 0x33, 0x33, 0x33, 0x33 };
char dialog_colors[] = { 0x00, 0x00, 0x11, 0x11, 0x22, 0x00, 0x00, 0x11, 0x22, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33 };
unsigned char report_colormap[] = { 0x00, 0x00, 0x11, 0x11, 0x22, 0x00, 0x00, 0x22, 0x00, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33 };
char colormap_42[] = { 0x00, 0x00, 0x11, 0x11, 0x22, 0x00, 0x00, 0x33, 0x22, 0x22, 0x11, 0x33, 0x22, 0x33, 0x22, 0x33 };
char game_palette[] = { 0, 1, 2, 3, 4, 0, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0 };
int cur_disk = 1;
char title_pan[] = "animation.pan";

main()
{
    int saved, sel;

    link_driver_stubs(*(int far *)(ENV + 0x60));
    link_driver_stubs(*(int far *)(ENV + 0x62));
    link_driver_stubs(*(int far *)(ENV + 0x64));
    drv_slot36(0);
    g_gfx->font = 1;
    g_gfx->fillcolor = 8;
    drv_set_palette(game_palette);
    drv_set_color_map(start_colormap, start_colormap2);
    srand(rand_seed = time(0L) & 0x7fff);
    cur_face = -1;
    anim_enabled = 1;
    if (ENV[0] == 11) {
        start_mode = 1;
        is_cga = ((video_mode = ENV[2]) == 'C') ? 1 : 0;
    }
    if (ENV[0] == 17) {
        start_mode = -1;
        load_env("env.sve");
    }
    ENV[0] = 0xFF;
    options &= ~0x20;
    if (start_mode == 1) {
        options |= 0xC;
        if (ENV[3] == 'N')
            options &= ~4;
        if (ENV[4]) {
            drv_joy_calibrate();
            options |= 0x10;
            strcpy(text_buf, "Move JOYSTICK to\nupper-left corner\nand press button.\n");
            text_window(text_buf, 80, 91);
            flush_input();
            wait_retrace(60);
            strcpy(text_buf, "Move JOYSTICK to\nlower-right corner\nand press button.\n");
            text_window(text_buf, 80, 91);
            flush_input();
        }
    }
    if (start_mode == 1)
        load_picture_swapped("labs.pic", 0);
    init_face_parts();
    if (start_mode == 0) {
        load_env("env.sve");
        options |= 8;
        end_of_case();
resume:
        if (persons[0].fate == -1 || plot_num == 0)
brief:      plot_briefing();
    } else {
        if (start_mode == 1) {
            play_sound(2);
            drv_set_color_map(title_colors, title_colors);
            play_title_pan("title2.pan", 0, 0);
            if (drv_kbhit())
                play_title_pan("credits.pan", 0, 0);
        }
        for (;;) {
            g_gfx->fillcolor = 5;
            strcpy(text_buf, "Do you want to...\n Create a New Character\n Load a Saved Game\n Practice a skill\n Review Hall of Fame\n");
            sel = show_menu(text_buf, 80, 80);
            g_gfx->fillcolor = 5;
            play_sound(1);
            switch (sel) {
            case -1:
            case 0:
                create_new_character();
                goto brief;
            case 3:
                load_hall_of_fame();
                show_hall_of_fame(-1);
                continue;
            case 2:
                sel = practice_menu();
                if (sel == -1)
                    continue;
                start_practice(sel);
                goto play;
            case 1:
                saved = options;
                if (load_game_menu() == -1)
                    continue;
                options = saved & 0x10 | options & ~0x10;
                if (options & 0x40)
                    goto resume;
                ENV[0] = 0;
                ENV[1] = 1;
                ENV[7] = 0;
                ENV[15] = 0;
                save_env("env.sve");
                goto play;
            }
            break;
        }
    }
    case_intro_story();
    ENV[0] = 0;
    ENV[1] = 0;
    mission_ended = -1;
play:
    if (!ENV[1]) {
        generate_case();
        if (scene_vars[0] != 1) {
            difficulty = 0;
            sel = training_screen(1L);
            start_practice(sel == -1 ? 0 : sel);
        } else
            save_env("env.sve");
    }
    drv_set_palette(game_palette);
    if (ENV[0] == 13)
        require_disk(3, 1L);
    else
        require_disk(2, 1L);
    set_exit_state();
}

play_sound(n)
int n;
{
    if (options & 4) drv_play_sound(n);
}

play_title_pan(name, x, y)
char *name;
int x, y;
{
    int color;

    drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
    strcpy(title_pan, name);
    color = g_gfx->fillcolor;
    anim_play_file(title_pan, -1, x, y);
    g_gfx->fillcolor = color;
    drv_set_palette(game_palette);
    gfx_show_page(0);
}

start_practice(skill)
int skill;
{
    ENV[0] = skill + 13;
    ENV[1] = 1;
    options |= 0x20;
    skill_levels = 0x555;
    here_org = random(12) + 4;
    here_city = random(16);
    load_world_file(random(3));
    if (skill == 2)
        compose_intercept();
    save_env("env.sve");
}

bios_set_page(page)
int page;
{
    bios_regs.h.ah = 5; bios_regs.h.al = page;
    int86(0x10, &bios_regs, &bios_regs);
}

set_exit_state()
{
}

draw_status_bar()
{
}

compose_intercept()
{
    int bits, idx, kind;

    strcpy(subst_vals[1], orgs[random(12) + 4].name);
    strcpy(subst_vals[2], orgs[random(12) + 4].name);
    strcpy(subst_vals[3], cities[random(16)].name);
    strcpy(subst_vals[4], cities[random(16)].name);
    bits = 0;
    strcpy(text_buf, "");
    do {
        kind = random(5);
        if (!(bits & (1 << kind))) {
            bits |= 1 << kind;
            switch (kind) {
            case 0:
                lookup_random_text("text.dta", "*SLOC00", 8);
                break;
            case 1:
                lookup_random_text("text.dta", "*RLOC00", 8);
                break;
            case 2:
                lookup_random_text("text.dta", "*SORG00", 8);
                break;
            case 3:
                lookup_random_text("text.dta", "*RORG00", 8);
                break;
            case 4:
                lookup_random_text("text.dta", "*FLUF00", 12);
                break;
            }
        }
    } while (bits != 0x1f);
    for (idx = 0; idx < 0x200; idx++)
        ENV[idx + 0x200] = text_buf[idx];
}

draw_intercept_popup()
{
}

/* BREAKIN.C - Covert Action building infiltration (TAC.EXE): setting up the
 * break-in, tracking the current room, the frame loop, play view and weapons
 * (setup_break_in .. mark_guard_down, image 158E-3B90).
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas /Zd.
 *
 * A separate object from TAC.C, compiled with /Zd (TAC.C can't be: see there).
 * With /Zd MSC flushes a code record every 52 line-number entries (one per
 * source line that starts generating code), besides the usual flush at 0x3B0
 * bytes or 99 fixups, and LINK writes the relocations record by record, so the
 * line layout decides the EXE's relocation order. Several short statements are
 * therefore joined onto one line in tac_frame (the movement code after the key
 * switch, 28+5 joins), at the end of tac_frame / start of draw_play_view (7) and
 * in fire_gun / grenade_menu / update_projectiles (about 40), so the records
 * start at 158E 1868 1B1A 1D43 1FAC 2148 22AF 2662* 290F 2CBF* 2CC4 3074* 30C7
 * 3319 36CB* 37C1 3B72* (* = size break), each inside a window from
 * tools/rebuild/relocwin.py. Check with tools/rebuild/zdcmp.py. */
#include "mps.h"
#include "tac.h"

/* MS C runtime */
extern char *itoa();
extern char *strcpy();
extern char *strcat();

/* Equipment, then pick the door to come in by (or the room the mission starts
 * in), place Max and the guards. */
setup_break_in()
{
    int i, py;
    int num, px;
    int exits[8];

    if (tac_mode != 1 && tac_mode != 2 && tac_mode != 3)
        equipment_screen(1L);
    else {
        equipment = 0xc1;
        if (tac_mode == 2 || tac_mode == 3) {
            grenades[0] = 4;
            if (tac_mode == 2)
                equipment = 0xc2;
            else
                equipment &= ~0x80;
        }
        equipment_screen(0L);
        draw_equipment_panel();
    }
    drv_set_color_map(tac_colormap, tac_colormap);
    rooms[0].flags |= 2;
    draw_room(180, 100, 3);
    g_gfx->fillcolor = 1;
    max_x = 328;
    max_y = 264;
    if (tac_mode == 1 || tac_mode == 2 || tac_mode == 3) {
        cur_room = start_room;
        px = rooms[start_room].x + rooms[start_room].w / 2;
        py = rooms[start_room].y + rooms[start_room].h / 2;
        if (tac_mode == 3) {
            py = rooms[start_room].y + rooms[start_room].h - 1;
            goal_room = start_room;
        }
        if (tac_mode == 1) start_room = -1;
        max_dir = 1;
        building[px][py - (tac_mode == 3 ? 1 : 0)] = 14;
        if (tac_mode == 2)
            for (i = 0; i < n_doors; i++) {
                if (doors[i].room_a == start_room) rooms[doors[i].room_b].flags |= 2;
                if (doors[i].room_b == start_room) rooms[doors[i].room_a].flags |= 2;
            }
    } else {
        cur_room = -1;
        num = 0;
        for (i = 0; i < n_doors; i++) {
            if ((!doors[i].room_a && doors[i].room_b) || (!doors[i].room_b && doors[i].room_a)) {
                exits[num++] = i;
                strcpy(msg_buf, "");
                strcat(msg_buf, itoa(num, num_buf, 10));
                draw_text_transparent(msg_buf, doors[i].x * 3 + 180, doors[i].y * 3 + 98,
                                      mono_display ? 4 : 15);
            }
        }
        if (num > 1) {
            strcpy(msg_buf, "Which door?  \n ");
            for (i = 0; i < num; i++) {
                strcat(msg_buf, "Door #");
                strcat(msg_buf, itoa(i + 1, num_buf, 10));
                strcat(msg_buf, "\n ");
            }
            i = show_menu(msg_buf, 180, 64);
            if (i != -1)
                i = exits[i];
            else
                i = exits[0];
        } else
            i = exits[0];
        if (!doors[i].room_a && doors[i].room_b) {
            cur_room = doors[i].room_b;
            px = doors[i].x + door_dx[doors[i].dir];
            py = doors[i].y + door_dy[doors[i].dir];
            max_dir = doors[i].dir * 2 + 1;
        }
        if (!doors[i].room_b && doors[i].room_a) {
            cur_room = doors[i].room_a;
            px = doors[i].x;
            py = doors[i].y;
            max_dir = ((doors[i].dir + 2) & 3) * 2 + 1;
        }
        building[px][py] |= 0x80;
        if (target_person != -1) compute_room_distances(start_room, 0);
    }
    if (tac_mode == 2) compute_room_distances(start_room, 999);
    want_dir = max_dir;
    for (i = 0; i < 16; i++)
        projectiles[i].type = -1;
    for (i = 0; i <= 8; i++) {
        actor_x[i] = actor_y[i] = actor_map_x[i] = actor_map_y[i] = 0;
        guards[i].flags = 0;
    }
    spawn_guard(0);
    guards[0].flags |= 0x80;
    for (i = 1; i <= difficulty + 1; i++)
        if (tac_mode != 2) spawn_guard(i);
    for (i = 0; i < 24; i++)
        room_noise[i] = 0;
    max_x = px * 16 + 8;
    max_y = py * 16 + 8;
    room_alert = 0;
    cur_room = -1;
    if (tac_mode == 2 || tac_mode == 3) {
        last_seen_x = max_x / 16;
        last_seen_y = max_y / 16;
        if (tac_mode == 3) {
            compute_room_distances(1, 240);
            building[last_seen_x][last_seen_y] = 2;
        }
    }
}

/* Track the room Max is in; when he changes room, update alerts and the view.
 * Then run one frame: Max, the guards, the alarm, the status bar colors. */
int max_dir = 4;
int want_dir = 4;

update_current_room()
{
    int i, room;

    cell_x = max_x / 16;
    cell_y = max_y / 16;
    if (room_map[cell_x][cell_y] != cur_room) {
        if (cur_room != -1) {
            rooms[cur_room].flags &= ~8;
            for (i = 1; i < 8; i++)
                if (guards[i].flags && guards[i].stun > 999) {
                    guards[i].flags = 0;
                    rooms[cur_room].flags |= 8;
                }
            if (doors_open > 0 || room_alert) rooms[cur_room].flags |= 8;
        }
        doors_open = 0;
        cur_room = room_map[cell_x][cell_y];
        max_moved = 0;
        max_x = cell_x * 16 - step_dx[max_dir] + 8;
        max_y = cell_y * 16 - step_dy[max_dir] + 8;
        if (cur_room == 0) {
            mission_over = 1;
            drv_copy_rect(back_page, actor_x[0], actor_y[0], 15, 15, g_gfx, actor_x[0], actor_y[0]);
            return;
        }
        draw_room_objects(cur_room);
        rooms[cur_room].flags |= 2;
        draw_room(180, 100, 3);
        if (cur_room == start_room && target_person != -1 && !disguised)
            compute_room_distances(cur_room, 240);
        room_alert = rooms[cur_room].flags & 8;
    }
    tac_frame();
    if (mission_over) return;
    for (i = 1; i <= 8; i++)
        guard_think(i);
    draw_play_view();
    sfx_tempo = 1;
    if (!(char)frame_count) sfx_variant = random(3) + 1;
    if (alarm_timer <= 0) {
        if (last_at_goal) {
            if (disguised)
                sfx_tempo = 3;
            else
                sfx_tempo = 2;
        }
    } else {
        if (last_at_goal)
            sfx_tempo = 5;
        else
            sfx_tempo = 4;
    }
    play_sound(44);
    if (++frame_count > 7500) frame_count -= 256;
    draw_disguise_status();
    if (tune_on) {
        play_tune(0);
        tune_on = 0;
    }
    if (mission_flags & 2) disguised = 0;
    if (alarm_timer) {
        disguised = 0;
        if (--alarm_timer == 0) compute_room_distances(start_room, 0);
        if (!(frame_count & 15) && tac_mode != 3) {
            play_tune(2);
            tune_on = 1;
            if (alarm_timer > 200) {
                play_sound(18);
                alarm_heard = 1;
            }
        }
    }
    if (!(frame_count & 31)) {
        KBD_FLAGS |= 0x20;
        i = random(24);
        if (rooms[i].flags & 0x10) {
            rooms[i].flags &= ~0x10;
            draw_room(180, 100, 3);
        }
    }
    if (last_disguised != disguised && !mono_display) {
        last_disguised = disguised;
        if (disguised)
            drv_recolor_rect(display_page, 0, 160, 320, 40, 13, alarm_color);
        else
            drv_recolor_rect(display_page, 0, 160, 320, 40, alarm_color, 13);
    }
    if (((unsigned char)rooms[cur_room].flags & 0x10) != last_dark) {
        last_dark = rooms[cur_room].flags & 0x10;
        if (last_dark)
            drv_recolor_rect(display_page, 0, 160, 320, 40, 9, 12);
        else
            drv_recolor_rect(display_page, 0, 160, 320, 40, 12, 9);
    }
}

/* ---- formerly FRAME.C: the frame loop, play view, weapons (same object) ---- */

extern int far gate_thunk_b();

/* Initialized data: held back until the end of tac_frame, so it comes after
 * tac_frame's literals and before grenade_menu's. */
int joy_dir_keys[9] = { 0, 0x48, 0x49, 0x4d, 0x51, 0x50, 0x4f, 0x4b, 0x47 };
int flash_active = 0;
char hit_colors[5] = { 0, 8, 3, 7, 15 };

tac_frame()
{
    int doorway;
    int mx;
    int jdx;
    int my;
    int jdy;
    int i;
    int ahead_x;
    int obj;
    int spare;
    int joykey;
    int code;
    int ahead_y;

    if (((equipment & 0x40) ? 3 : 1) < wounds)
        mission_over = 1;
    if ((rooms[cur_room].flags & 0x10) && !(equipment & 0x20))
        guards[0].stun += 2;
    if (guards[0].stun && --guards[0].stun > 0x40) {
        guards[0].spotted = 0;
        guards[0].flags |= 4;
        sneaking = 1;
        while (!drv_kbhit())
            get_key();
        if (guards[0].stun > 0x100)
            mission_over = 1;
        return;
    }
    made_noise = 0;
    if (ammo == 0 && clips) {
        ammo = 6;
        clips--;
        draw_equipment_panel();
    }
    joykey = -1;
    if ((options & 0x10) && drv_kbhit()) {
        joykey = read_joystick(&jdx, &jdy);
        if (joystick_button(0)) {
            if (guard_in_room)
                joykey = 0x20;
            else {
                joykey = 0x3B00;
                flush_input();
            }
        }
        if (joystick_button(1)) {
            if (joykey == -1)
                joykey = 0x35;
            else
                joykey = joy_dir_keys[joykey] + 0x80;
            flush_input();
        }
    }
    if (!(drv_kbhit() && joykey == -1) && !dive_count && !throw_delay) {
        if (joykey == -1) {
            code = get_key();
            if (code != last_key)
                key_repeat = 4;
            else
                key_repeat = 0;
        } else
            code = joykey;
        switch (last_key = code) {
        case 'f':
            game_speed = 2;
            break;
        case 'd':
            game_speed = 1;
            break;
        case 's':
            game_speed = 0;
            break;
        case ' ':
            if (cur_room == start_room && target_person != -1 && !(mission_flags & 2))
                made_noise = 1;
            if (fire_timer < 4 && (joykey == -1 || fire_timer == 0))
                fire_timer += 4;
            if (player_mode != 3)
                player_mode = 0;
            break;
        case '5':
            player_mode = 0;
            sneaking ^= 1;
            guards[0].flags &= ~4;
            guards[0].flags |= sneaking << 2;
            break;
        case '\r':
        case 0x3B00:
            if (tac_mode != 3) {
                examine_object();
                player_mode = 2;
                sneaking = 0;
            }
            break;
        case 0x3C00:
            made_noise = 1;
            if (equipment & 4)
                take_photo();
            break;
        case 0x3D00:
            made_noise = 1;
            plant_bug();
            break;
        case 0x3E00:
            made_noise = 1;
            use_object();
            break;
        case 0x3F00:
            made_noise = 1;
            if (grenades[cur_grenade]-- > 0) {
                grenade_menu(max_x, max_y, max_dir, 1, cur_grenade);
                throw_delay = 3;
            }
            break;
        case 0x4000:
            made_noise = 1;
            if (grenades[cur_grenade]-- > 0) {
                grenade_menu(max_x, max_y, max_dir, 2, cur_grenade);
                throw_delay = 3;
            }
            break;
        case 0x4100:
            made_noise = 1;
            if (grenades[cur_grenade]-- > 0) {
                grenade_menu(max_x, max_y, max_dir, 3, cur_grenade);
                throw_delay = 3;
            }
            break;
        case 0x4200:
            for (i = 0; i < 16; i++)
                if (projectiles[i].timer == -9999)
                    projectiles[i].timer = -63;
            break;
        case 0x4300:
            made_noise = 1;
            if (grenades[cur_grenade] > 0)
                grenade_menu(max_x, max_y, max_dir, -1, cur_grenade);
            break;
        case 0x4400:
            cur_grenade++;
            if (cur_grenade > 2)
                cur_grenade = 0;
            draw_equipment_panel();
            break;
        case 0x1F00:
            if (options & 4)
                play_sound(0);
            options ^= 4;
            break;
        case 0x1900:
            present_back_buffer();
            play_sound(0x25);
            message_shown = 1;
            show_menu("PAUSED\n", 0x50, 0x60);
            wait_key_or_button();
            play_sound(0x26);
            save_to_back_buffer();
            break;
        case 0x1000:
            present_back_buffer();
            if (show_menu("Are you sure\nyou want to Quit?\n No\n Yes\n", 0x50, 0x50) == 1) {
                set_exit_state(1L);
                exit();
            }
            save_to_back_buffer();
            break;
        case 0x2400:
            options ^= 0x10;
            if (options & 0x10)
                drv_joy_calibrate();
            break;
        case 0:
            player_mode = 0;
            want_dir = max_dir;
            break;
        case 8:
        case '7':
        case 0x4737:
            want_dir = 8;
            player_mode = 1;
            break;
        case 1:
        case '8':
        case 0x4838:
            player_mode = 1;
            want_dir = 1;
            break;
        case 2:
        case '9':
        case 0x4939:
            want_dir = 2;
            player_mode = 1;
            break;
        case 7:
        case '4':
        case 0x4B34:
            want_dir = 7;
            player_mode = 1;
            break;
        case 3:
        case '6':
        case 0x4D36:
            want_dir = 3;
            player_mode = 1;
            break;
        case 6:
        case '1':
        case 0x4F31:
            want_dir = 6;
            player_mode = 1;
            break;
        case 5:
        case '2':
        case 0x5032:
            want_dir = 5;
            player_mode = 1;
            break;
        case 4:
        case '3':
        case 0x5133:
            want_dir = 4;
            player_mode = 1;
            break;
        case 0xC7:
        case 0x4700:
            want_dir = 8;
            player_mode = 4;
            break;
        case 0xC8:
        case 0x4800:
            player_mode = 4;
            want_dir = 1;
            break;
        case 0xC9:
        case 0x4900:
            want_dir = 2;
            player_mode = 4;
            break;
        case 0xCB:
        case 0x4B00:
            want_dir = 7;
            player_mode = 4;
            break;
        case 0xCD:
        case 0x4D00:
            want_dir = 3;
            player_mode = 4;
            break;
        case 0xCF:
        case 0x4F00:
            want_dir = 6;
            player_mode = 4;
            break;
        case 0xD0:
        case 0x5000:
            want_dir = 5;
            player_mode = 4;
            break;
        case 0xD1:
        case 0x5100:
            want_dir = 4;
            player_mode = 4;
            break;
        }
        if (tac_mode == 1 && (player_mode == 1 || player_mode == 4)) {
            compute_room_distances(cur_room, 0xF0);
            tac_mode = 0;
        }
        if (player_mode == 4) {
            made_noise = 1;
            dive_count = 0;
            for (i = 3; i <= 9; i++) {
                mx = (step_dx[want_dir] * i + max_x) / 16; my = (step_dy[want_dir] * i + max_y) / 16;
                if (room_map[mx][my] != cur_room) { dive_count = i / 2 + 4; break; }
                obj = building[mx][my];
                if (obj != -1) {
                    obj &= 0x3F;
                    if (obj_types[obj].flags & 0x20) break;
                    if (!(obj_types[obj].flags & 1)) {
                        dive_count = i / 2 + 6;
                        max_dir = want_dir;
                    }
                } else {
                    dive_count = i / 2 + 6; max_dir = want_dir;
                }
            }
            if (dive_count == 0) player_mode = 0;
            else sneaking = 1;
        }
    } else last_key = -1;
    key_repeat--;
    if (!(options & 0x10) || !joystick_button(0)) flush_input();
    if (want_dir != max_dir) {
        if (((want_dir - max_dir) & 7) < 4) max_dir++;
        else max_dir--;
        max_dir = ((max_dir - 1) & 7) + 1;
    }
    if (player_mode == 1) {
        ahead_x = (step_dx[max_dir] * 2 + max_x) / 16; ahead_y = (step_dy[max_dir] * 2 + max_y) / 16;
        doorway = ((building[cell_x][cell_y] & 0x80) &&
                   (obj_types[building[cell_x][cell_y] & 0x3F].flags & 0x10)) ? 1 : 0;
        if (!doorway && ((max_x < room_left + 8 && step_dx[max_dir] < 0) ||
                         (max_x > room_right - 8 && step_dx[max_dir] > 0))) player_mode = 0;
        if (ahead_x != cell_x && (obj = building[ahead_x][cell_y] & 0x3F) != 0x3F &&
            (obj_types[obj].flags & 1)) player_mode = 0;
        if (!doorway && ((max_y < room_top + 8 && step_dy[max_dir] < 0) ||
                         (max_y > room_bottom - 8 && step_dy[max_dir] > 0))) player_mode = 0;
        if (ahead_y != cell_y && (obj = building[cell_x][ahead_y] & 0x3F) != 0x3F &&
            (obj_types[obj].flags & 1)) player_mode = 0;
        if (ahead_x != cell_x && ahead_y != cell_y && (obj = building[ahead_x][ahead_y] & 0x3F) != 0x3F &&
            (obj_types[obj].flags & 1)) player_mode = 0;
    }
    player_moving = 0;
    switch (player_mode) {
    case 4:
        if (dive_count > 6) {
            max_x += step_dx[max_dir] * 2; max_y += step_dy[max_dir] * 2;
        }
        if (--dive_count == 0) player_mode = 0;
        break;
    case 1:
        player_moving = 1;
        if (want_dir == max_dir) {
            if (!sneaking || dive_count) {
                max_x += step_dx[max_dir]; max_y += step_dy[max_dir];
            } else {
                max_x += dir_dx[max_dir]; max_y += dir_dy[max_dir]; sneak_steps++;
            }
            if (key_repeat <= 0 && dive_count == 0) player_mode = 0;
        }
        player_anim = ++player_anim & 3; break;
    case 2:
        player_anim = 6; break;
    case 3:
        player_anim = 7; break;
    default:
        player_anim = 0;
        if (max_heard && tac_mode != 1 && disguised == 0) player_anim = 4;
        break;
    }
    if (sneaking) player_anim = 7;
    guards[0].x = max_x; guards[0].y = max_y; guards[0].dir = max_dir;
    guards[0].firing = fire_timer; guards[0].mode = player_mode; guards[0].anim = player_anim;
    guards[0].room = cur_room; guards[0].flags &= ~4; guards[0].flags += sneaking * 4;
    if (fire_timer) fire_timer--;
    if ((i = frame_count % 8 + 1) != 0 && (guards[i].flags & 0x80)) {
        if (abs(max_x - guards[i].x) + abs(max_y - guards[i].y) < 10 &&
            (guards[i].stun > 0x18 || disguised == 0)) {
            if (disguised == 0 && guards[i].stun == 0)
                wounds++;
            if (guards[i].stun > 999 && --room_alert == 0) rooms[cur_room].flags &= ~8;
            guards[i].flags = guards[i].stun = 0;
            disguised = 1;
            i = random(3);
            grenades[i] = clamp(grenades[i] + 2, 2, 8);
            draw_equipment_panel();
        }
    }
    if (frame_count > 64 && (tac_mode == 3 || tac_mode == 2) &&
        (!guards_near || frame_count > 3600)) {
        cur_room = 0; mission_over = 1;
    }
}

draw_play_view()
{
    int k;
    int img;
    int range;
    int who;
    int fall;
    int len;

    who = 0;
    do {
        if (actor_x[who] != -1)
            drv_copy_rect(back_page, actor_x[who], actor_y[who], 15, 15, g_gfx, actor_x[who], actor_y[who]);
    } while (++who <= 8);
    if (flash_active) drv_copy_rect(back_page, flash_x, flash_y, 15, 15, g_gfx, flash_x, flash_y);
    flash_active = 0;
    for (k = 9; k >= 0; k--) {
        if ((who = k) == 9) who = 0;
        if (guards[who].room == cur_room && (guards[who].flags & 0x80)) {
            actor_x[who] = guards[who].x - rooms[cur_room].x * 16 + view_x0 - 8;
            actor_y[who] = guards[who].y - rooms[cur_room].y * 16 + view_y0 - 8;
            if (k == 9) {
                if (guards[who].firing == 0 && ((equipment & 0x40) ? 3 : 1) >= wounds &&
                    throw_delay == 0) {
                    img = guards[who].anim;
                    if (guards[who].spotted) img = 4;
                    if (guards[who].flags & 4) img = 7;
                    erase_actor_sprite(((sneaking & sneak_steps & 1) ? 9 : 0) + guards[who].dir * 20 +
                                       img - 20, actor_x[who], actor_y[who]);
                }
                continue;
            } else {
                if (guards[who].firing == 0) {
                    img = guards[who].anim;
                    if (guards[who].spotted)
                        img = 4;
                    if (guards[who].flags & 4)
                        img = 7;
                } else {
                    if (who == 0)
                        sneak_steps = 0;
                    img = ((guards[who].firing-- & 2) == 2) ? 4 : 5;
                    if ((guards[who].firing & 3) == 1) {
                        if (!flash_active && !(guards[who].flags & 2) && guards[who].stun < 99) {
                            flash_who = who; flash_active = 1;
                            flash_x = 6 * dir_dx[guards[who].dir] + actor_x[who];
                            flash_y = 6 * dir_dy[guards[who].dir] + actor_y[who];
                            if (flash_who != 0 || ammo != 0)
                                erase_actor_sprite(guards[who].dir * 20 - 6, flash_x, flash_y);
                            if (flash_who == 0 && ammo == 0)
                                play_sound(5);
                        } else
                            guards[who].firing++;
                    }
                }
                if (who == 0) {
                    if (throw_delay == 0)
                        drv_copy_rect(display_page,
                                      (((player_moving || img) ? img : 9) +
                                       (sneaking & sneak_steps & 1)) * 24,
                                      160, 25, 40, g_gfx, 0, 0);
                    else {
                        drv_copy_rect(display_page, (13 - throw_delay) * 24, 160, 25, 40, g_gfx, 0, 0);
                        img = 19 - --throw_delay;
                        sneak_steps = 0;
                    }
                    fire_gun(0, 0L);
                    if (guards[0].stun >= 0x42 || (dive_count && dive_count < 6)) {
                        len = clamp((guards[0].stun - 0x40) / 2, dive_count, 0x26);
                        gfx_fill_rect(g_gfx, 1, 0x27 - len, 0x17, len, 7);
                    }
                    if (flash_active && flash_who == 0 && ammo)
                        erase_actor_sprite(0x36, 10, 1);
                }
                if (who == 0 && ((equipment & 0x40) ? 3 : 1) < wounds)
                    erase_actor_sprite(0xA6, actor_x[who], actor_y[who]);
                else if (who != 0 && guards[who].stun > 0x20)
                    erase_actor_sprite(((dir_dy[guards[who].dir] == -1) ? 4 : 5) + 0xA0,
                                       actor_x[who], actor_y[who]);
                else if (!(guards[who].flags & 8))
                    erase_actor_sprite((who ? 8 : ((sneaking & sneak_steps & 1) ? 9 : 0)) +
                                       guards[who].dir * 20 + img - 20, actor_x[who], actor_y[who]);
            }
        } else
            actor_x[who] = -1;
    }
    for (who = 8; who >= 0; who--) {
        if ((guards[who].flags & 0x80) && guards[who].stun < 999) {
            drv_copy_rect(back_page, actor_map_x[who], actor_map_y[who], 2, 2, g_gfx, actor_map_x[who], actor_map_y[who]);
            actor_map_x[who] = 3 * guards[who].x / 16 + 180;
            actor_map_y[who] = 3 * guards[who].y / 16 + 100;
            if (who) {
                range = approx_distance(guards[who].x - max_x, guards[who].y - max_y);
                if ((((equipment & 0x80) ? 0x100 : 0x60) > range ||
                     (rooms[guards[who].room].flags & 4) || tac_mode == 2) &&
                    (!(guards[who].flags & 8) || !difficulty))
                    fill_rect_xy(actor_map_x[who], actor_map_y[who], actor_map_x[who] + 1, actor_map_y[who] + 1,
                                 (mono_display & frame_count & 1) ? 0 : alarm_color);
            } else if ((frame_count & 1) || who)
                fill_rect_xy(actor_map_x[who], actor_map_y[who], actor_map_x[who] + 1, actor_map_y[who] + 1, 0);
        }
    }
    for (who = 8; who >= 0; who--) {
        if (guards[who].room == cur_room && (guards[who].flags & 0x80) && (guards[who].flags & 2)) {
            guards[who].flags &= ~2;
            if (guards[who].firing == 0) {
                img = guards[who].anim;
                if (guards[who].flags & 4)
                    guards[who].anim = 7;
            } else
                img = (((guards[who].firing + 1) & 2) == 2) ? 4 : 5;
            for (fall = 0; fall < 4; fall++) {
                drv_copy_rect(back_page, actor_x[who], actor_y[who], 15, 15, g_gfx, actor_x[who], actor_y[who]);
                erase_actor_sprite(fall + 0xA0, actor_x[who], actor_y[who]);
                erase_actor_sprite(guards[who].dir * 20 + (who ? 8 : 0) + img - 20, actor_x[who], actor_y[who]);
                wait_retrace(2);
            }
            if (who) {
                mark_guard_down(who);
                actor_x[who] = actor_y[who] = 0;
            } else {
                wounds++;
                draw_equipment_panel();
            }
        }
    }
    update_projectiles(1L);
    if (flash_active)
        fire_gun(flash_who, 1L);
}

fire_gun(who, flag)
int who, flag;
{
    int r;
    int nearest;
    int hitwho;
    int hit;
    int angle;
    int i;
    int dx;
    int dy;
    int color;

    if (who) {
        hitwho = 0;
        if (!guard_can_see_max(who))
            hitwho = -1;
    } else {
        if (ammo == 0)
            return;
        if (flag) {
            ammo--;
            draw_equipment_panel();
            made_noise = 1;
        }
        hitwho = -1;
        nearest = 9999;
        for (i = 1; i <= 8; i++) {
            if (!(guards[i].flags & 0x80) || guards[i].room != cur_room || guards[i].stun > 999)
                continue;
            dx = guards[i].x - max_x;
            dy = guards[i].y - max_y;
            angle = direction8(dx, dy);
            if (angle != max_dir && ((max_dir - 2) & 7) + 1 != angle)
                continue;
            if (guard_can_see_max(i)) {
                r = approx_distance(dx, dy);
                if (r < nearest) {
                    hitwho = i;
                    nearest = r;
                }
            }
        }
    }
    hit = 0;
    if (hitwho != -1) {
        r = approx_distance(guards[who].x - guards[hitwho].x, guards[who].y - guards[hitwho].y);
        if (hitwho == 0) {
            violence++;
            compute_room_distances(cur_room, 0xF0);
            hit = guards[who].spotted / (5 - difficulty);
            if (player_mode != 1)
                hit++;
            if (difficulty == 0)
                hit = 1;
        } else {
            hit = guards[hitwho].heard / 2;
            if (equipment & 2)
                hit++;
            if (flag)
                guards[hitwho].heard = 0;
        }
        hit += 1 - r / 48;
        if (flag) {
            if (hitwho == 0)
                guards[who].spotted = 0;
            if (random(4) < hit) {
                guards[hitwho].flags |= 2;
                play_sound(hitwho == 0 ? 3 : (equipment & 2) ? 6 : 4);
            } else {
                play_sound(hitwho == 0 ? 0x21 : (equipment & 2) ? 6 : 0x22);
                compute_room_distances(cur_room, 0xF0);
                last_seen_x = max_x / 16; last_seen_y = max_y / 16;
            }
        }
    } else if (flag) play_sound(0x22);
    if (flag) { play_tune(3); wait_retrace(1); play_tune(0); }
    else if (hit) {
        color = hit_colors[clamp(hit, 0, 4)];
        gate_thunk_b(g_gfx, 4, 1, hit_flash_image); drv_recolor_rect(g_gfx, 4, 1, 16, 16, 1, color);
    }
}

grenade_menu(x, y, dir, fuse, type)
int x, y, dir, fuse, type;
{
    int slot;
    int d;
    int choice;

    for (slot = 0; slot < 16; slot++) {
        if (projectiles[slot].type == -1) {
            if (!(type & 0x80) && fuse != -1) { d = ((dir + 2) & 7) + 1; x += step_dx[d]; y += step_dy[d]; }
            projectiles[slot].x = x; projectiles[slot].y = y;
            projectiles[slot].dir = dir; projectiles[slot].type = type;
            if (fuse != -1) { projectiles[slot].timer = fuse * 10; play_sound(0xC); }
            else {
                present_back_buffer(); KBD_FLAGS &= ~0x20; strcpy(msg_buf, "Set trap\n Cancel\n Remote Control\n Booby Trap\n");
                choice = show_menu(msg_buf, 0x1E, 0x32); KBD_FLAGS |= 0x20; if (choice > 0) { play_sound(0xB); grenades[type]--; }
                switch (choice) {
                case 0:
                    projectiles[slot].type = -1;
                    break;
                case 1:
                    projectiles[slot].timer = -9999; break;
                case 2:
                    projectiles[slot].timer = -9998; break;
                }
                save_to_back_buffer(); if (choice == 1 || choice == 2) draw_room(0xB4, 100, 3);
            }
            break;
        }
    }
    if (!(type & 0x80)) draw_equipment_panel();
}

update_projectiles(active)
int active;
{
    int r;                          /* distance to a guard */
    int new_y, newx;
    int type;
    int in_room;
    int pass;
    int g;
    int px;
    int i;
    int py;
    int cx, cy;
    int shown;
    int cover;

    for (i = 0; i < 16; i++)
        if (projectiles[i].type != -1) {
            px = projectiles[i].x - rooms[cur_room].x * 16 + view_x0;
            py = projectiles[i].y - rooms[cur_room].y * 16 + view_y0;
            type = projectiles[i].type & 0x7F;
            in_room = room_map[projectiles[i].x / 16][projectiles[i].y / 16];
            shown = in_room == cur_room && projectiles[i].timer >= -63;
            if (throw_delay && !(projectiles[i].type & 0x80)) shown = 0;
            if (projectiles[i].timer < 0 && projectiles[i].timer > -9998 && active) {
                do {
                    if (shown) {
                        erase_actor_sprite((projectiles[i].timer & 7) + 0xA8, px - 8, py - 8);
                        if (type == 0) erase_actor_sprite((projectiles[i].timer & 3) + 0xA0, px - 8, py - 8);
                        if (type == 2 || projectiles[i].timer == -63) { play_tune(2); play_tune(1); tune_on = 1; }
                    }
                    if (projectiles[i].timer == -63) {
                        projectiles[i].timer = projectiles[i].type == 1 ? -16 : -8; draw_room(180, 100, 3);
                        if (type != 1) play_sound(in_room == cur_room ? 7 : 8);
                        if (type != 1 && !(projectiles[i].type & 0x80)) { compute_room_distances(in_room, 240); violence++; }
                        if (in_room != cur_room) { play_tune(4); play_tune(1); tune_on = 1; }
                        for (g = 0; g <= 8; g++)
                            if (guards[g].room == in_room && (guards[g].flags & 0x80)) {
                                r = approx_distance(guards[g].x - projectiles[i].x,
                                                       guards[g].y - projectiles[i].y);
                                if (g) r = r * (difficulty + 2) / 4; else r = (r << 2) / (difficulty + 2);
                                cover = (guards[g].flags & 4) ? 2 : 1;
                                cover += 2 - line_of_sight(projectiles[i].x, projectiles[i].y,
                                                           guards[g].x, guards[g].y);
                                if (type == 0 && 40 / cover > r) {
                                    if (g) mark_guard_down(g);
                                    else {
                                        wounds++; draw_equipment_panel();
                                    }
                                }
                                if (type == 2) guards[g].stun = clamp(guards[g].stun, (160 - r) / cover, 999);
                            }
                    }
                    if (++projectiles[i].timer == 0) {
                        if (shown)
                            drv_copy_rect(back_page, px - 8, py - 8, 15, 15, g_gfx, px - 8, py - 8);
                        if (type == 1) {
                            rooms[in_room].flags |= 0x10;
                            draw_room(180, 100, 3);
                        }
                        projectiles[i].type = -1;
                    }
                } while (projectiles[i].type == 2 && projectiles[i].timer > -63);
            }
            if (projectiles[i].timer > 0) {
                if (shown)
                    drv_copy_rect(back_page, px, py, 1, 1, g_gfx, px, py);
                px = projectiles[i].x * 3 / 16 + 180;
                py = projectiles[i].y * 3 / 16 + 100;
                drv_copy_rect(back_page, px, py, 1, 1, g_gfx, px, py);
                newx = step_dx[projectiles[i].dir] + projectiles[i].x;
                new_y = step_dy[projectiles[i].dir] + projectiles[i].y;
                cx = newx / 16;
                cy = new_y / 16;
                pass = (building[cx][cy] & 0x80) && (obj_types[building[cx][cy] & 0x3F].flags & 0x10);
                if (room_map[cx][cy] != in_room && !pass) {
                    projectiles[i].timer = 1;
                    projectiles[i].x -= step_dx[projectiles[i].dir] * 2;
                    projectiles[i].y -= step_dy[projectiles[i].dir] * 2;
                } else {
                    projectiles[i].x = newx;
                    projectiles[i].y = new_y;
                }
                if (shown) {
                    px = projectiles[i].x - rooms[cur_room].x * 16 + view_x0;
                    py = projectiles[i].y - rooms[cur_room].y * 16 + view_y0;
                    put_pixel(px, py, 10);
                }
                px = projectiles[i].x * 3 / 16 + 180;
                py = projectiles[i].y * 3 / 16 + 100;
                put_pixel(px, py, 10);
                if (--projectiles[i].timer == 0)
                    projectiles[i].timer = -63;
            }
        }
}

put_pixel(x, y, color)
int x, y, color;
{
    draw_line(x, y, x, y, color);
}

mark_guard_down(g)
int g;
{
    int sx, sy;

    sx = guards[g].x * 3 / 16 + 180;
    sy = guards[g].y * 3 / 16 + 100;
    drv_copy_rect(back_page, sx, sy, 2, 2, g_gfx, sx, sy);
    room_alert++;
    rooms[guards[g].room].flags |= 8;
    violence++;
    guards[g].stun = 9999;
}

/* ACTION.C - TAC.EXE: examining, photographing and bugging objects, the status
 * line, mission end messages, searching files, the computer terminal (password,
 * search, line input, found person) and the back buffer.
 * Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style. */
#include "mps.h"
#include "tac.h"

extern char *strcpy();
extern char *strcat();
extern char *format_clock_hms();
extern char *fopen();
extern char *strupr();
extern char *strstr();

/* Assembly segment (far) */
extern int far drv_kbhit();
extern int far gate_thunk_b();      /* draw an image: (port, x, y, image) */

examine_object()
{
    int unused, spare;              /* never used */
    int reply;
    int tile;

    object_in_front();
    strcpy(msg_buf, "");
    tile = building[front_x][front_y];
    if (tile != -1) {
        tile &= 0x3F;
        if (tile == 60) {
            if (mission_flags & 1)
                return;
            mission_flags |= 1;
            if (target_person != -1)
                persons[target_person].found |= persons[target_person].clues;
            building[front_x][front_y] = -1;
        }
        if (tile == 61) {
            if (tac_mode == 2)
                return;
            compute_room_distances(cur_room, 240);
            if (mission_flags & 2)
                return;
            present_back_buffer();
            KBD_FLAGS &= ~0x20;
            play_tune(0);
            if (target_person != -1) {
                persons[target_person].known |= 1;
                suspect_dossier(target_person, 0, 0);
            }
            strcpy(msg_buf, "Do you want to\narrest ");
            append_person_name(target_person);
            strcat(msg_buf, "?\n Yes\n No\n");
            reply = show_menu(msg_buf, 100, 140);
            KBD_FLAGS |= 0x20;
            drv_set_color_map(tac_colormap, tac_colormap);
            save_to_back_buffer();
            if (reply)
                return;
            mission_flags |= 2;
            msg_buf[0] = 0;
        }
        tile &= 0x3F;
        strcpy(msg_buf, obj_types[tile].name);
        if (obj_types[building[front_x][front_y] & 0x3F].flags & 4)
            strcat(msg_buf, " ... bug");
        if (obj_types[building[front_x][front_y] & 0x3F].flags & 8)
            strcat(msg_buf, " ... photo");
        if ((obj_types[building[front_x][front_y] & 0x3F].flags & 0x200)
            && !(building[front_x][front_y] & 0x40)) {
            building[front_x][front_y] |= 0x40;
            reveal_password_letter();
        }
        if (obj_types[tile].flags & 2) {
            if (((tile & 0xFD) != 0x1D && tile != 0x1C) || (equipment & 0x10)) {
                if (building[front_x][front_y] & 0x80) {
                    strcpy(msg_buf, obj_types[tile].name);
                    strcat(msg_buf, " closed.");
                    doors_open--;
                    play_sound((obj_types[tile & 0x3F].flags & 0x10) ? 14 : 17);
                } else {
                    doors_open++;
                    play_sound((obj_types[tile & 0x3F].flags & 0x10) ? 13 : 16);
                }
                building[front_x][front_y] ^= 0x80;
                reveal_rooms(front_x, front_y);
            }
        }
    }
    show_status_line(msg_buf);
}

object_in_front()
{
    int x, y;
    int tile;

    x = (step_dx[max_dir] * 3 + max_x) / 16;
    y = (step_dy[max_dir] * 3 + max_y) / 16;
    tile = building[x][y];
    if (tile != -1 && (tile & 0x3F) > 7
        && x >= rooms[cur_room].x && x < rooms[cur_room].x + rooms[cur_room].w
        && y >= rooms[cur_room].y && y < rooms[cur_room].y + rooms[cur_room].h) {
        front_x = x;
        front_y = y;
    } else {
        front_x = cell_x;
        front_y = cell_y;
    }
}

take_photo()
{
    int saved;
    int worth;
    int ok;
    int tile;

    object_in_front();
    tile = building[front_x][front_y];
    ok = 0;
    strcpy(msg_buf, "Nothing to photograph.");
    if (tile != -1 && (obj_types[tile & 0x3F].flags & 8)) {
        if (tile & 0x40)
            strcpy(msg_buf, "Already photographed.");
        else if ((tile & 0x80) || !(obj_types[tile & 0x3F].flags & 2)) {
            strcpy(msg_buf, obj_types[tile & 0x3F].name);
            strcat(msg_buf, " photographed.");
            building[front_x][front_y] |= 0x40;
            ok = 1;
        } else {
            strcpy(msg_buf, "Open ");
            strcat(msg_buf, obj_types[tile & 0x3F].name);
            strcat(msg_buf, " first.");
        }
    }
    if (photos_taken >= 36) {
        ok = 0;
        strcpy(msg_buf, "Out of film.");
    }
    show_status_line(msg_buf);
    if (ok) {
        photos_taken++;
        photo_score += room_types[rooms[cur_room].type].value;
        draw_film_count();
        play_tune(1);
        play_sound(9);
        wait_retrace(5);
        play_tune(0);
        tile &= 0x3F;
        if (tile >= 24)
            worth = 2;
        if (tile >= 29)
            worth = 3;
        if (tile >= 32)
            worth = 2;
        if (tile == 28)
            worth = 4;
        if (real_mission && !(options & 0x20)) {
            popup_x = (front_x - rooms[cur_room].x) * 16 + view_x0;
            popup_y = (front_y - rooms[cur_room].y) * 16 + view_y0;
            saved = difficulty;
            difficulty = orig_difficulty;
            present_back_buffer();
            if (worth != 4)
                describe_new_info(cur_org, cur_city,
                                  room_types[rooms[cur_room].type].value * worth, worth);
            else
                search_files();
            drv_set_color_map(tac_colormap, tac_colormap);
            save_to_back_buffer();
            g_gfx->fillcolor = 1;
            if (worth == 4) {
                draw_room(180, 100, 3);
                draw_equipment_panel();
            }
            difficulty = saved;
        }
    }
}

plant_bug()
{
    int t;

    object_in_front();
    t = building[front_x][front_y];
    if (!bugs_left)
        return;
    if (t != -1 && (obj_types[t & 0x3F].flags & 4) && !(rooms[cur_room].flags & 4)) {
        bugs_planted++;
        play_sound(10);
        bug_score += room_types[rooms[cur_room].type].value;
        rooms[cur_room].flags |= 4;
        bugs_left--;
        redraw_equipment_panel();
        strcpy(msg_buf, "");
        strcat(msg_buf, obj_types[t & 0x3F].name);
        strcat(msg_buf, " bugged.");
    } else
        strcpy(msg_buf, (rooms[cur_room].flags & 4) ? "Room already bugged." : "Nothing to bug.");
    show_status_line(msg_buf);
}

use_object()
{
    int t;

    object_in_front();
    t = building[front_x][front_y];
    if (t != -1 && (obj_types[t & 0x3F].flags & 0x200))
        computer_terminal();
}

draw_disguise_status()
{
    fill_rect_xy(123, 2, 168, 9, 1);
    if (frame_count & 4) {
        if (rooms[cur_room].flags & 0x10)
            draw_text_transparent("GAS", 132, 2, 12);
        else
            draw_text_transparent(format_clock_hms(frame_count), 124, 2, 15);
    } else if (disguised)
        draw_text_transparent("Disguise", 124, 2, 2);
    else
        draw_text_transparent(format_clock_hms(frame_count), 124, 2, 15);
}

show_status_line(s)
char *s;
{
    fill_rect_xy(27, 10, 168, 17, 1);
    draw_text_transparent(s, 100 - strlen(s) * 3, 10, 15);
}

show_menu(s, x, y)
char *s;
int x, y;
{
    int r;                          /* distance to a guard */

    r = text_window(s, x, y);
    g_gfx->fillcolor = 1;
}

mission_end_text()
{
    if (cur_room) {
        result_score = -1;
        if (guards[0].stun > 256)
            strcpy(msg_buf, "You are overcome\nby gas and pass out.\n");
        else if (((equipment & 0x40) ? 3 : 1) < wounds)
            strcpy(msg_buf, "You slump to\nthe ground, overcome\nby your wounds.\n");
        else
            strcpy(msg_buf, "The prisoner is\nreleased while you\nare out of the room.\n");
    } else {
        result_score = bug_score;
        if (frame_count > 64 && (tac_mode == 3 || tac_mode == 2) && guards_near == 0)
            strcpy(msg_buf, "You have eliminated\nall of your enemies.\n");
        else
            strcpy(msg_buf, "You quickly slip\nout of the building.\n");
    }
    message_shown = 1;
    show_menu(msg_buf, 32, 100);
    wait_retrace(120);
}

/* Kinds of evidence a file search can turn up (item_names); emitted after
 * search_files. */
int file_items[8] = { 2, 5, 6, 7, 8, 9, 10, 15 };

search_files()
{
    int tries;
    int i;
    int k;

    tries = 0;
    do {
        switch (random(5)) {
        case 4:
            k = cur_city;
            if (!(raided_cities & (1 << cur_city)))
                k = random(16);
            if (raided_cities & (1 << k)) {
                strcpy(msg_buf, "The CIA agent in\n");
                strcat(msg_buf, cities[k].name);
                strcat(msg_buf, " is\na double agent!!\n");
                show_menu(msg_buf, 20, 100);
                tries = 999;
            }
            break;
        case 0:
            if (target_person != -1 && (persons[target_person].clues & 0x7FFF) && random(3) == 0)
                k = 0;
            else
                k = cur_org;
            if (!(known_plans & (1 << k))) {
                show_master_plan(k, 1L);
                tries = 999;
                break;
            }
            k = random(4);
            if (agents[k].person != -1) {
                strcpy(msg_buf, agents[k].name);
                strcat(msg_buf, " now\nin ");
                strcat(msg_buf, cities[persons[agents[k].person].city].name);
                strcat(msg_buf, "!\n");
                show_menu(msg_buf, 20, 100);
                tries = 999;
            }
            break;
        case 1:
            k = file_items[random(8)];
            if (!(equipment & ((unsigned)1 << k))) {
                strcpy(msg_buf, "You find\n");
                strcat(msg_buf, item_names[k]);
                strcat(msg_buf, "!\n");
                show_menu(msg_buf, 20, 80);
                equipment |= (unsigned)1 << k;
                if (k == 15)
                    for (i = 0; i <= n_rooms; i++)
                        rooms[i].flags |= 2;
                if (k == 8)
                    grenades[0] = clamp(grenades[0] + 2, 0, 8);
                if (k == 9)
                    grenades[1] = clamp(grenades[1] + 2, 0, 8);
                if (k == 10)
                    grenades[2] = clamp(grenades[2] + 2, 0, 8);
                tries = 999;
            }
            break;
        case 2:
        case 3:
            i = random(n_clues - orig_difficulty * 4);
            k = 1 << i;
            if (target_person == -1 || !(k & persons[target_person].clues)
                || ((mission_flags & 4) && (k & persons[target_person].found)))
                break;
            msg_buf[0] = 0;
            if (!(k & persons[target_person].found)) {
                persons[target_person].found |= k;
                suspect_dossier(target_person, 0, 0);
                strcpy(msg_buf, "");
                append_person_name(target_person);
                strcat(msg_buf, " has\nbeen identified as\na participant\nin the plot.\n");
            } else if (!(mission_flags & 4) && target_person != 0) {
                suspect_dossier(target_person, 0, 0);
                strcpy(msg_buf, "You find incriminating\nevidence which will\nturn ");
                append_person_name(target_person);
                strcat(msg_buf, "\ninto a double agent!\n");
                mission_flags |= 4;
            }
            if (msg_buf[0]) {
                show_menu(msg_buf, 20, 100);
                tries = 999;
            }
            break;
        }
        tries++;
    } while (tries < 9);
}

choose_password()
{
    char line[256];
    char *stream;
    int ok;
    int i;
    int spare;

    stream = fopen("text.dta", "rt");
    fseek(stream, (long)random(20000), 0);
    fscanf(stream, "%32s", password);
    ok = 0;
    do {
        fscanf(stream, "%32s", password);
        if (strlen(password) >= 5 && strlen(password) <= 9) {
            ok = 1;
            for (i = 0; i < strlen(password); i++)
                if (password[i] < 'a' || password[i] > 'z') {
                    ok = 0;
                    break;
                }
        }
    } while (!ok);
    strcpy(password_shown, "..........");
    password_shown[strlen(password)] = 0;
    fclose(stream);
}

reveal_password_letter()
{
    int tries;
    int k;

    tries = 0;
    do {
        k = random(strlen(password));
        if (password[k] != ' ' && password_shown[k] == '.') {
            password_shown[k] = password[k];
            tries = 99;
        }
        tries++;
    } while (tries < 99);
    gfx_fill_rect(g_gfx, 248, 88, 64, 9, 10);
    draw_rect_outline(248, 88, 64, 9, 2);
    draw_text_transparent(password_shown, 250, 89, 5);
}

computer_terminal()
{
    present_back_buffer();
    draw_terminal_frame("Enter PassWord:");
    msg_buf[0] = 0;
    if (terminal_input(116, 100, 12) != -1) {
        draw_terminal_frame("");
        if (strcmpi(msg_buf, password) == 0) {
            draw_text_centered("Access CONFIRMED", 160, 103, 10);
            terminal_search();
            if (random(3) < orig_difficulty)
                compute_room_distances(cur_room, 240);
        } else {
            draw_text_centered("Access DENIED", 160, 103, 12);
            compute_room_distances(cur_room, 240);
            wait_retrace(90);
        }
        choose_password();
    }
    g_gfx->fillcolor = 1;
    drv_set_color_map(tac_colormap, tac_colormap);
    save_to_back_buffer();
    draw_equipment_panel();
}

draw_terminal_frame(title)
char *title;
{
    drv_set_color_map(terminal_colormap, terminal_colormap);
    fill_rect_xy(99, 85, 221, 114, 8);
    fill_rect_xy(100, 87, 220, 113, 5);
    fill_rect_xy(101, 88, 219, 112, 8);
    fill_rect_xy(105, 101, 215, 110, 5);
    draw_line(101, 86, 219, 86, 7);
    draw_line(103, 99, 217, 99, 5);
    draw_line(102, 112, 218, 112, 5);
    draw_line(104, 101, 104, 110, 7);
    draw_line(216, 101, 216, 110, 7);
    draw_text_centered(title, 161, 90, 2);
}

/* "Search for:" a person, city, organization, clue or agent. */
terminal_search()
{
    int p, tries, j, k;
    char word[20];
    int found, len;

    found = 0;
    wait_retrace(60);
    tries = 0;
    for (;;) {
        draw_terminal_frame("Search for:");
        msg_buf[0] = 0;
        terminal_input(106, 100, 15);
        flush_input();
        strcpy(word, msg_buf);
        strupr(word);
        if ((len = strlen(word)) == 0) return;
        for (p = 0; p < 64; p++) {
            if (!persons[p].id) continue;
            msg_buf[0] = 0;
            person_name(p);
            if (!strstr(strupr(msg_buf), word)) continue;
            if (persons[p].city != cur_city && persons[p].org != cur_org && orig_difficulty >= 2)
                continue;
            persons[p].known |= 0x1f;
            if (persons[p].city == cur_city && persons[p].org == cur_org)
                persons[p].found |= persons[p].clues & 0x7fff;
            suspect_dossier(p, 0, 0);
            wait_key_or_button();
            return;
        }
        for (j = 0; j < 16; j++) {
            strcpy(msg_buf, cities[j].name);
            if (strstr(strupr(msg_buf), word)) {
                strcpy(msg_buf, orgs[cur_org].name);
                strcat(msg_buf, " has\n");
                if (org_alert_level(j, cur_org)) {
                    strcat(msg_buf, "a");
                    append_building_type(j, cur_org);
                    cities[j].orgs_known |= 1 << cur_org;
                    set_location_known(cur_org, j, 12);
                    found = 1;
                } else {
                    strcat(msg_buf, "no operatives");
                    found = 0;
                }
                strcat(msg_buf, "\nin ");
                strcat(msg_buf, cities[j].name);
                strcat(msg_buf, "\n");
                if (found) {
                    popup_x = 100;
                    popup_y = 100;
                    popup_face = -2;
                    draw_intercept_popup();
                    wait_key_or_button();
                    return;
                }
                goto show;
            }
        }
        for (j = 2; j < 16; j++) {
            strcpy(msg_buf, orgs[j].name);
            if (strstr(strupr(msg_buf), word)) {
                strcpy(msg_buf, orgs[j].name);
                if (org_alert_level(cur_city, j)) {
                    append_building_type(cur_city, j);
                    cities[cur_city].orgs_known |= 1 << j;
                    set_location_known(j, cur_city, 12);
                    found = 1;
                } else {
                    strcat(msg_buf, " has\nno operatives");
                    found = 0;
                }
                strcat(msg_buf, "\nin ");
                strcat(msg_buf, cities[cur_city].name);
                strcat(msg_buf, "\n");
                if (!found) {
show:
                    show_menu(msg_buf, 100, 80);
                    return;
                }
                popup_x = 100;
                popup_y = 100;
                popup_face = -2;
                draw_intercept_popup();
                wait_key_or_button();
                return;
            }
        }
        j = 0;
        while (j < n_clues) {
            k = load_clue_text(j, 0);
            msg_buf[0] = 0;
            append_number(k);
            if (strstr(strupr(msg_buf), word) && reveal_random_clue(j, cur_org, cur_city))
                return;
            j++;
        }
        for (j = 0; j < 4; j++) {
            if (agents[j].person != -1) {
                strcpy(msg_buf, agents[j].name);
                if (strstr(strupr(msg_buf), word)) {
                    strcpy(msg_buf, agents[j].name);
                    strcat(msg_buf, " now\nin ");
                    strcat(msg_buf, cities[persons[agents[j].person].city].name);
                    strcat(msg_buf, "!\n");
                    goto show;
                }
            }
        }
        draw_terminal_frame("");
        draw_text_centered("No Data", 160, 103, 7);
        wait_retrace(90);
        if (++tries >= 3) return;
    }
}

/* Line input on the terminal into msg_buf; 1 on Enter, -1 on Esc. */
terminal_input(x, y, n)
int x, y, n;
{
    int first, key, i;
    char tmp[64];

    gfx_fill_rect(g_gfx, x, y + 1, n * 7, 9, 5);
    g_gfx->fillcolor = 5;
    cursor_pos = 0;
    first = 1;
    for (i = strlen(msg_buf); i < n; i++)
        msg_buf[i] = ' ';
    msg_buf[n] = 0;
    draw_input_field(x, y, n);
    flush_input();
    KBD_FLAGS &= ~0x20;
    for (;;) {
        while (drv_kbhit()) {
            drv_recolor_rect(g_gfx, cursor_x, y + 1, cursor_w, 10, 5, 2);
            wait_retrace(10);
            drv_recolor_rect(g_gfx, cursor_x, y + 1, cursor_w, 10, 2, 5);
            if (drv_kbhit()) wait_retrace(10);
        }
        key = get_key();
        if (key == 13) {
            KBD_FLAGS |= 0x20;
            break;
        }
        if (key == 0x4b00 && cursor_pos) cursor_pos--;
        if (key == 0x4d00 && cursor_pos < n - 1) cursor_pos++;
        if (key == 0x5200) {
            strcpy(tmp, msg_buf + cursor_pos);
            strcpy(msg_buf + cursor_pos + 1, tmp);
            msg_buf[cursor_pos] = ' ';
            msg_buf[n] = 0;
        }
        if (key == 0x5300) {
            strcpy(msg_buf + cursor_pos, msg_buf + cursor_pos + 1);
            msg_buf[cursor_pos] = ' ';
            msg_buf[n - 1] = ' ';
            msg_buf[n] = 0;
        }
        if (key == 8 && cursor_pos) {
            strcpy(msg_buf + cursor_pos - 1, msg_buf + cursor_pos);
            msg_buf[n - 1] = ' ';
            msg_buf[n] = 0;
            cursor_pos--;
        }
        if (key < 0x80 && key >= 0x20) {
            if (first)
                for (i = 0; i < n; i++)
                    msg_buf[i] = ' ';
            msg_buf[cursor_pos] = key;
            if (cursor_pos < n - 1) cursor_pos++;
        }
        if (key == 27) return -1;
        first = 0;
        draw_input_field(x, y, n);
    }
    for (i = n - 1; i >= 0 && msg_buf[i] == ' '; i--)
        msg_buf[i] = 0;
    return 1;
}

/* Draw the input field and note where the cursor is. */
draw_input_field(x, y, n)
int x, y, n;
{
    int i, ch;

    x += 2;
    y += 2;
    for (i = 0; i < n; i++) {
        gfx_fill_rect(g_gfx, x, y, 8, 8, 5);
        if (strlen(msg_buf) > i) {
            ch = msg_buf[i + 1];
            msg_buf[i + 1] = 0;
            draw_text(msg_buf + i, x, y, 10);
            msg_buf[i + 1] = ch;
            if (i == cursor_pos) {
                cursor_x = x;
                cursor_w = drv_char_width(1, msg_buf[i]);
            }
            x += drv_char_width(1, msg_buf[i]);
        }
    }
}

/* Portrait (or camera picture) and the text in msg_buf. */
draw_intercept_popup()
{
    int a, b, c, d;
    int x, y, k;

    x = clamp(31, popup_x - 146, popup_x);
    y = clamp(49, popup_y - 102, popup_y);
    gate_thunk_b(g_gfx, x, y, camera_img);
    if (popup_face > -1)
        draw_portrait(popup_face, x + 66, y + 24);
    if (popup_face == -2)
        gate_thunk_b(g_gfx, x + 55, y + 7, camera_img2);
    g_gfx->fillcolor = 11;
    draw_wrapped_text(14, x + 20, y + 67, 3);
    draw_wrapped_text(14, x + 19, y + 67, 5);
    draw_rect_outline(x + 13, y + 10, 119, 78, 15);
    draw_rect_outline(x + 57, y + 41, 31, 16, 15);
}

present_back_buffer()
{
    drv_copy_rect(g_gfx, 0, 0, 320, 200, work_page, 0, 0);
}

save_to_back_buffer()
{
    drv_copy_rect(work_page, 0, 0, 320, 200, g_gfx, 0, 0);
}

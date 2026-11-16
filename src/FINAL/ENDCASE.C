/* ENDCASE.C - FINAL.EXE: the debriefing at the end of a case (plot recap,
 * promotion, retirement, continue/save menu), the case timeline replay, and the
 * reports: date string, efficiency report, career summary, rogues' gallery and
 * the vacation snapshot.  One object in the original (image 275E-4F4C, data
 * 2504-3010: its data runs on from the timeline's strings to the date string
 * without an alignment gap).
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "final.h"

RastPort icon_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *icon_page = &icon_rp;
char plot_key[] = "*PL0000";

end_of_case()
{
    int unused, ep;
    char line[40];
    int i, clue, ok, choice, rank, spare2;

    play_sound(2);
    set_scene_var(0, 4);
    drv_set_color_map(story_colors, story_colors);
    set_scene_background("briefing.pan", 0, 0);
    strcpy(text_buf, "It looks like that about wraps it up, Max. ");
    strcat(text_buf, "We've been able to put together a pretty good chronology of this case, take a look.");
    wrap_text_buffer(40);
    show_menu(text_buf, 8, 149);
    clear_text_area();
    load_picture_swapped("icons.pic", 2);
    gfx_fill_rect(g_gfx, 0, 0, 320, 200, 1);
    num_participants = num_suspects - difficulty * 4;
    for (i = 0; i < num_persons; i++)
        persons[i].points = persons[i].known;
    mm_known = persons[0].known;
    reveal_all_case_data();
    persons[0].known = mm_known;
    case_result = ep_earned = items_taken = ep_possible = case_items = 0;
    case_timeline();
    ep = efficiency_report();
    play_sound(1);
    strcpy(plot_key, "*PL0000");
    plot_key[3] = plot_num / 10 + '0';
    plot_key[4] = plot_num % 10 + '0';
    plot_key[5] = last_episode + '0';
    if (case_result & 0x40)
        plot_key[6] = '5';
    set_scene_var(0, case_result & 0x40 ? 4 : 3);
    drv_set_color_map(story_colors, story_colors);
    set_scene_background("briefing.pan", 0, 0);
    do {
        text_buf[0] = 0;
        if (ok = lookup_text_simple("plot.txt", plot_key)) {
            wrap_text_buffer(40);
            show_menu(text_buf, 8, 149);
            clear_text_area();
        }
        plot_key[6]++;
    } while (ok);
    if (case_result & 0x40)
        plot_episodes |= 1 << last_episode;
    else {
        clue = -1;
        if (!(mm_known & 8))
            clue = 8;
        if (!(mm_known & 4))
            clue = 4;
        if (!(mm_known & 1))
            clue = 1;
        if (!(mm_known & 2))
            clue = 2;
        if (clue != -1 && plot_num) {
            strcpy(text_buf, "Interrogation of the suspects has revealed some additional information about Mr.Big.");
            wrap_text_buffer(40);
            show_menu(text_buf, 8, 149);
            pick_clue(mm_org, mm_city, clue, 1L);
            mm_known |= clue;
        }
    }
    if (persons[0].fate == -1) {
        strcpy(text_buf, "You have captured the MasterMind controlling the ");
        strcat(text_buf, orgs[mm_org].name);
        strcat(text_buf, "! The country has been saved from a dangerous plot. ");
        strcat(text_buf, "Congratulations, the President commends you.\n");
        clear_text_area();
        wrap_text_buffer(38);
        show_menu(text_buf, 8, 149);
    }
    vacation_snapshot(clamp(ep * (difficulty + 1) / 150, cur_month != 0, 20), 1L);
    flush_input();
    wait_key_or_button();
    play_sound(1);
    require_disk(1, 1L);
    load_hall_of_fame();
    hall_of_fame_insert(ep);
    save_hall_of_fame();
    cur_month++;
    history_len = -1;
    for (i = 0; i < 0x1fc; i++)
        if (history[i] == 0xFF) {
            history_len = i;
            break;
        }
    if (history_len != -1) {
        history[history_len++] = (plot_num << 4) + last_episode;
        history[history_len++] = case_result;
        history[history_len++] = ep / 256;
        history[history_len++] = ep;
        if (case_result & 0x80)
            history[history_len++] = leader_code;
        history[history_len] = 0xFF;
    }
    if (case_result & 0x80)
        masterminds_arrested |= 1L << leader_code;
    career_summary();
    career_points += ep * (difficulty + 1) / 16;
    rank = clamp((cur_month * 100 + 10000) / (career_points + 100), 1, 99);
    if (rank < career_rank) {
        strcpy(text_buf, "Congratulations Max, we've decided to promote you from 00");
        strcat(text_buf, itoa(career_rank, num_buf, 10));
        strcat(text_buf, " rank to 00");
        strcat(text_buf, itoa(rank, num_buf, 10));
        strcat(text_buf, " rank. Here's a commendation from the President.");
        career_rank = rank;
        set_scene_var(0, 1);
        drv_set_color_map(story_colors, story_colors);
        set_scene_background("briefing.pan", 0, 0);
        wrap_text_buffer(36);
        show_menu(text_buf, 8, 149);
        clear_text_area();
    }
    anim_active = 0;
    if (num_masterminds == 26)
        strcpy(text_buf, "INCREDIBLE: You have\narrested all 26 Masterminds!\n");
    if (cur_month == 120)
        strcpy(text_buf, "You have completed a\nten year career with the CIA.\n");
    if (num_masterminds == 26 || cur_month == 120) {
        strcat(text_buf, "You retire to a well-\ndeserved life of relaxation.\n");
        rogues_gallery();
        set_exit_state();
        ENV[0] = 0xFF;
        exit();
    }
    for (;;) {
        strcpy(text_buf, "Do you want to...\n Continue Game\n Save Game\n End Game\n");
        if (difficulty < 3 && (case_result & 0x80))
            strcat(text_buf, " Change Difficulty Level\n");
        choice = show_menu(text_buf, 80, 80);
        if (choice != 3)
            break;
        difficulty++;
        strcpy(text_buf, "Which difficulty level?\n Local Disturbance\n National Threat\n Regional Conflict\n Global Crisis\n");
        difficulty = clamp(show_menu(text_buf, 80, 80), 0, 3);
    }
    if (choice == 2) {
        set_exit_state();
        ENV[0] = 0xFF;
        exit();
    }
    if (choice == 1) {
        options |= 0x40;
        clock_base = 0;
        here_city = 1;
        save_game_menu();
        strcpy(text_buf, "Do you want to...\n Continue Game\n End Game\n");
        if (show_menu(text_buf, 80, 80) == 1) {
            set_exit_state();
            ENV[0] = 0xFF;
            exit();
        }
    }
    set_scene_var(0, 4);
    drv_set_color_map(story_colors, story_colors);
    set_scene_background("briefing.pan", 0, 0);
}

case_timeline()
{
    int p, tmp, agent2, fl, what, wait, unused2, unused3, i, holder, item;

    drv_set_color_map(face_colormap, face_colormap);
    gfx_fill_rect(g_gfx, 0, 0, 320, 104, 7);
    g_gfx->fillcolor = 1;
    for (i = 0; i < num_participants; i++)
        timeline_draw_person(i);
    timeline_draw_marker(0);
    if (!is_cga)
        drv_recolor_rect(g_gfx, 0, 0, 320, 104, 9, 7);
    gfx_fill_rect(g_gfx, 0, 104, 320, 96, 1);
    g_gfx->fillcolor = 9;
    item = 0;
    do
        items[item].holder = -1;
    while (++item < 4);
    for (i = 0; i < num_msgs; i++) {
        if (msgs[i].type != -1) {
            what = msgs[i].msg;
            wait = 0;
            gfx_fill_rect(g_gfx, 8, 112, 304, 80, is_cga ? 0 : 9);
            if (!is_cga)
                drv_recolor_rect(g_gfx, 0, 0, 320, 104, 9, 1);
            draw_text_centered(format_date_time(msgs[i].time) + 9, 160, 114, 7);
            switch (msgs[i].type) {
            case 0:
                if (msgs[i].flags == 0) {
                    wait = 1;
                    break;
                }
                if (!(plots[what].flags & 0x100) || what < 0) {
                    strcpy(text_buf, "");
                    append_person_name(p = msgs[i].sender);
                    agent2 = plots[what].suspect;
                    if (what >= 0) {
                        strcat(text_buf, " (");
                        strcat(text_buf, suspects[plots[what].suspect].name);
                        strcat(text_buf, ") ");
                        timeline_draw_icon(plots[what].suspect);
                    } else {
                        timeline_draw_link(p);
                        strcat(text_buf, " ");
                    }
                    if (p) {
                        strcat(text_buf, orgs[persons[p].org].name);
                        strcat(text_buf, "/");
                        strcat(text_buf, cities[persons[p].city].name);
                    }
                    truncate_text_to_width(300);
                    draw_text_centered(text_buf, 160, 124, 15);
                    if (what < 0) {
                        strcpy(text_buf, " sent message to ");
                        append_person_name(msgs[i].receiver);
                        draw_text_centered(text_buf, 160, 132, 15);
                        draw_line(20, 150, 299, 150, 7);
                        strcpy(text_buf, "^");
                        load_message_text(what);
                        strcat(text_buf, "^");
                        draw_wrapped_text(35, 20, 152, 14);
                        timeline_draw_link(msgs[i].receiver);
                    } else {
                        strcpy(text_buf, "");
                        strcat(text_buf, plots[what].name);
                        fl = plots[what].flags;
                        if (fl & 0x200)
                            strcpy(text_buf, "sent message to");
                        if (fl & 0x400)
                            strcpy(text_buf, "sent package to");
                        draw_text_centered(text_buf, 160, 132, 15);
                        if (plots[what].flags & 0xf00) {
                            strcpy(text_buf, "");
                            append_person_name(p = msgs[i].receiver);
                            strcat(text_buf, " (");
                            strcat(text_buf, suspects[plots[what].flags & 0xff].name);
                            strcat(text_buf, ") ");
                            if (p) {
                                strcat(text_buf, orgs[persons[p].org].name);
                                strcat(text_buf, "/");
                                strcat(text_buf, cities[persons[p].city].name);
                            }
                            truncate_text_to_width(300);
                            draw_text_centered(text_buf, 160, 140, 15);
                            timeline_draw_icon(plots[what].flags & 0xff);
                            draw_line(20, 150, 299, 150, 7);
                            if (!(fl & 0x400)) {
                                strcpy(text_buf, "^");
                                load_message_text(what);
                                strcat(text_buf, "^");
                                draw_wrapped_text(35, 12, 152, 14);
                            }
                        }
                    }
                    wait = -1;
                } else
                    wait = 1;
                p = suspects[plots[what].suspect].person;
                for (item = 0; item < 4; item++) {
                    if (plots[what].items & 1 << item) {
                        if (wait <= 0)
                            wait_key_or_button();
                        gfx_fill_rect(g_gfx, 8, 112, 304, 80, is_cga ? 0 : 9);
                        holder = items[item].holder;
                        items[item].holder = p;
                        timeline_scroll(holder);
                        timeline_scroll(p);
                        text_buf[0] = 0;
                        append_person_name(p);
                        agent2 = plots[what].suspect;
                        strcat(text_buf, " (");
                        strcat(text_buf, suspects[plots[what].suspect].name);
                        strcat(text_buf, ") ");
                        draw_text_centered(text_buf, 160, 140, 15);
                        strcpy(text_buf, "now has the ");
                        strcat(text_buf, items[item].name);
                        draw_text_centered(text_buf, 160, 148, 15);
                        wait = -1;
                        case_items |= 1 << item;
                    }
                    if (plots[what].items & 0x100 << item) {
                        holder = items[item].holder;
                        items[item].holder = -1;
                        timeline_scroll(holder);
                    }
                }
                break;
            case 11:
                wait = 1;
                break;
            case 1:
                strcpy(text_buf, "");
                append_person_name(what >> 8);
                strcat(text_buf, " left ");
                strcat(text_buf, cities[what & 0xff].name);
                break;
            case 4:
                strcpy(text_buf, "You traveled to ");
                strcat(text_buf, cities[what].name);
                break;
            case 5:
                strcpy(text_buf, "You broke in to ");
                strcat(text_buf, orgs[what >> 8].name);
                strcat(text_buf, "/");
                strcat(text_buf, cities[what & 0xff].name);
                break;
            case 6:
                strcpy(text_buf, "You arrested ");
                append_person_name(what);
                draw_text_centered(text_buf, 160, 144, 15);
                timeline_draw_event(what);
                wait = -1;
                break;
            case 7:
                strcpy(text_buf, "You confiscated ");
                strcat(text_buf, items[what].name);
                holder = items[what].holder;
                items[what].holder = -1;
                timeline_scroll(holder);
                items_taken |= 1 << what;
                break;
            case 8:
                text_buf[0] = 0;
                append_person_name(what);
                strcat(text_buf, " went into hiding.");
                draw_text_centered(text_buf, 160, 140, 15);
                holder = -1;
                for (item = 0; item < num_plots; item++)
                    if (plots[item].state == 999 && suspects[plots[item].suspect].person == what) {
                        holder = item;
                        break;
                    }
                if (holder == -1)
                    strcpy(text_buf, "Mission completed.");
                else {
                    strcpy(text_buf, "Unable to");
                    draw_text_centered(text_buf, 160, 148, 15);
                    strcpy(text_buf, "complete mission.");
                }
                draw_text_centered(text_buf, 160, 156, 15);
                timeline_draw_marker(what);
                wait = -1;
                break;
            case 9:
            case 10:
            case 13:
                text_buf[0] = 0;
                append_person_name(what);
                switch (msgs[i].type) {
                case 9:
                    strcat(text_buf, " came out of hiding.");
                    break;
                case 10:
                    strcat(text_buf, " escaped from jail.");
                    break;
                case 13:
                    strcat(text_buf, " released by exchange.");
                    break;
                }
                draw_text_centered(text_buf, 160, 144, 15);
                timeline_draw_person_b(what);
                wait = -1;
                break;
            case 12:
                strcpy(text_buf, "You turned ");
                append_person_name(what);
                timeline_draw_link(what);
                if (!is_cga)
                    drv_recolor_rect(g_gfx, 0, 0, 320, 104, 9, 2);
                break;
            }
            if (wait == 0) {
                truncate_text_to_width(300);
                draw_text_centered(text_buf, 160, 144, 15);
            }
            if (wait <= 0 && wait_key_or_button() == 27)
                return;
        }
    }
}

timeline_draw_person(n)
int n;
{
    int x, y, face;

    x = n % 4 * 80;
    y = n / 4 * 52;
    gfx_fill_rect(g_gfx, x + 1, y + 1, 78, 50, is_cga ? 3 : 1);
    face = persons[suspects[n].person].id;
    draw_face_parts(face, x + 45, y + 8);
    draw_sprite_a((face & 1 ? 0x68 : 0x70) + (face & 3), x + 35, y + 33);
    timeline_label(x, y, n);
}

timeline_label(x, y, n)
int x, y, n;
{
    char *p;

    strcpy(text_buf, suspects[n].name);
    p = strstr(text_buf, " ");
    if (is_cga) {
        if (!p)
            draw_text(text_buf, x + 2, y + 2, 5);
        else {
            *p = 0;
            draw_text(text_buf, x + 2, y + 2, 5);
            draw_text(p + 1, x + 2, y + 10, 5);
        }
    } else {
        if (!p)
            draw_text_transparent(text_buf, x + 2, y + 2, 5);
        else {
            *p = 0;
            draw_text_transparent(text_buf, x + 2, y + 2, 5);
            draw_text_transparent(p + 1, x + 2, y + 10, 5);
        }
    }
}

timeline_draw_link(person)
int person;
{
    int i;

    for (i = 0; i < num_participants; i++)
        if (suspects[i].person == person)
            timeline_draw_icon(i);
}

timeline_draw_icon(n)
int n;
{
    int x, y;

    x = n % 4 * 80;
    y = n / 4 * 52;
    if (!is_cga)
        drv_recolor_rect(g_gfx, x + 1, y + 1, 78, 50, 1, 9);
}

timeline_scroll(person)
int person;
{
    int s, x, y, k, img;

    if (person == -1)
        return;
    for (s = 0; s < num_participants; s++) {
        if (suspects[s].person != person)
            continue;
        x = s % 4 * 80;
        y = s / 4 * 52;
        img = drv_slot12(0, x + 1, y + 18);
        gfx_fill_rect(g_gfx, x + 1, y + 19, 16, 32, img);
        for (k = 0; k < 4; k++) {
            if (items[k].holder == person) {
                drv_copy_rect(icon_page, items[k].icon << 4, 0, 16, 16, g_gfx, x + 1, y + 35);
                y -= 16;
            }
        }
    }
}

timeline_draw_event(person)
int person;
{
    int x, y, i, k;

    for (i = 0; i < num_participants; i++) {
        if (suspects[i].person == person) {
            x = i % 4 * 80;
            y = i / 4 * 52;
            gfx_fill_rect(g_gfx, x, y, 80, 11, 7);
            gfx_fill_rect(g_gfx, x, y + 10, 24, 42, 7);
            gfx_fill_rect(g_gfx, x + 72, y + 10, 8, 42, 7);
            gfx_fill_rect(g_gfx, x, y + 40, 80, 12, 7);
            draw_line(x + 24, y + 39, x + 71, y + 39, 8);
            k = 24;
            do {
                draw_line(x + k, y + 11, x + k, y + 39, 7);
                draw_line(x + k + 1, y + 11, x + k + 1, y + 39, 0);
            } while ((k += 6) < 72);
            timeline_label(x, y, i);
        }
    }
}

timeline_draw_marker(person)
int person;
{
    int c, x, y, i;

    for (i = 0; i < num_participants; i++) {
        if (suspects[i].person != person)
            continue;
        x = i % 4 * 80;
        y = i / 4 * 52;
        for (c = 1; c < 16; c++) {
            if (c == 1)
                continue;
            drv_recolor_rect(g_gfx, x + 1, y + 9, 78, 42, c, 0);
        }
    }
}

timeline_draw_person_b(person)
int person;
{
    int c, x, y, i;

    for (i = 0; i < num_participants; i++)
        if (suspects[i].person == person)
            timeline_draw_person(i);
}

draw_sprite_a(n, x, y)
int n, x, y;
{
    drv_draw_image(g_gfx, x, y, icons[n]);
}

show_menu(s, x, y)
char *s;
int x, y;
{
    return text_window(s, x, y);
}

char date_str[] = "00:00 AM Jun 00";

char *format_date_time(t)
int t;
{
    int h;

    cur_minute = t % 60;
    date_str[3] = cur_minute / 10 + '0';
    date_str[4] = cur_minute % 10 + '0';
    t /= 60;
    cur_hour = t % 24;
    h = (cur_hour - 1) % 12 + 1;
    date_str[0] = h / 10 + '0';
    date_str[1] = h % 10 + '0';
    date_str[6] = cur_hour > 11 ? 'P' : 'A';
    strcpy(date_str + 9, month_names[cur_month % 12]);
    strcat(date_str, " 10");
    cur_day = t / 24 + 1;
    date_str[13] = cur_day / 10 + '0';
    date_str[14] = cur_day % 10 + '0';
    return date_str;
}

reveal_all_case_data()
{
    int i;

    for (i = 0; i < num_persons; i++)
        if (persons[i].id) persons[i].known = -1;
    for (i = 0; i < num_suspects; i++) {
        suspects[i].flags |= 0x8000;
        persons[suspects[i].person].roles |= 1 << i;
    }
    for (i = 0; i < num_msgs; i++)
        msgs[i].flags |= 0xF;
    for (i = 0; i < num_plots; i++)
        plots[i].flags |= 0x8000;
}

/* One unreferenced zero byte follows efficiency_report's strings in the original
 * data (and rogues_gallery's), before the next table's strings. */
char unused_2afb = 0;

efficiency_report()
{
    int p, total, msg, junk, cost, xpos, j, k, ypos, score;  /* junk, j unused */

    draw_page_frame("Efficiency Report", 14);
    ypos = 11;
    xpos = 8;
    drv_set_color_map(report_colormap, report_colormap);
    for (k = 0; k < num_participants; k++) {
        draw_card_panel(xpos, ypos);
        strcpy(text_buf, suspects[k].name);
        draw_text_transparent(text_buf, xpos + 100, ypos + 2, 0);
        p = suspects[k].person;
        if (!(suspects[k].flags & 0x100) || persons[p].fate == -1 || persons[p].fate == -3) {
            draw_portrait(persons[p].id, xpos + 0x66, ypos + 0x10);
            text_buf[0] = 0;
            append_person_name(p);
            strcat(text_buf, ", ");
            strcat(text_buf, rank_names[suspects[k].rank]);
            draw_text_transparent(text_buf, xpos + 100, ypos + 0x48, 0);
            text_buf[0] = 0;
            strcat(text_buf, orgs[persons[p].org].name);
            strcat(text_buf, "/");
            strcat(text_buf, cities[persons[p].city].name);
            draw_text_transparent(text_buf, xpos + 100, ypos + 0x50, 0);
        }
        drv_set_color_map(report_colormap, report_colormap);
        strcpy(text_buf, "At Large");
        score = 0;
        if (persons[p].fate == -1) {
            score = 5;
            strcpy(text_buf, "ARRESTED");
            case_result++;
        } else if (persons[p].fate == -3) {
            score = 10;
            strcpy(text_buf, "TURNED");
            case_result++;
        } else {
            if ((known_before(p) & 0xE) == 0xE) score++;
            if (known_before(p) & 1) score++;
        }
        if (p == 0 && score >= 5) case_result |= 0x80;
        draw_text_transparent(text_buf, xpos + 0x18, ypos + 2, 12);
        score *= suspects[k].rank + 3;
        cost = suspects[k].rank * 5 + 15;
        if (p == 0) {
            score <<= 2;
            cost <<= 2;
        }
        strcpy(text_buf, "EP:");
        strcat(text_buf, itoa(score, report_num_buf, 10));
        strcat(text_buf, "\211/");
        strcat(text_buf, itoa(cost, report_num_buf, 10));
        draw_text_transparent(text_buf, xpos + 0xF4, ypos + 2, 1);
        ep_earned += score;
        ep_possible += cost;
        xpos = random(14) + 2;
        ypos += 10;
        wait_key_or_button();
    }
    for (k = 0; k < 4; k++) {
        if (case_items & ((unsigned)1 << k)) {
            draw_card_panel(xpos, ypos);
            ep_possible += 50;
            strcpy(text_buf, items[k].name);
            draw_text_transparent(text_buf, xpos + 100, ypos + 2, 0);
            strcpy(text_buf, "EP:0");
            if (items_taken & ((unsigned)1 << k)) {
                draw_text_transparent("CONFISCATED", xpos + 8, ypos + 2, 12);
                strcpy(text_buf, "EP:50");
                ep_earned += 50;
            } else
                draw_text_transparent("Not found", xpos + 0x18, ypos + 2, 12);
            strcat(text_buf, "\211/50");
            draw_text_transparent(text_buf, xpos + 0xF0, ypos + 2, 1);
            xpos = random(14) + 2;
            ypos += 10;
            wait_key_or_button();
        }
    }
    total = 0;
    for (k = 0; k < num_msgs; k++) {
        if (msgs[k].type == 0) {
            msg = msgs[k].msg;
            if (plots[msg].severity) {
                draw_card_panel(xpos, ypos);
                total += plots[msg].severity;
                if (plots[msg].severity >= 5) case_result |= 0x40;
                score = plots[msg].severity * 40;
                strcpy(text_buf, plots[msg].name);
                if (!(plots[msg].flags & 0x2000)) {
                    strcat(text_buf, " ");
                    strcat(text_buf, suspects[plots[msg].suspect].name);
                }
                draw_text_centered(text_buf, xpos + 0x97, ypos + 2, 0);
                strcpy(text_buf, "EP: 0/");
                strcat(text_buf, itoa(score, report_num_buf, 10));
                draw_text_transparent(text_buf, xpos + 0xF0, ypos + 2, 4);
                ep_possible += score;
                text_buf[0] = 0;
                load_message_text(msg);
                draw_wrapped_text(0x20, xpos + 8, ypos + 0x10, 12);
                xpos = random(14) + 2;
                ypos += 10;
                wait_key_or_button();
            }
        }
    }
    if (!(case_result & 0x40)) {
        draw_card_panel(xpos, ypos);
        draw_text_centered("Prevented crime", xpos + 0x97, ypos + 2, 0);
        draw_text_transparent("EP:100\211/100", xpos + 0xF0, ypos + 2, 1);
        ep_earned += 100;
        ep_possible += 100;
        xpos = random(14) + 2;
        ypos += 10;
        wait_key_or_button();
    }
    score = 0;
    k = 0;
    do {
        if (double_agents & (1 << k)) score++;
    } while (++k < 16);
    if (score) {
        draw_card_panel(xpos, ypos);
        strcpy(text_buf, "");
        strcat(text_buf, itoa(score, report_num_buf, 10));
        strcat(text_buf, " Double Agent(s)");
        draw_text_transparent(text_buf, xpos + 100, ypos + 2, 0);
        strcpy(text_buf, "remained undetected");
        draw_text_transparent(text_buf, xpos + 100, ypos + 10, 0);
        strcpy(text_buf, "within the CIA.");
        draw_text_transparent(text_buf, xpos + 100, ypos + 0x12, 0);
        strcpy(text_buf, "EP:0/");
        strcat(text_buf, itoa(score * 50, report_num_buf, 10));
        draw_text_transparent(text_buf, xpos + 0xF0, ypos + 2, 4);
        ep_possible += score * 50;
        xpos = random(14) + 2;
        ypos += 10;
        wait_key_or_button();
    }
    draw_card_panel(xpos, ypos);
    total = ep_earned * 25 / (ep_possible / 40);
    if (total < 0) total = 0;
    draw_text_transparent("Efficiency Rating", xpos + 100, ypos + 2, 0);
    strcpy(text_buf, "--- ");
    strcat(text_buf, itoa(total, report_num_buf, 10));
    strcat(text_buf, " ---");
    draw_text_transparent(text_buf, xpos + 100, ypos + 0x18, 0);
    strcpy(text_buf, "EP:");
    strcat(text_buf, itoa(ep_earned, report_num_buf, 10));
    strcat(text_buf, "\211/");
    strcat(text_buf, itoa(ep_possible, report_num_buf, 10));
    draw_text_transparent(text_buf, xpos + 0xF0, ypos + 2, 1);
    wait_key_or_button();
    return total;
}

char *crime_names[] = {
    "Kidnapping", "Theft", "Assassination", "Drug Smuggle",
    "Theft", "Photo", "Bombing", "DataCrime",
    "Terrorist Attack", "Forgery", "Jail Break", "Blackmail",
    "Manufacture"
};

/* by leader code */
char *mastermind_names[] = {
    "PFO", "M18", "Jamaican Gang", "Haitian Junta",
    "Red September", "Iraqi SP", "Muslim Jihad", "Shining Way",
    "Tupamaros", "Colombian Cartel", "Mafia", "Libyan Emb.",
    "FLN", "Amazon Cartel", "Mercenaries", "Death Squads",
    "Rev. Guards", "UnionCorsique", "PIFA", "Red Army",
    "Red Battalion", "Direct Action", "Stassi", "PRC",
    "Marxists", "Dignity Bttn"
};

career_summary()
{
    int crime, arrests, busted, eps, xpos, sub, off, ypos, value, n, plot;

    draw_page_frame("Career", 1);
    draw_text_centered("The Career of", 160, 16, 0);
    strcpy(text_buf, "Max '");
    strcat(text_buf, codename);
    strcat(text_buf, "' Remington");
    draw_text_centered(text_buf, 160, 24, 0);
    off = n = eps = arrests = busted = 0;
    ypos = 0x24;
    while (history[off] != 0xFF && off < 0x100) {
        plot = history[off] >> 4;
        sub = history[off] & 0xF;
        strcpy(text_buf, "Case #");
        strcat(text_buf, itoa(n + 1, career_num_buf, 10));
        strcat(text_buf, ", ");
        strcat(text_buf, month_names[n % 12]);
        strcat(text_buf, " ");
        strcat(text_buf, itoa(n / 12 + 1990, career_num_buf, 10));
        strcat(text_buf, ".  Arrests: ");
        value = history[off + 1] & 0xF;
        strcat(text_buf, itoa(value, career_num_buf, 10));
        arrests += value;
        strcat(text_buf, " EP: ");
        value = (history[off + 2] << 8) + history[off + 3];
        strcat(text_buf, itoa(value, career_num_buf, 10));
        eps += value;
        draw_text(text_buf, 16, ypos, 0);
        ypos += 8;
        strcpy(text_buf, (history[off + 1] & 0x40) ? "... couldn't stop " : "... prevented ");
        crime = plot_defs[plot].crime[sub];
        strcat(text_buf, crime_names[crime]);
        strcat(text_buf, "/");
        strcat(text_buf, plot_defs[plot].roles[sub][0]);
        truncate_text_to_width(300);
        draw_text(text_buf, 12, ypos, 7);
        ypos += 8;
        if (history[off + 1] & 0x80) {
            strcpy(text_buf, "... arrested ");
            strcat(text_buf, mastermind_names[history[off + 4]]);
            strcat(text_buf, " MasterMind!");
            off++;
            draw_text(text_buf, 12, ypos, 12);
            ypos += 8;
            busted++;
        }
        ypos += 2;
        off += 4;
        n++;
        if (ypos > 0xB4) {
            wait_key_or_button();
            draw_page_frame("Career", 1);
            ypos = 16;
        }
    }
    draw_line(12, ypos + 1, 0x12F, ypos + 1, 0);
    strcpy(text_buf, "Arrested, MasterMinds: ");
    strcat(text_buf, itoa(busted, career_num_buf, 10));
    strcat(text_buf, "  Agents: ");
    strcat(text_buf, itoa(arrests, career_num_buf, 10));
    draw_text(text_buf, 12, ypos + 4, 0);
    wait_key_or_button();
    if (masterminds_arrested) {
        xpos = ypos = 999;
        for (off = 0; off < 26; off++) {
            if (masterminds_arrested & (1L << off)) {
                num_masterminds++;
                if (xpos > 0x100) {
                    xpos = 0x1C;
                    ypos += 0x50;
                }
                if (ypos > 0x8C) {
                    if (ypos < 999) wait_key_or_button();
                    draw_page_frame("Career", 1);
                    ypos = 16;
                    draw_text_centered("MasterMinds Arrested", 160, 16, 0);
                    ypos = 32;
                }
                draw_face_for(off, xpos, ypos, 0, 0);
                draw_text_centered(mastermind_names[off], xpos + 0x19, ypos + 0x38, is_cga ? 0 : 12);
                xpos += 0x48;
                ypos ^= 8;
            }
        }
        wait_key_or_button();
    }
}

truncate_text_to_width(w)
int w;
{
    while (text_width(text_buf) > w)
        text_buf[strlen(text_buf) - 1] = 0;
}

char unused_2dd5 = 0;

/* Max beside the faces of every MasterMind arrested in the career. */
rogues_gallery()
{
    int xo, x, i, y;

    play_sound(2);
    xo = (options & 2) ? 0 : 0x61;
    load_picture_swapped("gender.pic", 1);
    gfx_fill_rect(back_page, xo, 0, 0xDF, 200, 5);
    drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
    x = (options & 2) ? 0x104 : 0x38;
    draw_text_centered("Max", x, 0x56, 14);
    draw_text_centered(codename, x, 0x5E, 14);
    draw_text_centered("Remington", x, 0x66, 14);
    i = 0;
    do {
        if (masterminds_arrested & (1L << i)) {
            x = random(0xA4) + 4;
            y = random(0x8C) + 4;
            draw_face_for(i, x + xo, y, 0, 0);
            draw_text_transparent("ARRESTED", x + xo + 1, y + 0x18, 0);
            draw_text_transparent("ARRESTED", x + xo, y + 0x17, 12);
            wait_retrace(30);
        }
    } while (++i < 26);
    wait_retrace(120);
    show_menu(text_buf, xo + 0x18, 0x40);
    play_sound(1);
}

char *vacation_prefix[] = {
    "lau", "off", "bch", "cas"
};
/* by score / 150: kind, then up to 4 frames (-1 none) */
int vacations[21][5] = {
    { 0, 1, -1, -1, -1 },
    { 0, 2, -1, -1, -1 },
    { 1, 4, -1, -1, -1 },
    { 1, 3, -1, -1, -1 },
    { 1, 2, -1, -1, -1 },
    { 1, 1, -1, -1, -1 },
    { 1, 2, 1, -1, -1 },
    { 2, 4, -1, -1, -1 },
    { 2, 1, -1, -1, -1 },
    { 2, 3, -1, -1, -1 },
    { 2, 4, 1, -1, -1 },
    { 2, 2, -1, -1, -1 },
    { 2, 1, 2, -1, -1 },
    { 2, 4, 3, 2, -1 },
    { 3, 4, -1, -1, -1 },
    { 3, 2, -1, -1, -1 },
    { 3, 3, -1, -1, -1 },
    { 3, 2, 4, -1, -1 },
    { 3, 1, -1, -1, -1 },
    { 3, 2, 3, 4, -1 },
    { 3, 4, 2, 1, 3 }
};

/* Retirement/vacation picture; also shown from the Hall of Fame. */
vacation_snapshot(n, show_text)
int n, show_text;
{
    int t, kind, k, m;          /* t unused */

    kind = vacations[n][0];
    if (show_text) {
        gfx_fill_rect(g_gfx, 0, 0, 320, 200, 0);
        switch (kind) {
        case 0:
            strcpy(text_buf, "After a difficult few days it's time to head for the LaundroMat.");
            break;
        case 1:
            strcpy(text_buf, "Word of your latest case seems to have reached the secretarial pool.");
            break;
        case 2:
            strcpy(text_buf, "After a successful case, you deserve some time at the beach!");
            break;
        case 3:
            strcpy(text_buf, "You're feeling invincible, time to try your luck at the Casino!");
            break;
        }
        wrap_text_buffer(24);
        dossier_state = 1;
        text_window(text_buf, 0x40, 0x50);
        wait_retrace(120);
    }
    require_disk(kind <= 1 ? 4 : 3, 1L);
    open_catalog(kind <= 1 ? "final4.cat" : "final3.cat");
    icon_page->page = 2;
    drv_begin_image_grab();
    strcpy(text_buf, vacation_prefix[kind]);
    strcat(text_buf, "back.pic");
    load_picture_swapped(text_buf, 2);
    vacation_back = drv_get_image(2, 0, 0, 320, 200);
    strcpy(text_buf, vacation_prefix[kind]);
    strcat(text_buf, "hand");
    strcat(text_buf, (options & 2) ? "f.pic" : "m.pic");
    load_picture_swapped(text_buf, 2);
    vacation_frames[0] = drv_get_image(2, 0, 0, 320, 200);
    play_sound(kind + 40);
    vacation_extra = 0;
    if (kind <= 1 && random(3)) {
        load_picture_swapped("laudude1.pic", 2);
        vacation_extra = drv_get_image(2, 0, 0, 320, 200);
    }
    drv_draw_image(icon_page, 0, 0, vacation_back);
    if (vacation_extra) drv_draw_image(icon_page, 0, 0, vacation_extra);
    drv_draw_image(icon_page, 0, 0, vacation_frames[0]);
    drv_copy_rect(icon_page, 0, 0, 320, 200, g_gfx, 0, 0);
    for (k = 1; k <= 4; k++) {
        if (vacations[n][k] != -1) {
            strcpy(text_buf, vacation_prefix[kind]);
            strcat(text_buf, (options & 2) ? "dude" : "babe");
            strcat(text_buf, itoa(vacations[n][k], vacation_num_buf, 10));
            strcat(text_buf, ".pic");
            load_picture_swapped(text_buf, 2);
            vacation_frames[k] = drv_get_image(2, 0, 0, 320, 200);
            drv_draw_image(icon_page, 0, 0, vacation_back);
            for (m = 1; m <= k; m++)
                drv_draw_image(icon_page, 0, 0, vacation_frames[m]);
            drv_draw_image(icon_page, 0, 0, vacation_frames[0]);
            drv_slot9(2);
            drv_copy_rect(icon_page, 0, 0, 320, 200, g_gfx, 0, 0);
            drv_gate_slot30(0);
        }
    }
    drv_end_image_grab();
    close_catalog();
    _dos_freemem(vacation_back);
}

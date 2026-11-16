/* SCREENS.C - Covert Action strategic layer (GAME.EXE): the hotel, the CIA
 * building and the data-file screens (organization/city summaries, suspects,
 * coded messages).
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "game.h"

/* Wait at the hotel: let time pass until something happens or a key is pressed. */
hotel_rest()
{
    in_building = 1;
    while (!city_exit) {
        if (kbhit()) break;
        process_events(60, 0, 0);
    }
    in_building = 0;
}

hotel_screen()
{
    int p, i, old_options, choice;

    do {
        load_picture_swapped("hotel.pic", 0);
        strcpy(text_buf, "You are at your\nhotel. Do you...\n Leave Hotel\n Visit the lounge\n Sleep through case\n Save Game\n Load Game\n \n Quit\n");
        switch (choice = show_menu(text_buf, 0x10, 0x28)) {
        case -1:
        case 0:
            return;
        case 2:
            hotel_rest();
            break;
        case 1:
            text_buf[0] = 0;
            show_prose("*lounge", 0x20);
            show_menu(text_buf, 0x14, 0x50);
            for (i = 0; i < num_suspects; i++) {
                p = suspects[i].person;
                if (persons[p].city == here_city && !(suspects[i].flags & 0x100))
                    reveal_random_clue(i, 0, here_city);
            }
            raise_alertness(0, here_city, 0x14);
            break;
        case 3:
            options &= ~0x40;
            *(int far *)(ENV + 0x50) = difficulty;
            save_game_menu();
            break;
        case 4:
            old_options = options;
            load_game_menu();
            options = old_options & 0x10 | options & ~0x10;
            advance_time(0);
            break;
        case 6:
            city_exit = -1;
            break;
        }
    } while (!city_exit);
}

data_files_menu()
{
    int choice;

    do {
        clear_screen();
        draw_sprite_a(0x65, 0x40, 4);
        strcpy(text_buf, "Data Files...\n Clues\n Suspects\n Inside Information\n News Bulletins\n");
        strcat(text_buf, " Organization Summaries\n City Summaries\n Activity Reports\n");
        choice = show_menu(text_buf, 0x14, 0x1f);
        clear_screen();
        switch (choice) {
        case 0:
            suspects_overview(-1);
            break;
        case 1:
            suspect_files_screen();
            break;
        case 2:
            documents_screen();
            break;
        case 3:
            chronology_screen(0, 0);
            break;
        case 4:
            organization_summary();
            break;
        case 5:
            city_summary();
            break;
        case 6:
            activity_report();
            break;
        }
    } while (choice != -1);
}

cia_hq_screen()
{
    int sub, k, found, item;

    if (last_exit == 2) {
        if (ENV[9]) {
            coded_messages_screen();
            show_decoded_message((char)ENV[8]);
        }
        advance_time((char)ENV[10] * 30);
        last_exit = 0;
    }
    for (;;) {
        clear_screen();
        strcpy(text_buf, "You are in the CIA building.\nWhich floor ?\n 1. Data Section\n 2. Intelligence Section\n 3. Crypto Branch\n Leave building\n");
        switch (item = show_menu(text_buf, 8, 0x15)) {
        case -1:
            return;
        case 1:
            do {
                drv_set_color_map(intel_colors, intel_colors);
                set_scene_background("comm.pan", 0xa8, 0);
                strcpy(text_buf, "Intelligence Section...\n Local Scan\n International Scan\n Active Wire Taps\n Accuse Double Agent\n Check with Sam\n");
                switch (sub = show_menu(text_buf, 0x14, 0x15)) {
                case 0:
                    if (!describe_new_info(1, here_city, 100, 0, 0)) {
                        clear_play_area();
                        show_menu("No new information\n", 0x14, 0x29);
                    }
                    advance_time(240);
                    break;
                case 1:
                    found = 0;
                    for (k = 0; k < 4; k++) {
                        advance_time(60);
                        found += describe_new_info(1, random(16), 50, 0, 0);
                    }
                    if (!found) {
                        clear_play_area();
                        show_menu("No new information\n", 0x14, 0x29);
                    }
                    break;
                case 2:
                    wiretaps_screen();
                    break;
                case 3:
                    if (mole_cities & 1 << here_city) {
                        strcpy(text_buf, "The local agent confesses\nand is replaced.\n");
                        strcat(text_buf, "You search his files\nfor additional information...\n");
                        show_menu(text_buf, 0x14, 0x14);
                        mole_cities -= 1 << here_city;
                        for (k = 0; k < 3; k++)
                            if (describe_new_info(1, here_city, 100, 0, 0))
                                break;
                    } else {
                        strcpy(text_buf, "The local agent is checked\nand proved innocent.\nYou are barred from\nusing the local office.\n");
                        show_menu(text_buf, 0x14, 0x14);
                        clear_location(1, here_city);
                        return;
                    }
                    break;
                case 4:
                    research_office();
                    break;
                }
            } while (sub != -1);
            break;
        case 0:
            do {
                drv_set_color_map(data_colors, data_colors);
                set_scene_background("research.pan", 0xa8, 0);
                strcpy(text_buf, "Data Section...\n Review Clues\n Review Suspects\n Inside Information\n News Bulletins\n");
                strcat(text_buf, " Organization Summary\n City Summary\n Activity Reports\n");
                switch (sub = show_menu(text_buf, 0x14, 0x15)) {
                case 0:
                    suspects_overview(-1);
                    break;
                case 1:
                    suspect_files_screen();
                    break;
                case 2:
                    documents_screen();
                    break;
                case 3:
                    chronology_screen(0, 0);
                    break;
                case 4:
                    organization_summary();
                    break;
                case 5:
                    city_summary();
                    break;
                case 6:
                    activity_report();
                    break;
                }
            } while (sub != -1);
            break;
        case 2:
            do {
                drv_set_color_map(crypto_colors, crypto_colors);
                set_scene_background("crypto.pan", 0xa8, 0);
                strcpy(text_buf, "Crypto Branch...\n Coded Messages\n Crime Chronology\n");
                switch (sub = show_menu(text_buf, 0x14, 0x15)) {
                case 0:
                    if (!last_exit) {
                        ENV[8] = 0xFF;
                        coded_messages_screen();
                        if (ENV[8] != 0xFF)
                            city_exit = 2;
                    }
                    break;
                case 1:
                    chronology_screen(1L);
                    break;
                }
            } while (sub != -1 && !city_exit);
            break;
        case 3:
            return;
        }
        if (!city_exit)
            continue;
        return;
    }
}

activity_report()
{
    int osum, csum, i, y;

    draw_bevel_box(0, 0, 0x13f, 0xc7, 1);
    csum = osum = 0;
    for (i = 0; i < 16; i++) {
        csum += city_clue_count[i];
        osum += org_clue_count[i];
    }
    draw_text("Activity Report Summary", 0x60, 6, 0xf);
    for (y = 0x14, i = 0; i < 16; y += 8, i++) {
        draw_text(cities[i].name, 2, y, is_cga ? 0xf : 3);
        gfx_fill_rect(g_gfx, 0x52, y + 1, 0xa0 * city_clue_count[i] / csum, 6, 0xb);
        if (i) {
            draw_text(orgs[i].abbrev, 0xa2, y - 8, 0xc);
            gfx_fill_rect(g_gfx, 0xf2, y - 7, 0xa0 * org_clue_count[i] / osum, 6, 0xe);
        }
    }
    wait_key_or_button();
}

wiretaps_screen()
{
    int i, found;

    draw_page_frame("WireTaps", 7);
    strcpy(text_buf, "");
    found = 0;
    for (i = 0; i < num_sites; i++) {
        if (sites[i].strength > 1) {
            strcat(text_buf, orgs[sites[i].org].name);
            strcat(text_buf, "/");
            strcat(text_buf, cities[sites[i].city].name);
            strcat(text_buf, " ... ");
            strcat(text_buf, itoa(sites[i].strength, num_str, 10));
            strcat(text_buf, "%\n");
            found = 1;
        }
    }
    if (!found)
        strcat(text_buf, "none \n");
    show_menu(text_buf, 0x32, 0x15);
}

organization_summary()
{
    int tmp, dist, i, o, empty;

    for (;;) {
        strcpy(text_buf, "Which organization ...\n");
        menu_count = 0;
        append_org_name();
        clear_play_area();
        if ((o = show_menu(text_buf, 0x10, 0x15)) == 0xffff)
            break;
        o = menu_items[o];
        draw_page_frame(orgs[o].name, 0xc);
        draw_text_centered(orgs[o].name, 0xa0, 0x10, 5);
        empty = 1;
        strcpy(text_buf, "Allies: \n ");
        for (i = 1; i < 16; i++) {
            if (city_distance(orgs[o].home, orgs[i].home) < 8 && i != o) {
                strcat(text_buf, orgs[i].name);
                strcat(text_buf, "\n ");
            }
        }
        if (empty == 1)
            strcat(text_buf, "none");
        dossier_state = 1;
        show_menu(text_buf, 0x14, 0x17);
        strcpy(text_buf, "Known Locations:\n-");
        for (i = 0; i < 16; i++) {
            if (org_alert_level(i, o) && cities[i].orgs_known & 1 << o
                && sites[set_location_known(o, i, 0)].flags & 4) {
                append_building_type(i, o);
                strcat(text_buf, " in ");
                strcat(text_buf, cities[i].name);
                strcat(text_buf, "\n-");
            }
        }
        dossier_state = 1;
        show_menu(text_buf, 0x90, 0x17);
        draw_line(0x18, 0x19, 0x127, 0x19, 4);
        empty = 1;
        strcpy(text_buf, "Associates: \n ");
        for (i = 1; i < 16; i++) {
            dist = city_distance(orgs[o].home, orgs[i].home);
            if (dist >= 8 && dist < 12 && i != o) {
                strcat(text_buf, orgs[i].name);
                strcat(text_buf, "\n ");
            }
        }
        if (empty == 1)
            strcat(text_buf, "none");
        menu_flag = 1;
        show_menu(text_buf, 0x14, 0x67);
    }
}

append_org_name()
{
    int i;

    for (i = 1; i < 16; i++) {
        if (LOBYTE(orgs[i].flags) & 1) {
            strcat(text_buf, " ");
            strcat(text_buf, orgs[i].name);
            strcat(text_buf, "\n");
            menu_items[menu_count++] = i;
        }
    }
}

city_summary()
{
    int tmp, any, i, j, loc;

    for (;;) {
        clear_play_area();
        strcpy(text_buf, "Which city ...\n");
        menu_count = 0;
        append_city_name();
        if ((loc = show_menu(text_buf, 0x14, 0x15)) == 0xffff)
            break;
        loc = menu_items[loc];
        draw_page_frame(cities[loc].name, 2);
        draw_text_centered(cities[loc].name, 0xa0, 0xf, 5);
        any = 0;
        strcpy(text_buf, "Known Locations:\n-");
        for (i = 1; i < 16; i++) {
            if (!org_alert_level(loc, i))
                continue;
            if (set_location_known(i, loc, 0) == -1)
                continue;
            if (sites[set_location_known(i, loc, 0)].flags & 4) {
                strcat(text_buf, orgs[i].name);
                append_building_type(loc, i);
            } else
                strcat(text_buf, "Unknown building.");
            strcat(text_buf, "\n-");
            any = 1;
        }
        if (!any)
            strcat(text_buf, "none\n");
        dossier_state = 1;
        show_menu(text_buf, 0xa0, 0x19);
        any = 0;
        strcpy(text_buf, "Suspects:\n-");
        for (i = 0; i < 64; i++) {
            if (persons[i].known & 8 && persons[i].city == loc) {
                append_person_name(i);
                if (persons[i].known & 4) {
                    strcat(text_buf, "/");
                    strcat(text_buf, orgs[persons[i].org].abbrev);
                }
                for (j = 0; j < num_suspects; j++) {
                    if (persons[i].roles & 1 << j) {
                        strcat(text_buf, "\n... \214");
                        strcat(text_buf, suspects[j].name);
                    }
                }
                strcat(text_buf, "\n- ");
                any = 1;
            }
        }
        if (!any)
            strcat(text_buf, "none\n");
        dossier_state = 1;
        show_menu(text_buf, 0x14, 0x19);
        draw_line(0x18, 0x19, 0x127, 0x19, 10);
        any = 0;
        strcpy(text_buf, "Clues:\n");
        for (i = 0; i < 80; i++) {
            if (clues[i].kind >> 8 == 8 && (clues[i].kind & 0xff) == loc) {
                strcat(text_buf, "-");
                describe_person(i);
                strcat(text_buf, "\n");
                any = 1;
            }
        }
        if (!any)
            strcat(text_buf, "none\n");
        wrap_text_buffer(16);
        show_menu(text_buf, 0x14, 0x71);
        clear_play_area();
    }
}

append_city_name()
{
    int i;

    for (i = 0; i < 16; i++) {
        strcat(text_buf, " ");
        strcat(text_buf, cities[i].name);
        strcat(text_buf, "\n");
        menu_items[menu_count++] = i;
    }
}

documents_screen()
{
    int i, item;

    do {
        draw_page_frame("Documents", 7);
        strcpy(text_buf, "Select Document:\n ");
        menu_items[0] = -1;
        menu_count = 1;
        for (i = 0; i < 16; i++) {
            if (!(seen_orgs & 1 << i))
                continue;
            menu_items[menu_count++] = i;
            switch (i) {
            case 0:
                strcat(text_buf, "Master Plan\n ");
                break;
            default:
                strcat(text_buf, orgs[i].name);
                strcat(text_buf, " Personel File\n ");
                break;
            }
        }
        if (menu_count == 1) {
            strcat(text_buf, "none \n");
            menu_items[1] = -1;
        }
        if ((item = menu_items[show_menu(text_buf, 0x14, 0x17) + 1]) != 0xffff)
            show_master_plan(item, 0, 0);
    } while (item != -1);
}

suspect_files_screen()
{
    int a, sel, who;

    for (;;) {
        draw_page_frame("Suspect Files", 7);
        menu_count = 1;
        menu_items[0] = -1;
        if ((sel = list_suspects()) == 0xffff)
            break;
        suspect_dossier(sel, 0, 0);
        wait_key_or_button();
    }
}

list_suspects()
{
    int a, b, s, i, flag, k;

    strcpy(text_buf, " ");
    for (i = 0; i < num_persons; i++) {
        if (persons[i].known) {
            append_person_name(i);
            if (persons[i].known & 4) {
                strcat(text_buf, " of the ");
                strcat(text_buf, orgs[persons[i].org].abbrev);
            }
            if (persons[i].known & 8) {
                strcat(text_buf, " in ");
                strcat(text_buf, cities[persons[i].city].name);
            }
            strcat(text_buf, ".\n ");
            flag = 0;
            for (k = 0; k < 15; k++) {
                if (persons[i].roles & 1 << k) {
                    strcat(text_buf, "\214 ");
                    strcat(text_buf, suspects[k].name);
                    strcat(text_buf, " ");
                    flag = 1;
                }
            }
            if (persons[i].fate == -1) {
                strcat(text_buf, "(Arrested)");
                flag = 1;
            }
            if (persons[i].fate == -2) {
                strcat(text_buf, "(Hiding)");
                flag = 1;
            }
            if (persons[i].fate == -3) {
                strcat(text_buf, "(Turned)");
                flag = 1;
            }
            if (persons[i].fate == -4) {
                strcat(text_buf, "(In Custody)");
                flag = 1;
            }
            menu_items[menu_count++] = i;
            if (flag) {
                strcat(text_buf, "\n ");
                menu_items[menu_count++] = i;
            }
        }
    }
    if (menu_count == 1) {
        strcat(text_buf, "none \n");
        menu_items[menu_count] = -1;
    }
    return menu_items[show_menu(text_buf, 10, 0x11) + 1];
}

coded_messages_screen()
{
    char txt[64];
    int md, r, top, idx, f, msg, row, y, z;

    draw_page_frame("Coded Messages", 7);
    menu_count = 1;
    menu_items[0] = -1;
    top = 2;
    f = 2;
    strcpy(text_buf, " ");
    for (msg = 0; msg < num_msgs; msg++) {
        md = msgs[msg].msg;
        if (msgs[msg].type == 0 && msgs[msg].flags != 0) {
            if ((plots[md].flags & 0xf00) == 0x200 || (plots[md].flags & 0xf00) == 0x300 || md < 0) {
                if (!(msgs[msg].flags & 0x8000)) {
                    append_person_name((char)msgs[msg].sender);
                    strcat(text_buf, " ");
                    row = strlen(text_buf);
                    format_message_event(msg);
                    strcpy(txt, text_buf + row + 11);
                    while (text_width(txt) > 0x124)
                        txt[strlen(txt) - 1] = 0;
                    text_buf[row + 11] = 0;
                    strcat(text_buf, "\n ...");
                    strcat(text_buf, txt);
                    strcat(text_buf, "\n ");
                    menu_items[menu_count++] = msg;
                    menu_items[menu_count++] = msg;
                }
            }
        }
    }
    if (last_exit)
        return;
    if (menu_count == 1) {
        strcat(text_buf, " none\n");
        menu_items[menu_count] = -1;
    }
    if ((msg = menu_items[show_menu(text_buf, 10, 0xf) + 1]) != 0xffff) {
        ENV[8] = msg;
        compose_intercept_text(msg);
        for (idx = 0; idx < 0x200; idx++)
            ENV[0x200 + idx] = text_buf[idx];
    }
}

show_decoded_message(n)
int n;
{
    int turned, role, msg, tt, src, z, j, k, prev, who, evt, tgt;

    draw_teletype_paper();
    draw_text_transparent("Message Decode", 0x78, 0x12, 5);
    msg = msgs[n].msg;
    role = plots[msg].flags & 0xff;
    src = msgs[n].sender;
    tgt = msgs[n].receiver;
    if (msg >= 0) {
        turned = 0;
        if ((plots[msg].flags & 0xf00) == 0x300) {
            tt = src;
            src = tgt;
            tgt = tt;
            turned = 1;
        }
        for (j = 0; j < num_msgs; j++) {
            if (msgs[n].time == msgs[j].time) {
                for (k = 0; k < 2 - difficulty; k++) {
                    prev = msgs[j].flags;
                    do
                        msgs[j].flags |= 1 << random(4);
                    while (msgs[j].flags == prev && (prev & 0xe) != 0xe);
                }
                if (!(msgs[j].flags & 0xe))
                    msgs[j].flags |= 2;
                if (j != n)
                    who = j;
            }
        }
        persons[msgs[n].sender].known |= msgs[who].flags & 0xe;
        persons[msgs[who].sender].known |= msgs[n].flags & 0xe;
        persons[msgs[n].sender].roles |= 1 << plots[msg].suspect;
        persons[msgs[n].receiver].roles |= 1 << role;
        msgs[n].flags |= persons[msgs[who].sender].known & 0xe;
        msgs[who].flags |= persons[msgs[n].sender].known & 0xe;
    } else {
        persons[src].roles |= persons[src].flags & 0x7fff;
        persons[tgt].roles |= persons[tgt].flags & 0x7fff;
        who = n;
    }
    draw_text_transparent("FROM:", 0x20, 0x30, 5);
    draw_text_transparent("TO:", 0xa0, 0x30, 5);
    if (persons[src].known)
        suspect_dossier(src, 0x20, 0x38);
    if (persons[tgt].known)
        suspect_dossier(tgt, 0xa0, 0x38);
    draw_text_transparent("MESSAGE:", 0x20, 0x77, 5);
    text_buf[0] = 0;
    load_message_text(msg);
    draw_wrapped_text(0x1e, 0x20, 0x7f, 0);
    screen_width = 0x140;
    wait_key_or_button();
    msgs[n].flags |= 0x8000;
    msgs[who].flags |= 0x8000;
}

truncate_text_to_width(w)
int w;
{
    while (text_width(text_buf) > w)
        text_buf[strlen(text_buf) - 1] = 0;
}

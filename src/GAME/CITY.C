/* CITY.C - Covert Action main game (GAME.EXE): the city screen and the
 * buildings in it (break in, wiretap, watch), CIA contacts, successful
 * missions, interrogations, prose.dta passages, capture and the prisoner
 * exchange.
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "game.h"

city_loop(city)
int city;
{
    int orgd, choice, sitev, j, unusedv, i, evx, whos;

    do {
        status_y = 0xAE;
        if (last_exit == 0 && jailbreak_person != -1) {
            drv_set_color_map(jail_colors, jail_colors);
            set_scene_background("warning.pan", 0xA8, 0);
            strcpy(text_buf, "JailBreak in ");
            strcat(text_buf, cities[persons[jailbreak_person].city].name);
            strcat(text_buf, "!\n");
            strcat(text_buf, orgs[persons[jailbreak_person].org].name);
            strcat(text_buf, " agents\nare trying to\nfree ");
            append_person_name(jailbreak_person);
            strcat(text_buf, "!\n");
            show_menu(text_buf, 16, 21);
            persons[jailbreak_person].known |= 0x40;
            ENV[12] = jailbreak_person;
            jailbreak_person = -1;
            city_exit = 8;
            here_org = 1;
            return;
        }
        if (last_exit == 8) {
            whos = (char)ENV[12];
            if (ENV[8] == 0xFF) {
                drv_set_color_map(bustout_colors, bustout_colors);
                set_scene_background("bustout.pan", 0xA8, 0);
                set_scene_var(0, (persons[whos].id & 1) ? -1 : 1);
                append_person_name(whos);
                strcat(text_buf, " escapes!\n");
                persons[whos].fate = 99;
                persons[whos].known |= 0x40;
                clear_location(persons[whos].org, persons[whos].city);
                add_chronology_entry(10, whos);
            } else {
                clear_play_area();
                strcat(text_buf, "Escape attempt foiled!\n");
            }
            show_menu(text_buf, 20, 21);
            last_exit = 0;
        }
        if (last_exit == 12) {
            raise_alertness(here_org, here_city, (char)ENV[9] * 25);
            if ((char)ENV[8] >= 25) {
                set_location_known(here_org, city, 8);
                strcpy(text_buf, "Your car tracer leads\nyou to a new building.\n");
                show_menu(text_buf, 16, 120);
            } else
                last_exit = 0;
        }
        if (last_exit == 3) {
            if (ENV[9] == 1)
                set_location_known(here_org, city, 8);
            else
                last_exit = 0;
            if (ENV[9] == 2)
                interrogate_suspect((char)ENV[8]);
            raise_alertness(here_org, city, (char)ENV[10]);
        }
        if (last_exit == 6) {
            if (ENV[9]) {
                clear_screen();
                text_buf[0] = 0;
                show_prose("*carcap", 32);
                show_menu(text_buf, 20, 32);
                ENV[12] = here_org;
                city_exit = 10;
                return;
            }
            here_org = (char)ENV[14];
            heat = 0;
            last_exit = 3;
        }
        if (last_exit == 7) {
            if (ENV[8] == 0xFF)
                captured_screen();
            if (city_exit)
                return;
            last_exit = 0;
        }
        if ((!(ENV[10] & 2) && ENV[8] != 0xFF && last_exit == 1 || last_exit == 7
             || last_exit == 10 && ENV[8] != 0xFF) && ENV[11]) {
            drv_set_color_map(wounded_colors, wounded_colors);
            set_scene_background("wounded.pan", 0xE0, 0);
            strcpy(text_buf, "You take time\nto recover from\nyour wounds\n");
            show_menu(text_buf, 20, 21);
            for (i = 0; i < (char)ENV[11]; i++)
                for (j = 0; j < 6; j++)
                    advance_time(60);
            if (last_exit != 10)
                last_exit = 0;
        }
        if (last_exit == 10) {
            orgd = (char)ENV[12];
            heat = 0;
            whos = pick_clue(orgd, city, 0, 0, 0);
            if (whos != -1 && persons[whos].fate > 0)
                persons[whos].fate = 0;
            if (ENV[8] == 0xFF) {
                if (!difficulty) {
                    text_buf[0] = 0;
                    show_prose("*surpriseL", 32, orgs[orgd].name);
                    show_menu(text_buf, 20, 32);
                } else {
                    here_org = orgd;
                    captured_screen();
                    if (city_exit)
                        return;
                }
            } else {
                text_buf[0] = 0;
                show_prose("*surpriseW", 32, orgs[orgd].name);
                show_menu(text_buf, 20, 32);
                set_location_known(orgd, here_city, 12);
            }
            last_exit = 0;
        }
        for (;;) {
            clear_screen();
            clear_pending = -1;
            if (last_exit == 0)
                load_city_picture(here_city, 240, 140);
            g_gfx->fillcolor = 5;
            advance_time(0);
            strcpy(text_buf, "You are in ");
            strcat(text_buf, cities[here_city].name);
            strcat(text_buf, "\nDo you go to ...\n");
            strcat(text_buf, " The Airport.\n");
            strcat(text_buf, " Your Hotel.\n ");
            menu_count = 2;
            for (i = 1; i < 16; i++) {
                sitev = set_location_known(i, city, 0);
                if (sitev != -1) {
                    menu_items[menu_count++] = i;
                    if (sites[sitev].flags & 4) {
                        strcat(text_buf, orgs[i].name);
                        append_building_type(city, i);
                    } else
                        strcat(text_buf, "unknown building");
                    strcat(text_buf, "\n ");
                }
            }
            i = 0;
            do {
                if (clues[i].suspect != -1) {
                    evx = clues[i].suspect;
                    if (clues[i].text >> 8 == 2 && clues[i].kind >> 8 == 8
                        && persons[suspects[evx].person].city == here_city) {
                        append_number(clues[i].text);
                        strcat(text_buf, "\n ");
                        menu_items[menu_count++] = persons[suspects[evx].person].org;
                    }
                }
                i++;
            } while (i < 80);
            strcat(text_buf, "Check Data\n");
            menu_items[menu_count] = -1;
            if (last_exit == 0) {
                choice = show_menu(text_buf, 16, 9);
                whos = persons[suspects[random(num_suspects)].person].org;
                if (difficulty && choice > 2 && choice < menu_count
                    && describe_alert_level(whos, here_city) > ((mole_cities & (1 << here_city)) ? 20 : 50)) {
                    ENV[12] = whos;
                    city_exit = 10;
                    heat = 0;
                    clear_screen();
                    text_buf[0] = 0;
                    show_prose("*surprise", 16);
                    show_menu(text_buf, 24, 31);
                    return;
                }
            } else switch (last_exit) {
            case 1: case 3: case 4: case 12: case 99:
                choice = 2;
                menu_items[2] = here_org;
                break;
            case 2:
                choice = 2;
                menu_items[2] = 1;
                break;
            }
            if (choice == menu_count)
                data_files_menu();
            else
                break;
        }
        if (choice == 1)
            hotel_screen();
        else if (last_exit != 1 || !(ENV[10] & 2))
            advance_time(120);
        if (choice > 1 && (here_org = menu_items[choice]) != 0)
            building_screen();
    } while (choice > 0 && !city_exit);
}

building_screen()
{
    int tmpn, orgg, len, sitej, btypek, junkg, extrak, lvl, spare, cityb, choice, scorex;

    left_building = 0;
    do {
        if (last_exit == 3 || last_exit == 12 || last_exit == 99)
            last_exit = 0;
        cityb = here_city;
        orgg = here_org;
        cia_proximity = clamp(99 - city_distance(orgs[1].home, orgs[orgg].home) * 6, 0, 99);
        if (orgg == 1)
            choice = -2;
        else {
            strcpy(text_buf, "You are at the\n");
            lvl = set_location_known(orgg, cityb, 0);
            if (sites[lvl].flags & 4) {
                strcat(text_buf, orgs[orgg].name);
                btypek = append_building_type(cityb, orgg);
            } else
                strcat(text_buf, "unknown building");
            len = strlen(text_buf);
            lvl = describe_alert_level(orgg, cityb);
            text_buf[len] = 0;
            switch (lvl / 16) {
            case 1:
                strcat(text_buf, "\nA few guards are\npeering through the\nwindows.");
                break;
            case 2:
                strcat(text_buf, "\nIt appears extra\nguards have been\nposted.");
                break;
            case 0:
                break;
            default:
                strcat(text_buf, "\nThe building is\nswarming with guards.");
            }
            strcat(text_buf, "\nDo you ...\n Place wiretap\n");
            strcat(text_buf, " Break into building\n");
            strcat(text_buf, " Watch the building\n Check Data\n Leave\n");
            g_gfx->fillcolor = 5;
            if (last_exit == 0) {
                strcpy(scene_name, "blding01.pan");
                btypek = clamp(btypek - 2, 0, 3);
                scene_name[7] = btypek + '1';
                status_y = 4;
                drv_set_color_map(building_colors[btypek], building_colors[btypek]);
                set_scene_background(scene_name, 0, 0);
                set_scene_var(10, clamp(lvl / 16 + 1, 1, 4));
                choice = show_menu(text_buf, 2, 33);
            } else switch (last_exit) {
            case 1:
                choice = 1;
                break;
            case 3: case 4:
                choice = 0;
                break;
            }
        }
        switch (choice) {
        case -2:
            cia_contact_screen(orgg, cityb);
            left_building = 1;
            break;
        case 2:
            watch_building(orgg, cityb);
            if (here_org == 1)
                left_building = 1;
            break;
        case 1:
            if (last_exit == 0 && first_visit) {
                status_y = 4;
                advance_time(60);
                city_exit = 1;
                load_picture_swapped("sneakin.pic", 1);
                drv_slot9(1);
                if (cur_drive < 2)
                    wait_retrace(60);
            } else {
                success_briefing(orgg, cityb);
                last_exit = 0;
            }
            break;
        case 0:
            if (last_exit == 0 && first_visit) {
                load_picture_swapped("wiretap.pic", 0);
                strcpy(text_buf, "The guards are ");
                lvl = describe_alert_level(orgg, cityb);
                lvl = clamp(10 - lvl / 5, 2, 10);
                strcat(text_buf, ".\nYou will have ");
                strcat(text_buf, itoa(lvl, scene_name, 10));
                strcat(text_buf, " minutes.\n");
                dossier_state = 1;
                show_menu(text_buf, 20, 20);
                city_exit = 4;
            } else {
                last_exit = 0;
                if (first_visit) {
                    scorex = (char)ENV[8];
                    raise_alertness(here_org, here_city, (char)ENV[9] * 50);
                }
                if (scorex) {
                    sitej = set_location_known(orgg, cityb, 4);
                    sites[sitej].strength += scorex;
                }
                advance_time(60);
            }
            break;
        case 3:
            data_files_menu();
            break;
        case -1: case 4:
            left_building = 1;
            if (difficulty && describe_alert_level(here_org, here_city) > 50) {
                set_scene_background("followed.pan", 0, 0);
                text_buf[0] = 0;
                show_prose("*followed", 32);
                show_menu(text_buf, 24, 0x91);
                drv_set_color_map(followed_colors, followed_colors);
                ENV[9] = here_org;
                city_exit = 6;
            }
            break;
        }
    } while (!left_building && !city_exit);
    if (here_org == 1 && (mole_cities & (1 << here_city)))
        raise_alertness(alert_org, here_city, 40);
}

cia_contact_screen(org, city)
int org, city;
{
    register unsigned bit;
    register unsigned *visited;
    int u1, u2, u3;

    if (last_exit == 0) {
        raise_alertness(org, city, 20);
        bit = 1 << here_org;
        visited = &cities[here_city].orgs_visited;
        if (!(*visited & bit))
            *visited |= bit;
        if (here_org == 1) {
            clear_screen();
            drv_set_color_map(hq_colors, hq_colors);
            if (!set_scene_background("hq.pan", 0xA8, 0))
                options &= ~8;
            if (!difficulty) {
                strcpy(text_buf, "You arrive at\nthe CIA building\nand check with\nyour contact.\n");
                show_menu(text_buf, 16, 17);
                research_office();
            }
        }
    }
    if (here_org == 1)
        cia_hq_screen();
    last_exit = 0;
}

watch_building(org, city)
int org, city;
{
    int best_orgj, selk, o, best, distj, who;

    for (;;) {
        gfx_fill_rect(g_gfx, 0, 0, 320, 200, 5);
        advance_time(random(2) * 60 + 60);
        do {
            best = 999;
            best_orgj = org;
            o = 1;
            do {
                if (org_alert_level(city, o)) {
                    distj = city_distance(orgs[org].home, orgs[o].home) + random(16);
                    if (org == 0)
                        distj = random(16);
                    who = pick_clue(o, city, 0, 0, 0);
                    if (who == -1 || persons[who].flags == 0)
                        distj += random(24);
                    if (cities[city].orgs_known & (1 << o))
                        distj += random(16);
                    if (distj < best && o != org) {
                        best = distj;
                        best_orgj = o;
                    }
                }
                o++;
            } while (o < 16);
            if (random(3) || !org)
                who = pick_clue(best_orgj, city, 9, 0, 0);
            else
                who = pick_clue(org, city, 9, 0, 0);
        } while (persons[who].fate < 0 || who == 0);
        portrait_x = 26;
        portrait_y = 45;
        face_shown = persons[who].id;
        drv_set_color_map(binos_colors, binos_colors);
        if (set_scene_background("binos3.pan", 150, 2))
            set_scene_var(0, (persons[who].id & 1) ? -1 : 1);
        else {
            gfx_fill_rect(g_gfx, 168, 8, 144, 96, 1);
            draw_face_parts(face_shown, 224, 32);
            draw_sprite_a((face_shown & 3) + 104, 214, 57);
        }
        strcpy(text_buf, "You notice someone");
        strcat(text_buf, "\nleaving the building.\n");
        strcat(text_buf, "Do you ...\n Wait\n Follow car.\n Trace car.\n Check Data\n");
        selk = show_menu(text_buf, 2, 20);
        switch (selk) {
        case -1:
            return;
        case 0: case 3:
            if (persons[who].known == 9)
                free_location_if_unused(who);
            if (selk == 3)
                data_files_menu();
            break;
        case 1:
            if (persons[who].id & 1)
                strcpy(text_buf, "He looks ");
            else
                strcpy(text_buf, "She looks ");
            describe_alert_level(persons[who].org, persons[who].city);
            strcat(text_buf, "\n.");
            dossier_state = 1;
            show_menu(text_buf, 20, 100);
            ENV[8] = who;
            ENV[9] = here_org;
            ENV[10] = persons[who].id & 1;
            city_exit = 3;
            here_org = best_orgj;
            return;
        case 2:
            drv_set_color_map(bugcar_colors, bugcar_colors);
            play_animation("bugcar.pan", 0, 0);
            city_exit = 12;
            here_org = best_orgj;
            return;
        default:
            return;
        }
    }
}

success_briefing(org, city)
int org, city;
{
    int tmpm, junkv, sitei, who, i, extra, sparei, scorex;

    add_chronology_entry(5, (org << 8) + city);
    sitei = set_location_known(org, city, 12);
    orgs[org].flags |= 1;
    if (last_exit) {
        scorex = (char)ENV[8];
        raise_alertness(org, city, (char)ENV[9]);
    }
    who = pick_clue(org, city, 0, 0, 0);
    if (scorex == -1) {
        raise_alertness(org, city, 100);
        captured_screen();
    } else {
        if ((ENV[10] & 1) && who != -1) {
            i = 0;
            do {
                if (agents[i].person == who) {
                    drv_set_color_map(briefing_colors, briefing_colors);
                    set_scene_background("briefing.pan", 0, 0);
                    set_scene_var(0, 2);
                    strcpy(text_buf, "Good job Max, You found the\n");
                    strcat(text_buf, agents[i].name);
                    strcat(text_buf, "!. That should really\nslow down their operation.\n");
                    show_menu(text_buf, 16, 0x95);
                    success_briefing_text(i);
                }
                i++;
            } while (i < 4);
        }
        sites[sitei].strength += scorex;
        if (ENV[10] & 2)
            interrogate_suspect(who);
    }
}

interrogate_suspect(who)
int who;
{
    int tmpl, junke, m, evide, i, roleg, extra, dbl, sparev, pidd;
    char name[20];

    here_org = 1;
    portrait_x = 24;
    portrait_y = 37;
    face_shown = persons[who].id;
    drv_set_color_map(intrgate_colors, intrgate_colors);
    set_scene_background("intrgate.pan", 0xE0, 0);
    set_scene_var(0, (persons[who].id & 1) ? -1 : 1);
    dbl = ENV[13] == 0;
    strcpy(text_buf, "You accuse ");
    append_person_name(who);
    strcat(text_buf, "\nof taking part in\nthe plot, 'We know\nthat your role was:\n");
    if (dbl)
        persons[who].roles |= persons[who].flags & 0x7FFF;
    evide = 0;
    roleg = -1;
    for (i = 0; i < num_suspects - difficulty * 4; i++) {
        if (persons[who].roles & (1 << i)) {
            evide = 1;
            strcat(text_buf, suspects[i].name);
            strcat(text_buf, ".'\n");
        }
        if (suspects[i].person == who)
            roleg = i;
    }
    if (persons[who].org != 1 && !dbl)
        clear_location(persons[who].org, persons[who].city);
    if (!evide) {
        persons[who].fate = -1;
        strcpy(text_buf, "You have no evidence\nagainst ");
        append_person_name(who);
        strcat(text_buf, (persons[who].id & 1) ? ".\nHe" : ".\nShe");
        strcat(text_buf, " will have to\nbe released.\n");
        show_menu(text_buf, 16, 21);
        persons[who].fate = 99;
        raise_alertness(persons[who].org, persons[who].city, 99);
        add_chronology_entry(9, who);
        if (who == jailbreak_person)
            jailbreak_person = -1;
        return;
    }
    show_menu(text_buf, 16, 21);
    set_location_known(1, here_city, 12);
    text_buf[0] = 0;
    if (!dbl) {
        if (evide) {
            persons[who].fate = -1;
            show_prose("*inter1", 24);
        }
    } else {
        persons[who].fate = -3;
        show_prose("*doublea", 24);
    }
    add_chronology_entry(dbl ? 12 : 6, who);
    clear_play_area();
    show_menu(text_buf, 16, 21);
    for (m = 0; m < num_msgs; m++) {
        if (evide && msgs[m].type == 0 && msgs[m].sender == who
            && ((msgs[m].flags & 0xF) || difficulty < 2 || persons[who].fate == -3)
            && ((plots[msgs[m].msg].flags & 0x800) || (plots[msgs[m].msg].flags & 0x200))) {
            text_buf[0] = 0;
            show_prose("*inter2", 24);
            format_message_event(m);
            strcat(text_buf, ",\" you ask. ");
            if (bitcount[msgs[m].flags & 0x1F] >= difficulty * 2 || persons[who].fate == -3) {
                strcat(text_buf, "\"Oh yeah, I guess I did,\" the prisoner responds.\n");
                wrap_text_buffer(24);
                clear_play_area();
                show_menu(text_buf, 16, 21);
                drv_copy_rect(g_gfx, 224, 0, 96, 200, back_page, 224, 0);
                show_decoded_message(m);
                gfx_fill_rect(g_gfx, 0, 0, 224, 200, 5);
                drv_copy_rect(back_page, 224, 0, 96, 200, g_gfx, 224, 0);
                screen_width = 224;
            } else {
                strcat(text_buf, "\"Hmmm..., I don't seem to remember.\", the suspect responds.\n");
                wrap_text_buffer(24);
                clear_play_area();
                show_menu(text_buf, 16, 21);
            }
        }
    }
    persons[who].known |= 0x71F;
    if (dbl || persons[who].roles) {
        if (suspects[roleg].flags & 0x100) {
            strcpy(text_buf, "The MasterMind breaks down and lists the participants in the plot.");
            wrap_text_buffer(24);
            clear_play_area();
            show_menu(text_buf, 16, 21);
        }
        for (i = 0; i < num_suspects - difficulty * 4; i++) {
            if (suspects[i].person == who)
                suspects[i].found |= 0x1F;
            if (suspects[roleg].flags & 0x100) {
                pidd = suspects[i].person;
                persons[pidd].known |= 0x1F;
                persons[pidd].roles |= persons[pidd].flags & 0x7FFF;
                suspect_dossier(pidd, 0, 0);
                wait_key_or_button();
            }
        }
        if (!dbl) {
            clear_screen();
            portrait_x = 101;
            portrait_y = 19;
            face_shown = persons[who].id;
            drv_set_color_map(jail_colors2, jail_colors2);
            set_scene_background("injail.pan", 0xA8, 0);
            set_scene_var(0, (persons[who].id & 1) ? -1 : 1);
            text_buf[0] = 0;
            append_person_name(who);
            strcat(text_buf, "\nis taken to\nthe local jail.\n");
            show_menu(text_buf, 24, 21);
        }
        clear_screen();
        drv_set_color_map(briefing_colors, briefing_colors);
        set_scene_background("briefing.pan", 0, 0);
        set_scene_var(0, 2);
        text_buf[0] = 0;
        append_person_name(who);
        strcpy(name, text_buf);
        text_buf[0] = 0;
        show_prose("*nice0", 36, name, (suspects[roleg].rank - 1) / 3);
        wrap_text_buffer(40);
        show_menu(text_buf, 16, 0x95);
    }
    process_events(240, 1L);
}

show_prose(key, width, rplc, n)
char *key;
int width;
char *rplc;
int n;
{
    int len;

    len = strlen(key);
    if (key[len - 1] == '0')
        key[len - 1] += n;
    lookup_text("prose.dta", key, subst_keys, subst_vals, 1);
    prose_substitute("$RPLC", rplc);
    prose_substitute("$NAME", "Max Remington");
    prose_substitute("$CITY", cities[here_city].name);
    prose_substitute("$ORG", orgs[here_org].name);
    prose_substitute("$US", orgs[1].name);
    wrap_text_buffer(width);
}

/* Replace every KEY in text_buf with VAL. */
prose_substitute(key, val)
char *key, *val;
{
    char *p;
    char buf[256];

    do {
        if ((p = strstr(text_buf, key)) != 0) {
            strcpy(buf, p);
            *p = 0;
            strcat(text_buf, val);
            strcat(text_buf, buf + strlen(key));
        }
    } while (p);
}

/* The plot of an organization has been foiled: mark every plot sharing a
 * message with it as done. */
success_briefing_text(n)
int n;
{
    int cell;
    int pidx;
    int i;
    int j;
    int mask;

    mask = 1 << n;
    cell = -1;
    for (i = 0; i < num_msgs; i++) {
        if (msgs[i].type == 0) {
            pidx = msgs[i].msg;
            if (plots[pidx].items & mask) cell = plots[pidx].suspect;
            if (cell != -1 && plots[pidx].suspect == cell)
                for (j = 0; j < num_plots; j++)
                    if (plots[pidx].msg == plots[j].msg) plots[j].state = 999;
        }
    }
    add_chronology_entry(7, n);
    agents[n].person = -1;
}

captured_screen()
{
    int i;

    drv_set_color_map(capture_colors, capture_colors);
    set_scene_background("surndr01.pan", 0xe0, 0);
    text_buf[0] = 0;
    show_prose("*grilled", 0x18);
    if (!prisoner_exchange()) {
        for (i = 0; i < random(3) + 2; i++) {
            advance_time(360);
            if (jailbreak_person != -1) {
                clear_screen();
                drv_set_color_map(jail_colors, jail_colors);
                set_scene_background("warning.pan", 0xa0, 0);
                strcpy(text_buf, "JailBreak in ");
                strcat(text_buf, cities[persons[jailbreak_person].city].name);
                strcat(text_buf, "!\n");
                strcat(text_buf, orgs[persons[jailbreak_person].org].name);
                strcat(text_buf, " agents\nfree ");
                append_person_name(jailbreak_person);
                strcat(text_buf, "!\n");
                show_menu(text_buf, 0x10, 0x15);
                LOBYTE(persons[jailbreak_person].known) |= 0x40;
                persons[jailbreak_person].fate = 99;
                clear_location(persons[jailbreak_person].org, persons[jailbreak_person].city);
                add_chronology_entry(10, jailbreak_person);
                jailbreak_person = -1;
            }
        }
        drv_set_color_map(escape_colors, escape_colors);
        set_scene_background("escape.pan", 0xe0, 0);
        text_buf[0] = 0;
        show_prose("*escape", 0x18);
        show_menu(text_buf, 0x10, 0x15);
        city_exit = 7;
    } else {
        if (difficulty) clear_location(here_org, here_city);
        left_building = 1;
    }
}

prisoner_exchange()
{
    int p;
    int worth;
    int idx;
    int i;
    int rank;
    int who;

    p = -1;
    worth = 99;
    for (i = 0; i < num_suspects - difficulty * 4; i++) {
        who = suspects[i].person;
        rank = suspects[i].importance;
        for (idx = 0; idx < num_plots - 1; idx++)
            if (plots[idx].suspect == i && plots[idx].state == 999) rank -= 2;
        if (persons[who].fate == -1 && rank <= worth) {
            p = who;
            worth = rank;
        }
    }
    strcat(text_buf, " No thanks, Squinty.\n Agree to exchange.\n");
    if (show_menu(text_buf, 0x10, 0x15) == 1) {
        strcpy(text_buf, "You are exchanged\nfor ");
        if (p != -1) {
            append_person_name(p);
            strcat(text_buf, ".\n");
            persons[p].fate = 99;
            LOBYTE(persons[p].known) |= 0x40;
            clear_location(persons[p].org, persons[p].city);
            add_chronology_entry(13, p);
        } else {
            strcat(text_buf, "two double agents.\n");
            mole_cities |= 1 << random(16);
            mole_cities |= 1 << random(16);
        }
        show_menu(text_buf, 0x10, 0x79);
        return 1;
    }
    return 0;
}

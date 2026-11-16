/* TIME.C - GAME.EXE: the game clock and the daily world events (suspects
 * going into / coming out of hiding, message traffic, wiretaps, airport
 * sightings), the status bar, the clue overview screens and the research
 * office's advice.
 * Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style. */
#include "game.h"

advance_time(minutes)
int minutes;
{
    if (minutes == 0)
        draw_status_bar();
    while (minutes >= 60) {
        process_events(60, 0, 0);
        minutes -= 60;
        if (num_msgs > 5)
            wait_retrace(30);
    }
    if (minutes != 0)
        process_events(30, 0, 0);
}

int time_unused = 0;                    /* 3c84 never referenced */

/* The "il = 0;" at the end of each "if (nfa)" path (with "for (; il ...)")
 * is what the original does: C2 cross-jumps the copies into the first
 * branch's, so the rest of the else-if chain lands after "il = 0; jmp cond".
 * The chain's last three branches share one copy at the end of an else block;
 * with a copy in every branch C2 keeps the second branch's instead. */
process_events(minutes, force)
int minutes, force;
{
    int ncityi, rsl, odaye, ohourf, pado, nfa, hida, padb;
    int triesi, pa, locd, pij, movedi, il, kk, freee, td, padd, sidxb;

    ohourf = clock_hour;
    odaye = clock_day;
    clock_base += minutes;
    draw_status_bar();
    wait_retrace(2);
    if (!((ohourf < 12 && clock_hour >= 12) || odaye != clock_day || force))
        return;
    game_time++;
    for (il = 0; il < 16; il++)
        cities[il].orgs_visited = 0;
    for (pa = 0; pa < num_persons; pa++) {
        if (persons[pa].id != 0 && persons[pa].fate >= 0)
            persons[pa].fate -= persons[pa].fate / (difficulty + 3);
    }
    heat -= heat / (difficulty + 3);
    nfa = 0;
    hiding_target = -2;
    for (il = 0; il < num_plots - 1; il++) {
        if (check_out_of_hiding(il) != -1)
            nfa++;
    }
    if (random(10) >= difficulty + 4 && num_msgs > 5 && nfa != 0 && !force)
        return;
    if (nfa <= difficulty) {
        hiding_target = -1;
        for (il = 0; il < num_plots - 1; il++) {
            if (check_out_of_hiding(il) != -1) {
                nfa = 1;
                break;
            }
        }
    }
    hida = 0;
    for (;;) {
        triesi = 0;
        do {
            rsl = random(num_suspects - difficulty * 4);
            pa = suspects[rsl].person;
            if (persons[pa].fate >= 0 && pa != hiding_target)
                break;
            triesi++;
        } while (triesi < 999);
        if (triesi != 999 && num_msgs > 8
            && (persons[pa].city != here_city || persons[pa].org != here_org || in_building)) {
            freee = 1;
            for (il = 0; il < num_plots; il++) {
                if (suspects[plots[il].suspect].person == pa && plots[il].state == 999) {
                    freee = 0;
                    break;
                }
            }
            if ((freee || (nfa == 0 && hiding_target < 0)) && (!hida || !(persons[pa].known & 0xf))) {
                persons[pa].fate = -2;
                if (persons[pa].known != 0) {
                    strcpy(text_buf, "Bulletin: ");
                    append_person_name(pa);
                    strcat(text_buf, " has gone into hiding.\n");
                    incoming_message("Surveillance Team");
                }
                add_chronology_entry(8, pa);
                hida = 1;
                continue;
            }
        }
        break;
    }
    if ((triesi == 999 && nfa == 0) || clock_base > 40000) {
        mm_known = persons[0].known;
        save_env("env.sve");
        require_disk(1, 1L);
        set_exit_state();
        ENV[0] = 9;
        exit();
    }
    if (force)
        return;
    if (nfa) {
        do {
            pij = random(num_plots - 1);
            nfa = check_out_of_hiding(pij);
        } while (nfa == -1);
        if (!(plots[pij].flags & 0xfff)) {
            plots[pij].state = game_time;
            if (suspect_state[plots[pij].suspect].time == -1)
                suspect_state[plots[pij].suspect].time = game_time;
            il = 0;
        } else {
            if ((plots[pij].flags & 0x1000)
                && persons[suspects[plots[nfa].suspect].person].fate < 0) {
                plots[pij].state = 0;
            } else if (plots[nfa].state != 999) {
                plots[pij].state = plots[nfa].state;
            } else {
                plots[pij].state = game_time;
                if (suspect_state[plots[pij].suspect].time == -1)
                    suspect_state[plots[pij].suspect].time = game_time;
                plots[nfa].state = game_time;
                if (suspect_state[plots[nfa].suspect].time == -1)
                    suspect_state[plots[nfa].suspect].time = game_time;
                for (il = 0; il < num_plots; il++) {
                    if (plots[pij].msg == plots[il].msg && il != pij && il != nfa)
                        plots[il].state = -1;
                }
                if (suspects[plots[pij].suspect].person == suspects[plots[nfa].suspect].person) {
                    plots[pij].state = -1;
                    plots[nfa].state = -1;
                }
            }
            il = 0;
        }
    } else
        il = 0;
    for (; il < num_plots; il++) {
        if (plots[il].state == game_time) {
            add_chronology_entry(0, il);
            pa = suspects[plots[il].suspect].person;
            for (kk = 0; kk < 4; kk++) {
                if (plots[il].items & (1 << kk)) {
                    agents[kk].person = pa;
                    if (random(2) >= difficulty && !(plots[il].flags & 0x2000) && num_msgs > 5) {
                        strcpy(text_buf, "INTERPOL Bulletin:\n");
                        strcat(text_buf, agents[kk].name);
                        strcat(text_buf, " spotted in ");
                        strcat(text_buf, cities[persons[pa].city].name);
                        strcat(text_buf, "!\n");
                        incoming_message("INTERPOL");
                        add_chronology_entry(11, (kk << 8) + persons[pa].city);
                    }
                }
                if (plots[il].items & (0x100 << kk))
                    agents[kk].person = -1;
            }
            if (plots[il].flags & 0x2000) {
                text_buf[0] = 0;
                load_message_text(il);
                incoming_message("");
            } else {
                if ((plots[il].flags & 0xf00) == 0x200 && num_msgs > 5) {
                    strcpy(text_buf, "Message traffic detected.\n... ");
                    if (random(2)) {
                        strcat(text_buf, "FROM: ");
                        strcat(text_buf, cities[persons[pa].city].name);
                        city_clue_count[persons[pa].city]++;
                    } else {
                        strcat(text_buf, "TO: ");
                        strcat(text_buf, cities[persons[suspects[(int)(unsigned char)plots[il].flags].person].city].name);
                        city_clue_count[persons[suspects[(int)(unsigned char)plots[il].flags].person].city]++;
                    }
                    strcat(text_buf, " ...\n");
                    incoming_message("Satellite Intercept");
                }
                sidxb = set_location_known(persons[pa].org, persons[pa].city, 0);
                if (persons[pa].fate == -3 || (sidxb != -1 && random(50) < sites[sidxb].strength)) {
                    for (kk = 0; kk < num_msgs; kk++) {
                        if (msgs[kk].type == 0 && msgs[kk].msg == il && msgs[kk].time == clock_base) {
                            LOBYTE(msgs[kk].flags) |= 0xf;
                            HIBYTE(msgs[kk].flags) |= 0x80;
                            if (persons[pa].fate == -3) {
                                strcpy(text_buf, "Double Agent: ");
                                persons[msgs[kk].receiver].known |= 0xc;
                                persons[msgs[kk].receiver].roles |= 1 << plots[il].flags;
                            } else
                                strcpy(text_buf, "Wiretap at ");
                            strcat(text_buf, orgs[persons[pa].org].name);
                            strcat(text_buf, "/");
                            strcat(text_buf, cities[persons[pa].city].name);
                            strcat(text_buf, " reveals ");
                            if (persons[pa].fate == -3) {
                                if (persons[pa].id & 1)
                                    strcat(text_buf, "he ");
                                else
                                    strcat(text_buf, "she ");
                            } else {
                                append_person_name(pa);
                                strcat(text_buf, " ");
                            }
                            format_message_event(kk);
                            strcat(text_buf, "\n");
                            if ((plots[il].flags & 0xf00) == 0x800) {
                                load_message_text(il);
                                persons[msgs[kk].receiver].roles |= persons[msgs[kk].receiver].flags;
                            } else if (persons[pa].fate == -3)
                                load_message_text(il);
                            incoming_message("");
                        }
                    }
                }
                if ((plots[il].flags & 0xf00) == 0x900 && (persons[pa].known & 1)) {
                    for (kk = 0; kk < num_msgs; kk++) {
                        if (msgs[kk].type == 0 && msgs[kk].msg == il
                            && msgs[kk].sender_city != msgs[kk].receiver_city) {
                            strcpy(text_buf, "From: ");
                            strcat(text_buf, orgs[1].name);
                            strcat(text_buf, "/");
                            strcat(text_buf, cities[msgs[kk].sender_city].name);
                            strcat(text_buf, "\n");
                            append_person_name(pa);
                            strcat(text_buf, " has just returned from a trip to ");
                            strcat(text_buf, cities[msgs[kk].receiver_city].name);
                            strcat(text_buf, ".\n");
                            incoming_message("Airport Surveillance");
                            LOBYTE(msgs[kk].flags) |= 9;
                        }
                    }
                }
            }
        }
    }
    movedi = 0;
    for (il = 0; il < num_suspects; il++) {
        if (!movedi && (suspects[il].flags & 8)) {
            pa = suspects[il].person;
            if ((persons[pa].known & 8) && random(128 / (difficulty + 1)) < persons[pa].fate
                && persons[pa].city != here_city) {
                for (td = 0; td < 4; td++) {
                    ncityi = random(16);
                    if (org_alert_level(ncityi, persons[pa].org)) {
                        locd = pick_clue(persons[pa].org, ncityi, 0, 0, 0);
                        if (persons[locd].flags == 0 && persons[locd].known == 0) {
                            strcpy(text_buf, "");
                            append_person_name(pa);
                            strcat(text_buf, " seems to have departed from ");
                            strcat(text_buf, cities[persons[pa].city].name);
                            strcat(text_buf, ".\n");
                            incoming_message("Airport Surveillance");
                            add_chronology_entry(1, (pa << 8) + persons[pa].city);
                            free_location_if_unused(locd);
                            persons[pa].city = ncityi;
                            remove_location_type(pa, 8);
                            persons[pa].fate /= 2;
                            movedi = 1;
                            break;
                        }
                    }
                }
            }
        }
    }
}

remove_location_type(p, bits)
int p;
unsigned bits;
{
    int i;
    char sg;

    persons[p].known &= ~bits;
    persons[p].points /= 2;
    if (bits == 1)
        persons[p].known |= 0x80;
    for (i = 0; i < num_plots; i++) {
        sg = plots[i].suspect;
        if (suspects[sg].person == p) {
            suspects[sg].found &= ~bits;
            suspect_state[sg].progress /= 2;
        }
    }
    for (i = 0; i < 80; i++) {
        if (suspects[clues[i].suspect].person == p && clues[i].kind >> 8 == bits)
            clues[i].suspect = -1;
    }
}

check_out_of_hiding(n)
int n;
{
    int padk, a, b, padn, flagj, il, sto, resm, padc, bin, pade;

    if (plots[n].state != 999)
        return -1;
    a = suspects[plots[n].suspect].person;
    sto = persons[a].fate;
    if (sto == -3 && plots[n].severity != 0)
        return -1;
    for (il = 0; il < n; il++) {
        if (plots[il].state == 999 && plots[n].suspect == plots[il].suspect)
            return -1;
    }
    il = plots[n].suspect;
    if (!(plots[n].flags & 0xfff)) {
        if (num_msgs <= 5)
            return -1;
        sto = persons[a].fate;
        if (sto < 0 && sto != -3) {
            check_special_location(a, n);
            return -1;
        }
        return 1;
    }
    bin = (unsigned char)plots[n].flags;
    b = suspects[bin].person;
    flagj = persons[b].fate < 0 && persons[b].fate != -3 && (plots[n].flags & 0x1000);
    resm = -1;
    for (il = 0; il < num_plots; il++) {
        if (plots[il].suspect == bin) {
            if (plots[n].msg == plots[il].msg) {
                resm = il;
                break;
            }
            if (plots[il].state == 999 && !flagj)
                return -1;
        }
    }
    if (persons[a].fate == -1) {
        check_special_location(a, n);
        return -1;
    }
    if (persons[b].fate == -1) {
        check_special_location(b, n);
        return -1;
    }
    if (persons[a].fate == -2 && persons[b].fate != -1) {
        persons[a].fate = 0;
        strcpy(text_buf, "Bulletin:\n");
        append_person_name(a);
        strcat(text_buf, " has come out of hiding!\n");
        incoming_message("Surveillance Team");
        add_chronology_entry(9, a);
    }
    if (persons[b].fate == -2 && persons[a].fate != -1) {
        persons[b].fate = 0;
        strcpy(text_buf, "Bulletin:\n");
        append_person_name(b);
        strcat(text_buf, " has come out of hiding!\n");
        incoming_message("Surveillance Team");
        add_chronology_entry(9, b);
    }
    return resm;
}

check_special_location(p)
int p;
{
    int i, unusedf;

    for (i = 0; i < num_suspects - difficulty * 4; i++) {
        if (suspects[i].flags & 0x100)
            mastermind = suspects[i].person;
    }
    if ((hiding_target == -1 || random(8) < difficulty) && persons[p].fate == -1
        && difficulty > 1 && !(persons[p].known & 0x40) && persons[mastermind].fate != -1) {
        jailbreak_person = hiding_target = p;
        return 1;
    }
    return 0;
}

char date_str[] = "00:00 AM Jun 00";      /* 3cf8 */

char *format_date_time(t)
unsigned t;
{
    int h;

    clock_minute = t % 60;
    date_str[3] = clock_minute / 10 + '0';
    date_str[4] = clock_minute % 10 + '0';
    t /= 60;
    clock_hour = t % 24;
    h = (clock_hour + 11) % 12 + 1;
    date_str[0] = h / 10 + '0';
    date_str[1] = h % 10 + '0';
    date_str[6] = clock_hour > 11 ? 'P' : 'A';
    strcpy(date_str + 9, month_names[cur_month % 12]);
    strcat(date_str, " 10");
    clock_day = t / 24 + 1;
    date_str[13] = clock_day / 10 + '0';
    date_str[14] = clock_day % 10 + '0';
    return date_str;
}

int status_y = 174;                     /* 3d0c status bar position */

draw_status_bar()
{
    char buf[32];

    drv_set_color_map(status_colormap, status_colormap);
    gfx_fill_rect(g_gfx, 0, status_y, 160, 26, 8);
    draw_line(1, status_y + 1, 1, status_y + 24, 5);
    draw_line(2, status_y + 2, 2, status_y + 24, 7);
    draw_line(2, status_y + 1, 158, status_y + 1, 7);
    draw_line(158, status_y + 2, 158, status_y + 24, 5);
    draw_line(2, status_y + 24, 158, status_y + 24, 5);
    gfx_fill_rect(g_gfx, 5, status_y + 3, 150, 9, 5);
    draw_line(3, status_y + 3, 5, status_y + 3, 5);
    draw_line(6, status_y + 4, 6, status_y + 11, 7);
    draw_line(156, status_y + 3, 156, status_y + 11, 5);
    strcpy(buf, cities[here_city].name);
    strcat(buf, ", ");
    strcat(buf, cities[here_city].country);
    draw_text_centered(buf, 80, status_y + 4, 10);
    gfx_fill_rect(g_gfx, 15, status_y + 14, 130, 9, 5);
    draw_line(13, status_y + 14, 15, status_y + 14, 5);
    draw_line(16, status_y + 15, 16, status_y + 22, 7);
    draw_line(146, status_y + 14, 146, status_y + 22, 5);
    draw_text_centered(format_date_time(clock_base), 80, status_y + 15, 10);
    drv_set_color_map(std_colormap, std_colormap2);
    status_y = 174;
}

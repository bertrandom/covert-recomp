/* CLUE.C - game library shared by GAME/TAC/FINAL/BUG: suspects, clues,
 * known organization sites, suspect dossiers and intercepted-message
 * descriptions.  One object file in the original.  Reconstructed from
 * BUG.EXE; compiles with MSC 5.1 CL /AS /Gs /Oas, K&R style. */
#include "mps.h"
#include "gamelib.h"

extern char *strcat();
extern char *strcpy();
extern char *itoa();

/* Initialized tables: MSC emits the strings of an initializer at once and the
 * table itself after the end of the next function, so each definition sits
 * just before the function whose data it follows in DGROUP. */
char *clue_kind_names[] = {             /* 1A40 (strings 176A) */
    " tied to ", " registered to ", " acquired by ", " delivered to ",
    " requested for ", " tied to ", " registered to ", " traced to ",
    " smuggled into ", " requested for ", " tied to ", " rented by ",
    " frequented by ", " is in ", " linked to ", " purchased by ",
    " purchased by ", " traced to ", " purchased in ", " linked to ",
    " received by ", " signed for by ", " traced to ", " sent to ",
    " refers to ", " withdrawn by ", " withdrawn by ", " paid by ",
    " transaction in ", " requested for ", " withdrawn by ", " withdrawn by ",
    " paid by ", " transaction in ", " requested for ", " assigned to ",
    " assigned to ", " assigned to ", " used in ", " assigned to ",
};
char clue_kind_bits[16] = {             /* 1A90 not referenced by BUG */
    2, 2, 1, 4, 1, 8, 1, 8, 1, 4, 1, 4, 1, 2, 1, 8
};
char bitcount[32] = {                   /* 1AA0 bits set in 0..31 */
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5
};
char *month_names[] = {                 /* 1AC0 (strings 198A) */
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
};

describe_new_info(org, city, amount, popup)
int org, city, amount, popup;
{
    int dorg4, o1, nbits, p, n2, best_d, total, t, bit8, p_org, cd, w, level, quot;
    unsigned kn;
    int pts2, here_p6, mis, newbit, pcity, v2c, oth, rate, ret2;

    total = 0;
    popup_flag = popup;
    if (amount <= 0)
        return 0;
    n2 = 0;
    best_d = 9999;
    v2c = -1;
    here_p6 = -1;
    for (p = 0; p < num_persons; p++) {
        if (!persons[p].id)
            continue;
        p_org = persons[p].org;
        pcity = persons[p].city;
        dorg4 = city_distance(orgs[org].home, orgs[p_org].home);
        cd = city_distance(cities[city].code, cities[pcity].code);
        if (!dorg4 && !cd)
            here_p6 = p;
        quot = ((long)((dorg4 + 2) * (cd + 2)) << 8) / (amount + 1);
        rate = ((long)((dorg4 + 3) * (cd + 6)) << 6) / (amount + 1);
        w = 10000 / (difficulty + 2) / quot;
        persons[p].points += (long)w * w / (persons[p].points / 2 + w + 1);
        pts2 = persons[p].points;
        quot = 2500 / (pts2 + 1);
        for (level = 0; level < num_suspects; level++) {
            if (suspects[level].person == p && suspect_state[level].time <= game_time
                && suspect_state[level].time != -1) {
                suspect_state[level].progress += 5000 / (difficulty + 3) / rate;
                kn = suspects[level].found;
                nbits = bitcount[suspects[level].found & 0x1f];
                while (suspect_state[level].progress * (suspects[level].importance + 2) > (nbits + 2) * (nbits + 2) * 32
                       && (suspects[level].found & 0x1f) != 0x1f) {
                    total += reveal_random_clue(level, org, city);
                    nbits = bitcount[suspects[level].found & 0x1f];
                }
            }
        }
        if (!persons[p].known && dorg4 && cd)
            continue;
        {
            kn = persons[p].known;
            level = 2;
            for (mis = 0; mis < num_msgs; mis++) {
                if (msgs[mis].sender == p) {
                t = msgs[mis].msg;
                while (bitcount[msgs[mis].flags & 0xf] * 2 + level
                       < suspects[plots[t].suspect].importance * persons[p].points / 96
                       && (msgs[mis].flags & 0xf) != 0xf) {
                    bit8 = 1 << random(4);
                    if (!(bit8 & msgs[mis].flags)) {
                    suspect_dossier(p, 0, 0);
                    text_buf[0] = 0;
                    if (plots[t].flags & 0x200)
                        strcpy(text_buf, "       CODED MESSAGE:\n");
                    if (plots[t].flags & 0x800)
                        strcpy(text_buf, "       MEETING NOTES:\n");
                    if (!msgs[mis].flags)
                        strcat(text_buf, "       NEW INFORMATION\n");
                    else
                        strcat(text_buf, "    ADDITIONAL INFORMATION\n");
                    append_person_name(p);
                    strcat(text_buf, " ");
                    format_message_event(mis);
                    strcat(text_buf, "\n... ");
                    if (bit8 & 1) {
                        strcat(text_buf, "on ");
                        strcat(text_buf, month_names[cur_month % 12]);
                        strcat(text_buf, " ");
                        strcat(text_buf, itoa(msgs[mis].time / 1440 + 1, itoa_buf, 10));
                    }
                    if (plots[t].flags & 0xfff) {
                        oth = msgs[mis].receiver;
                        if (bit8 & 2) {
                            persons[oth].known |= 2;
                            append_person_name(oth);
                        }
                        if (bit8 & 4) {
                            strcat(text_buf, "of the ");
                            strcat(text_buf, orgs[persons[oth].org].name);
                        }
                        if (bit8 & 8) {
                            strcat(text_buf, "in ");
                            strcat(text_buf, cities[msgs[mis].receiver_city].name);
                        }
                        strcat(text_buf, "\n");
                        draw_bevel_box(16, 96, 264, 48, is_cga ? 4 : 3);
                        g_gfx->fillcolor = 3;
                        draw_wrapped_text(32, 20, 100, 11);
                        wait_key_or_button();
                        msgs[mis].flags |= bit8;
                        suspect_dossier(p, 0, 0);
                        wait_key_or_button();
                        persons[p].known |= 0x10;
                    } else {
                        msgs[mis].flags |= 0xe;
                        wait_key_or_button();
                    }
                    msgs[mis].flags |= bit8;
                    if (!(persons[p].roles & (1 << plots[t].suspect))
                        && ((difficulty < 1 && dorg4 + cd == 0 && (msgs[mis].flags & 0xf) == 0xf)
                            || !(plots[t].flags & 0xfff))) {
                        persons[p].roles |= 1 << plots[t].suspect;
                        kn |= 0x10;
                        persons[p].known &= ~0x10;
                        msgs[mis].flags |= 0xf;
                    }
                    }
                }
                level++;
                if ((plots[t].flags & 0xf00) && (msgs[mis].flags & 0xe)) {
                    o1 = msgs[mis].receiver;
                    pick_clue(persons[o1].org, persons[o1].city, msgs[mis].flags & 6, 0L);
                    if (msgs[mis].receiver_city == persons[o1].city)
                        pick_clue(persons[o1].org, persons[o1].city, msgs[mis].flags & 8, 0L);
                }
                }
            }
            while (kn && (bitcount[kn & 0xf] + bitcount[(kn & 0x70f) >> 8]) * 25 < persons[p].points
                   && (kn & 0x70f) != 0x70f) {
                if (org == p_org && !(kn & 4)) {
                    kn |= 4;
                    break;
                }
                if (city == pcity && !(kn & 8)) {
                    kn |= 8;
                    break;
                }
                do
                    newbit = 1 << random(12);
                while ((newbit & kn & 0x70f) || !(newbit & 0x70f));
                kn |= newbit;
            }
            if (persons[p].known != kn) {
                pick_clue(p_org, pcity, kn, 1L);
                best_d = 0;
                v2c = -1;
                total++;
            }
        }
    }
    if (!total && popup) {
        strcpy(text_buf, "");
        p = suspects[random(num_suspects)].person;
        face_shown = -1;
        switch (random(8 - difficulty)) {
        case 0:
            strcpy(text_buf, cities[persons[p].city].name);
            city_clue_count[persons[p].city]++;
            break;
        case 1:
            strcpy(text_buf, orgs[persons[p].org].name);
            org_clue_count[persons[p].org]++;
            orgs[persons[p].org].flags |= 1;
            break;
        case 2:
            strcpy(text_buf, " ");
            face_shown = persons[p].id;
            break;
        case 3:
            newbit = persons[p].known;
            persons[p].known |= 2;
            text_buf[0] = 0;
            append_person_name(p);
            persons[p].known = newbit;
            break;
        case 4:
        case 6:
            p_org = here_org;
            pcity = persons[suspects[random(num_suspects)].person].city;
            goto reach;
        case 5:
        case 7:
            p_org = persons[suspects[random(num_suspects)].person].org;
            pcity = here_city;
reach:
            if ((ret2 = org_can_reach(here_org, p_org, pcity)) && !(cities[pcity].orgs_known & ((unsigned)1 << p_org))
                && org_alert_level(pcity, p_org)) {
                cities[pcity].orgs_known |= (unsigned)1 << p_org;
                set_location_known(p_org, pcity, 12);
                orgs[p_org].flags |= 1;
                strcpy(text_buf, orgs[p_org].name);
                append_building_type(pcity, p_org);
                strcat(text_buf, " in ");
                strcat(text_buf, cities[pcity].name);
                face_shown = -2;
                break;
            }
            text_buf[0] = 0;
        }
        if (text_buf[0]) {
            draw_intercept_popup();
            wait_key_or_button();
        }
    }
    return total;
}

int clue_word_1ad8 = 0;                 /* 1AD8 not referenced by BUG */

pick_clue(org, city, known, show)
int org, city;
unsigned known;
int show;
{
    int i, j, ok, old;

    for (i = 0; i < num_persons; i++) {
        if (persons[i].org == org && persons[i].city == city) {
            old = persons[i].known;
            if (persons[i].known |= known) {
found:
                if (show)
                    describe_clue(i, old);
                return i;
            }
            return -1;
        }
    }
    do
        i = random(63) + 1;
    while (persons[i].id);
    if (org == mm_org && city == mm_city) {
        i = 0;
        known |= mm_known;
    }
    if (!known)
        return -1;
    old = persons[i].known;
    persons[i].org = org;
    persons[i].city = city;
    persons[i].known = known;
    persons[i].flags = 0;
    persons[i].roles = 0;
    do {
        ok = 1;
        persons[i].id = random(0x7fff);
        for (j = 0; j < num_persons; j++)
            if ((persons[i].id & 0x3f == persons[j].id & 0x3f) && i != j)
                ok = 0;
    } while (!ok);
    goto found;
}

free_location_if_unused(i)
int i;
{
    if (persons[i].flags & 0x7fff)
        return;
    persons[i].id = 0;
    persons[i].org = -1;
    persons[i].city = -1;
    persons[i].known = 0;
}

describe_clue(p, newk)
int p;
unsigned newk;
{
    unsigned old, diff;

    old = persons[p].known;
    persons[p].known = newk;
    if (old == newk)
        return;
    do {
        suspect_dossier(p, 0, 0);
        dossier_state = 0;
        old |= persons[p].known;
        diff = old ^ persons[p].known;
        if (diff & 0x10) {
            persons[p].known |= 0x10;
            strcpy(text_buf, "");
            append_person_name(p);
            strcat(text_buf, " has been\nidentified as a participant\nin the plot.\n");
            show_menu(text_buf, 20, 60);
        } else if (diff & 2) {
            strcpy(text_buf, "");
            append_person_name(p);
            strcat(text_buf, " has been positively\nidentified as ");
            persons[p].known |= 2;
            append_person_name(p);
            strcat(text_buf, "\n");
            show_menu(text_buf, 20, 60);
        } else if (diff & 1) {
            persons[p].known |= 1;
            strcpy(text_buf, "We have acquired a\nphotograph of ");
            append_person_name(p);
            strcat(text_buf, ".\n");
            show_menu(text_buf, 20, 60);
        } else if (diff & 8) {
            persons[p].known |= 8;
            strcpy(text_buf, "");
            append_person_name(p);
            strcat(text_buf, " has been\nspotted in ");
            strcat(text_buf, cities[persons[p].city].name);
            strcat(text_buf, "\n");
            show_menu(text_buf, 20, 60);
            city_clue_count[persons[p].city]++;
        } else if (diff & 4) {
            persons[p].known |= 4;
            strcpy(text_buf, "");
            append_person_name(p);
            strcat(text_buf, " has been\nidentified as a member\nof the ");
            strcat(text_buf, orgs[persons[p].org].name);
            strcat(text_buf, "\n");
            show_menu(text_buf, 20, 60);
            orgs[persons[p].org].flags |= 1;
            org_clue_count[persons[p].org]++;
        } else if (diff & 0x20) {
            persons[p].known |= 0x20;
            strcpy(text_buf, "We have obtained\nadditional information\nconcerning ");
            append_person_name(p);
            strcat(text_buf, "\n");
            show_menu(text_buf, 20, 60);
        } else if (diff & 0x100) {
            persons[p].known |= 0x100;
            strcpy(text_buf, "We have determined\nthe rank of\n");
            append_person_name(p);
            strcat(text_buf, "\n");
            show_menu(text_buf, 20, 60);
        } else if (diff & 0x200) {
            persons[p].known |= 0x200;
            strcpy(text_buf, "We found recruiting\ninformation about\n");
            append_person_name(p);
            strcat(text_buf, "\n");
            show_menu(text_buf, 20, 60);
        } else if (diff & 0x400) {
            persons[p].known |= 0x400;
            strcpy(text_buf, "We found recruiting\ninformation about\n");
            append_person_name(p);
            strcat(text_buf, "\n");
            show_menu(text_buf, 20, 60);
            continue;
        }
    } while (persons[p].known != old);
    suspect_dossier(p, 0, 0);
    wait_key_or_button();
}

char *rank_names[] = {                  /* 1F24 (strings 1C4A) */
    "Recruit", "Operative", "Technician", "Agent",
    "Organizer", "Special Agent", "Group Leader", "MasterMind",
};
char *clue_item_codes[] = {             /* 1F34 not referenced by BUG */
    "CAR", "WPN", "ADR", "TKT", "MSG", "$", "$", "FCE",
};
char *number_prefix[][8] = {            /* 1F44 */
    { "Ford Escort #", "Chevy Nova #", "Toyota Tercel #", "VW Golf #",
      "Mazda RX7 #", "Honda Civic #", "Peugot #", "Chrysler #" },
    { "Walther PPK #", "Smith&Wesson 9mm #", "Berreta M92S #", "Browning 9mm #",
      "Hechler&Koch VP #", "Luger 9mm #", "Colt 45 #", "357 Magnum #" },
    { "Rue Laverne ", "HochStrasse ", "Main St. ", "Webley Ct. ",
      "Holmley Park ", "ObensGrabbe ", "La Paz Blvd. ", "North Ave. " },
    { "PanAm #", "United #", "Sabena #", "Lufthansa #",
      "El Al #", "KLM #", "SwissAir #", "BOAC #" },
    { "W.Union #", "RCA #", "Telex #", "AmTel #",
      "InterTel #", "SatComm #", "TelTron #", "ComLink #" },
    { "$", "$", "$", "$", "$", "$", "$", "$" },
    { "$", "$", "$", "$", "$", "$", "$", "$" },
    { "Swiss Passport #", "InterPol ID#", "Bahamian Passport #", "Gold Card #",
      "Swedish Passport #", "Green Card #", "VISTA Card #", "Liberian Passport #" },
};

wait_key_or_button()
{
    int key;

    key = -1;
    while (drv_kbhit() && key == -1) {
        if ((options & 0x10) && (joystick_button(0) || joystick_button(1)))
            key = 1;
    }
    if (key == -1)
        key = get_key();
    flush_input();
    return key;
}

add_location(org, city, flags)
int org, city;
unsigned flags;
{
    int i;

    for (i = 0; i < num_persons; i++) {
        if (persons[i].org == org && persons[i].city == city) {
            persons[i].flags |= flags;
            return i;
        }
    }
    do
        i = random(64);
    while (persons[i].id || !i);
    if (org == mm_org && city == mm_city)
        i = 0;
    if (flags) {
        persons[i].org = org;
        persons[i].city = city;
        persons[i].known = i ? 0 : mm_known;
        persons[i].flags = flags;
        persons[i].roles = 0;
        persons[i].points = 0;
        if (i) {
            persons[i].id = random(0x7ffe) + 1;
            if (!random(3))
                persons[i].id |= 1;
        } else
            persons[i].id = mm_id;
        persons[i].fate = 0;
        return i;
    }
    return -1;
}

set_location_known(org, city, flags)
int org, city;
unsigned flags;
{
    int i;

    if (flags)
        cities[city].orgs_known |= 1 << org;
    for (i = 0; i < num_sites; i++) {
        if (sites[i].org == org && sites[i].city == city) {
            if (sites[i].flags |= flags)
                return i;
            return -1;
        }
    }
    if (!flags)
        return -1;
    sites[num_sites].org = org;
    sites[num_sites].city = city;
    sites[num_sites].flags = flags;
    sites[num_sites].strength = 0;
    sites[num_sites].f8 = sites[num_sites].fa = 0;
    num_sites++;
    return num_sites - 1;
}

clear_location(org, city)
int org, city;
{
    int i;

    for (i = 0; i < num_sites; i++) {
        if (sites[i].org == org && sites[i].city == city) {
            sites[i].flags = 0;
            sites[i].strength = sites[i].f8 = sites[i].fa = 0;
            cities[city].orgs_known &= ~(1 << org);
            break;
        }
    }
}

reveal_random_clue(n, a, b)
int n, a, b;
{
    unsigned bit;

    if ((suspects[n].found & 0x1f) != 0x1f) {
        do {
            bit = 1 << random(5);
            if (!difficulty && !(suspects[n].found & 0x10))
                bit = 0x10;
            if (suspects[n].type == 2 && difficulty < 2 && !(suspects[n].found & 8))
                bit = 8;
        } while (suspects[n].found & bit);
        show_clue(a, b, n, bit);
        return 1;
    }
    return 0;
}

delete_clue(n)
int n;
{
    int i;

    for (i = n; i < 79; i++) {
        memcpy(&clues[i], &clues[i + 1], 12);
        if (clues[i].suspect == -1) {
            clues[i].org = -1;
            clues[i].city = -1;
            break;
        }
    }
}

char *clue_method_names[] = {           /* 207E (strings 1FC4) */
    "Clandestine Photo", "Electronic WireTap", "Covert Surveillance",
    "File Record Search", "Local Informant", "INTERPOL Data Base",
    "Local Authorities",
};

show_clue(org, city, suspect, kind)
char org, city;
int suspect, kind;
{
    int phase, yy, top, pic_y, wid, t1, line, loop, ci, cj, shown; /* yy, top, t1, loop unused */

    if (!(suspects[suspect].found & kind)) {
        for (ci = 0; ci < 80; ci++) {
            if (clues[ci].suspect == -1) {
                clues[ci].org = org;
                clues[ci].city = city;
                clues[ci].suspect = suspect;
                if (kind > 31)
                    kind >>= 5;
                clues[ci].kind = encode_clue(ci, kind);
                clues[ci].text = load_clue_text(suspect, 0);
                suspects[suspect].found |= kind;
                draw_page_frame("Clue", 9);
                g_gfx->fillcolor = 15;
                strcpy(text_buf, "\207Source: ");
                strcat(text_buf, orgs[clues[ci].org].name);
                strcat(text_buf, "/");
                strcat(text_buf, cities[clues[ci].city].name);
                strcat(text_buf, "\n");
                clue_text_wrapper(ci);
                if (clues[ci].org > 1)
                    clue_icon = popup_flag == 1 ? 1 : 0;
                strcat(text_buf, "\n\207Method: ");
                strcat(text_buf, clue_method_names[clue_icon]);
                draw_wrapped_text(31, 16, 17, 5);
                if (kind == 1) {
                    draw_portrait(face_shown, 264, 18);
                    draw_sprite_a(108, 299, 46);
                } else
                    draw_sprite_a(clue_icon + 96, 272, 16);
                draw_text_transparent("\214Related Clues:", 16, 66, 5);
                line = 76;
                shown = 0;
                pic_y = 73;
                for (phase = 0; phase < 2; phase++) {
                    for (cj = 0; cj < 80; cj++) {
                        if (clues[cj].suspect != -1 && ci != cj) {
                            if (line > 180)
                                break;
                            if (!((phase && clues[ci].kind == clues[cj].kind) ||
                                  (!phase && clues[ci].text == clues[cj].text)))
                                continue;
                            text_buf[0] = 0;
                            wid = random(12) + 4;
                            draw_card_panel(wid, line - 2);
                            if ((clues[cj].kind >> 8) == 16)
                                clue_text_wrapper(cj);
                            else
                                describe_person(cj);
                            strcat(text_buf, "\n");
                            shown = 1;
                            line = draw_wrapped_text(32, wid + 8, line, 0);
                            line += 4;
                            if ((clues[cj].kind >> 8) == 1) {
                                draw_portrait(persons[suspects[clues[cj].suspect].person].id,
                                              264, clamp(pic_y, 0, 150));
                                draw_sprite_a(108, 299, clamp(pic_y + 24, 0, 176));
                                pic_y += 40;
                            }
                        }
                    }
                }
                if (!shown)
                    draw_text_transparent("...none", 16, 72, 5);
                wait_key_or_button();
                face_shown = -1;
                ci = 999;
            }
        }
    }
}

encode_clue(ci, kind)
int ci, kind;
{
    int who;

    who = suspects[clues[ci].suspect].person;
    switch (kind) {
    case 8:
        city_clue_count[persons[who].city]++;
        return (kind << 8) + persons[who].city;
    case 4:
        org_clue_count[persons[who].org]++;
        orgs[persons[who].org].flags |= 1;
        strcat(text_buf, orgs[persons[who].org].name);
        return (kind << 8) + persons[who].org;
    case 1:
        return (kind << 8) + who;
    case 2:
        return (kind << 8) + who;
    case 16:
        return clues[ci].suspect + (kind << 8);
    }
}

char *clue_keywords[] = {               /* 20BA (strings 208C) */
    "$KEY", "$NAME", "$ORG", "$CITY", "$ROLE",
};

load_clue_text(suspect, full)
int suspect, full;
{
    int pos, val;
    char key[8];

    val = suspects[suspect].info;
    if (full)
        val &= 0x7f;
    else
        val >>= 1;
    if (suspect < num_suspects - difficulty * 4)
        return ((unsigned char)suspects[suspect].type << 8) + val;
    pos = persons[suspects[suspect].person].id;
    strcpy(key, "*C0000");
    key[5] += pos % 6;
    key[3] += (pos >> 3) % 4;
    pos = strlen(text_buf);
    lookup_text("clues.txt", key, clue_keywords, subst_vals, 5);
    text_buf[pos] = 0;
    return ((text_buf[pos + 1] & 15) << 8) + val;
}

describe_person(ci)
int ci;
{
    if (clues[ci].text != -1) {
        append_number(clues[ci].text);
        strcat(text_buf, clue_kind_names[clue_kind_index(clues[ci].kind, clues[ci].text)]);
    }
    if (clues[ci].kind != -1) {
        describe_person_id(ci, clues[ci].kind);
        strcat(text_buf, ".");
    }
}

clue_kind_index(kind, text)
int kind, text;
{
    int idx, k;

    idx = ((text >> 8) & 7) * 5;
    for (k = kind >> 8; k > 1; k >>= 1)
        idx++;
    return idx;
}

describe_person_id(ci, id)
int ci, id;
{
    int n;

    n = id & 0xff;
    switch (id >> 8) {
    case 8:
        strcat(text_buf, cities[n].name);
        break;
    case 4:
        strcat(text_buf, orgs[n].name);
        orgs[n].flags |= 1;
        break;
    case 2:
        person_name(n);
        break;
    case 1:
        strcat(text_buf, "this face.");
        face_shown = persons[n].id;
        break;
    case 16:
        if (clues[ci].suspect < num_suspects - difficulty * 4)
            strcat(text_buf, "Valkerie");
        else
            strcat(text_buf, "Thunderbolt");
        break;
    }
}

append_number(num)
int num;
{
    if (num != -1) {
        strcat(text_buf, number_prefix[(num >> 8) & 15][(num >> 4) & 7]);
        strcat(text_buf, itoa((num & 0x3f) + 1, itoa_buf, 10));
        if (((num >> 8) & 15) == 5)
            strcat(text_buf, "00");
        if (((num >> 8) & 15) == 6)
            strcat(text_buf, "000");
    }
}

clue_text_wrapper(ci)
int ci;
{
    clue_text(clues[ci].kind, clues[ci].text, ci);
}

clue_text(kind, text, ci)
int kind, text, ci;
{
    int num, pos, cut;
    char key[8];

    num = kind & 0xff;
    strcpy(key, "*C00");
    key[2] += (text >> 8) & 15;
    for (pos = kind >> 8; pos > 1; pos >>= 1)
        key[3]++;
    pos = strlen(text_buf);
    append_number(text);
    strcpy(subst_vals[0], text_buf + pos);
    text_buf[pos] = 0;
    cut = 1;
    switch (kind >> 8) {
    case 1:
        face_shown = persons[num].id;
        break;
    case 2:
        person_name(num);
        strcpy(subst_vals[1], text_buf + pos);
        text_buf[pos] = 0;
        break;
    case 4:
        strcpy(subst_vals[2], orgs[num].name);
        break;
    case 8:
        strcpy(subst_vals[3], cities[num].name);
        break;
    case 16:
        cut = 2;
        if (clues[ci].suspect < num_suspects - difficulty * 4) {
            strcpy(key, "*C0000");
            key[5] += num;
            key[3] += msg_day % 10;
            key[2] += msg_day / 10;
        } else {
            pos = persons[suspects[clues[ci].suspect].person].id;
            strcpy(key, "*C0000");
            key[5] += pos % 6;
            key[3] += (pos >> 3) % 4;
        }
        break;
    }
    pos = strlen(text_buf);
    lookup_text("clues.txt", key, clue_keywords, subst_vals, 5);
    clue_icon = text_buf[pos] & 15;
    strcpy(text_buf + pos, text_buf + pos + cut);
}

suspect_dossier(who, x, y)
int who, x, y;
{
    int role, inset, dist, msg, embedded, self, spare, near_city, ei, evt; /* inset, spare, evt unused; self never read */

    embedded = y;
    self = who;
    if (y)
        x += 4;
    else {
        strcpy(text_buf, "");
        append_person_name(who);
        draw_page_frame(text_buf, 3);
        y = 18;
        x += 10;
    }
    y += 2;
    strcpy(text_buf, "Name:\200");
    append_person_name(who);
    draw_text_transparent(text_buf, x, y, 7);
    if (persons[who].known & 0x100) {
        near_city = (persons[who].id >> 2) & 7;
        for (ei = 0; ei < num_suspects; ei++)
            if (suspects[ei].person == who)
                near_city = suspects[ei].rank;
        strcpy(text_buf, "Rank:\200");
        strcat(text_buf, rank_names[near_city]);
        y += 8;
        draw_text_transparent(text_buf, x, y, 7);
    }
    if (persons[who].known & 4) {
        orgs[persons[who].org].flags |= 1;
        strcpy(text_buf, "Org: \200");
        strcat(text_buf, orgs[persons[who].org].name);
        y += 8;
        draw_text_transparent(text_buf, x, y, 7);
    }
    if (persons[who].known & 8) {
        strcpy(text_buf, "City: \200");
        strcat(text_buf, cities[persons[who].city].name);
        y += 8;
        draw_text_transparent(text_buf, x, y, 7);
    }
    strcpy(text_buf, "Recruited");
    if (persons[who].known & 0x400) {
        for (ei = 0; ei < num_suspects; ei++) {
            if (persons[who].org == persons[suspects[ei].person].org) {
                if (who != suspects[ei].person) {
                    strcat(text_buf, " by ");
                    person_name(suspects[ei].person);
                }
                break;
            }
        }
    }
    if (persons[who].known & 0x200) {
        near_city = -1;
        dist = 999;
        ei = 0;
        do {
            if (ei != persons[who].city && city_map_distance(ei, persons[who].city) < dist) {
                near_city = ei;
                dist = city_map_distance(ei, persons[who].city);
            }
        } while (++ei < 16);
        if (near_city != -1) {
            strcat(text_buf, " in ");
            strcat(text_buf, cities[near_city].name);
        }
    }
    if (strlen(text_buf) > 12 && !embedded) {
        strcat(text_buf, ".");
        y += 8;
        draw_text_transparent(text_buf, x, y, 7);
    }
    if ((persons[who].known & 1) && !embedded) {
        draw_portrait(persons[who].id, 264, 8);
        draw_sprite_a(108, 299, 40);
    }
    role = 0;
    y += 10;
    draw_line(x, y - 2, x + 128, y - 2, 12);
    for (ei = 0; ei < num_suspects; ei++) {
        if (persons[who].roles & (1 << ei)) {
            strcpy(text_buf, "Role: \200");
            strcat(text_buf, suspects[ei].name);
            draw_text_transparent(text_buf, x, y, 7);
            role = 1;
        }
    }
    if (!role) {
        if ((persons[who].known & 0x1f) == 0x1f && !(persons[who].flags & 0x7fff))
            strcpy(text_buf, "Role: \200NOT INVOLVED");
        else
            strcpy(text_buf, "Role: \200unknown");
        draw_text_transparent(text_buf, x, y, 7);
    }
    if (persons[who].fate == -1) {
        strcpy(text_buf, "(Under Arrest)");
        y += 8;
        draw_text_transparent(text_buf, x, y, 5);
    }
    if (persons[who].fate == -2) {
        strcpy(text_buf, "(In Hiding)");
        y += 8;
        draw_text_transparent(text_buf, x, y, 5);
    }
    if (persons[who].fate == -3) {
        strcpy(text_buf, "(Turned)");
        y += 8;
        draw_text_transparent(text_buf, x, y, 5);
    }
    draw_line(x, y + 8, x + 128, y + 8, 12);
    y += 2;
    y = clamp(y + 8, (persons[who].known & 1) ? embedded + 54 : 0, 99);
    for (ei = 0; ei < num_msgs; ei++) {
        if (msgs[ei].sender == who && msgs[ei].flags && !embedded) {
again:
            strcpy(text_buf, "");
            format_message_event(ei);
            y = draw_wrapped_text(37, x, y, 5);
            if (!embedded) {
                msg = msgs[ei].msg;
                if (msgs[ei].flags & 0x8000) {
                    strcpy(text_buf, "'");
                    load_message_text(msg);
                    strcat(text_buf, "'");
                    y = draw_wrapped_text(36, x + 4, y, 12);
                } else {
                    if ((plots[msg].flags & 0xf00) == 0x200 || (plots[msg].flags & 0xf00) == 0x300) {
                        draw_text("(message not decoded)", x + 4, y, 4);
                        y += 8;
                    }
                    if ((plots[msg].flags & 0xf00) == 0x800 || (plots[msg].flags & 0xf00) == 0x900) {
                        text_buf[0] = 0;
                        load_message_text(msg);
                        garble_message(msgs[ei].flags, 5);
                        y = draw_wrapped_text(36, x + 4, y, 12);
                    }
                }
            }
            if (y >= 192) {
                draw_text("...more", 256, 192, 12);
                wait_key_or_button();
                strcpy(text_buf, "");
                append_person_name(who);
                draw_page_frame(text_buf, 3);
                y = 16;
                goto again;
            }
        }
    }
}

format_message_event(e)
int e;
{
    int who2, other, m, who;

    m = msgs[e].msg;
    strcat(text_buf, m >= 0 ? plots[m].name : (m & 1) ? "Rcvd msg fm" : "Sent msg to");
    if ((plots[m].flags & 0xfff) || m < 0) {
        who = msgs[e].sender;
        who2 = msgs[e].receiver;
        other = -1;
        if (msgs[e + 1].time == msgs[e].time)
            other = e + 1;
        if (msgs[e - 1].time == msgs[e].time)
            other = e - 1;
        if (msgs[e].flags & 2) {
            strcat(text_buf, " ");
            append_person_name(who2);
        } else
            strcat(text_buf, " someone");
        if (msgs[e].flags & 4) {
            strcat(text_buf, " of the ");
            strcat(text_buf, orgs[persons[who2].org].abbrev);
        }
        if (msgs[e].flags & 8) {
            strcat(text_buf, " in ");
            strcat(text_buf, cities[msgs[e].receiver_city].name);
        }
        if ((msgs[e].flags & 2 && persons[who2].known & 2) ||
            (msgs[e].flags & 4 && msgs[e].flags & 8 &&
             persons[who2].known & 4 && persons[who2].known & 8)) {
            msgs[e].flags |= persons[who2].known & 6;
            msgs[other].flags |= persons[who].known & 6;
            persons[who2].known |= msgs[e].flags & 6;
            if (msgs[e].receiver_city == persons[who2].city) {
                msgs[e].flags |= persons[who2].known & 8;
                persons[who2].known |= msgs[e].flags & 8;
            }
        }
        if ((msgs[other].flags & 2 && persons[who].known & 2) ||
            (msgs[other].flags & 4 && msgs[other].flags & 8 &&
             persons[who].known & 4 && persons[who].known & 8)) {
            msgs[other].flags |= persons[who].known & 6;
            msgs[e].flags |= persons[who2].known & 6;
            persons[who].known |= msgs[other].flags & 6;
            if (msgs[other].receiver_city == persons[who].city) {
                msgs[other].flags |= persons[who].known & 8;
                persons[who].known |= msgs[other].flags & 8;
            }
        }
    }
    if (msgs[e].flags & 1) {
        strcat(text_buf, " on ");
        strcat(text_buf, month_names[cur_month % 12]);
        strcat(text_buf, " ");
        strcat(text_buf, itoa(msgs[e].time / 1440 + 1, itoa_buf, 10));
    }
    strcat(text_buf, ".");
}

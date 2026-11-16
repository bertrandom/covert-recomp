/* FINAL.H - FINAL.EXE (title, new characters, briefings, end of case): types and
 * globals shared by all src/FINAL files.  The game tables and the library globals
 * come from MPS.H and GAMELIB.H; everything is listed below with its DGROUP offset
 * in FINAL.EXE (one name per address; tools/rebuild/syms/FINAL.txt is the same
 * table, checked with tools/rebuild/symcheck.py FINAL).
 * Reconstructed for Microsoft C 5.1: CL /AS /Gs /Oas. K&R style, no prototypes. */
#include "mps.h"
#include "gamelib.h"

/* Shared game state: COVERT.EXE stores a far pointer to it at 0000:04F0. */
#define ENV (*(unsigned char far * far *)0x4F0L)

/* A plot of plot.txt (*PLnn): the MasterMind's plan of up to 8 episodes. */
struct PlotDef {                /* 0x4A bytes */
    char name[24];              /* +00 "Welcome Max", "'KeyHole' Sattelite", ... */
    unsigned orgs;              /* +18 organization leaders that may run it (bit per
                                   leader code, see Org.flags) */
    int crime[8];               /* +1A crime of each episode (crime_names), -1 none */
    char *roles[8][2];          /* +2A the two roles of each episode's briefing */
};

/* An object the plot moves around (4, crimeN.dta). */
struct Item {                   /* 0x12 bytes */
    char name[16];              /* +00 */
    char icon;                  /* +10 icon on icons.pic */
    char holder;                /* +11 person carrying it on the timeline, -1 none */
};

/* A Hall of Fame entry (fame.dta). */
struct Fame {                   /* 0x2C bytes */
    int score;                  /* +00 -1 = empty */
    char name[32];              /* +02 code name */
    int difficulty;             /* +22 bit 7: Maxine */
    int plot;                   /* +24 plot_defs index */
    int episode;                /* +26 */
    int points;                 /* +28 efficiency points */
    int month;                  /* +2A cur_month */
};

/* In FINAL a person's points (+C) hold the known flags from before the
 * debriefing reveals everything (end_of_case); the report reads its low byte. */
#define known_before(p) (*(unsigned char *)&persons[p].points)
/* A suspect's +24 is a random identity code (the clue code reads its low byte as
 * Suspect.info); generate_case writes it as a word. */
#define suspect_id(n) (*(int *)&suspects[n].info)

/* Assembly segment (far) */
extern int far link_driver_stubs();
extern int far drv_slot36();
extern int far drv_slot12();            /* read a pixel */
extern int far drv_play_sound();
extern int far drv_get_image();
extern void far drv_begin_image_grab();
extern void far drv_end_image_grab();
extern void far drv_slot9();
extern void far drv_gate_slot30();
extern void far drv_draw_image();       /* (port, x, y, image) */

/* MS C runtime */
extern char *strcpy();
extern char *strcat();
extern int strlen();
extern char *strstr();
extern char *itoa();
extern int srand();
extern int int86();
extern int getch();
extern int exit();
extern int open();
extern int close();
extern int read();
extern int write();
extern long lseek();
extern int access();
extern char *memcpy();
extern int _dos_getdrive();
extern int _bios_disk();
extern int _dos_freemem();
extern int errno;                       /* 56F3 */

/* MicroProse and game library */
extern int random();
extern int clamp();
extern int text_window();
extern int show_menu();
extern int flush_input();
extern int wait_retrace();
extern int load_env();
extern int save_env();
extern int load_picture_swapped();
extern int open_catalog();
extern int close_catalog();
extern int require_disk();
extern int anim_play_file();
extern int lookup_random_text();
extern int lookup_text_simple();
extern int load_message_text();
extern int make_msg_key();
extern int wrap_text_buffer();
extern int draw_wrapped_text();
extern int set_scene_var();
extern int set_scene_background();
extern int fill_rect_xy();
extern int draw_line();
extern int draw_text();
extern int draw_text_centered();
extern int draw_text_transparent();
extern int draw_rect_outline();
extern int draw_page_frame();
extern int draw_card_panel();
extern int draw_portrait();
extern int draw_face_parts();
extern int init_face_parts();
extern int text_width();
extern int get_key();
extern int wait_key_or_button();
extern int read_joystick();
extern int joystick_button();
extern int append_person_name();
extern int pick_clue();
extern int add_location();
extern int set_location_known();
extern int city_distance();
extern int org_can_reach();
extern int org_alert_level();
extern int install_int24_handler();
extern int restore_int24_handler();

/* FINAL */
extern char *format_date_time();

/* ---- Globals by DGROUP offset ----
 * From MPS.H:      back_page 1570, g_gfx 4B58, options 8090, bios_regs 9F90
 * From GAMELIB.H:  persons 0188, sites 0588, clues 1188, month_names 367C,
 *   rank_names 3AE0, subst_vals 3ED8, msg_key 5D3C, text_buf 79E2,
 *   difficulty 7DE6, clock_base 7DF0, mm_known 7DF6, mm_org 7DF8, mm_city 7DFA,
 *   mm_id 7DFC, cur_month 7E08, player_name 7E1C, player_org_name 7E44,
 *   is_cga 8092, cities 8294, num_persons 84B6, msgs 84B8, plots 8BCA,
 *   num_msgs 96CA, num_sites 96D0, game_time 96D2, num_plots 9E88, msg_day 9E90,
 *   num_suspects 9FA2, suspects 9FA6, dossier_state A7B0, orgs A7BE,
 *   suspect_state AD6C, video_mode AE2C, here_city AE36, city_clue_count AE38,
 *   org_clue_count AE58, seen_orgs AE78, here_org B374
 * (FINAL's timeline/event list is GAMELIB's msgs, the plot steps of crimeN.dta
 * are GAMELIB's plots, the participants are GAMELIB's suspects.) */

/* _DATA, FINAL.C (also defines persons 0188, sites 0588, clues 1188, back_page 1570) */
extern int  jailbreak_person;                 /* 1548 env word 42h (ENV.C) */
extern RastPort work_rp;                /* 154A page 2 */
extern RastPort *work_page;             /* 155C -> work_rp */
extern RastPort back_rp;                /* 155E page 1 */
extern char start_colormap[];           /* 1572 color maps (16 bytes each) */
extern char start_colormap2[];          /* 1582 */
extern char std_colormap[];             /* 1592 (gamelib.h) */
extern char std_colormap2[];            /* 15A2 (gamelib.h) */
extern char colormap_b2[], colormap_c2[]; /* 15B2, 15C2 */
extern char story_colors[];             /* 15D2 briefing.pan */
extern char title_colors[];             /* 15E2 title2.pan */
extern char tele_colors[];              /* 15F2 (gamelib.h) */
extern char colormap_02[];              /* 1602 */
extern char face_colormap[];            /* 1612 (gamelib.h) */
extern char dialog_colors[];            /* 1622 code name dialog */
extern unsigned char report_colormap[]; /* 1632 efficiency report */
extern char colormap_42[];              /* 1642 */
extern char game_palette[];             /* 1652 */
extern int  cur_disk;                   /* 1664 disk in the drive */
extern char title_pan[];                /* 1666 "animation.pan": play_title_pan's file */

/* _DATA, NEWCHAR.C */
extern int  face_defs[26][8];           /* 1CFE portrait of each leader: sex, features, icon */
extern struct PlotDef plot_defs[16];    /* 1E9E */
extern char *skill_names[];             /* 247E "Combat", "Driving", ... */
extern int  rating_colors[];            /* 24A8 */
extern char face_palette[];             /* 24B0 */

/* _DATA, ENDCASE.C */
extern RastPort icon_rp;                /* 28AC page 2: icons.pic */
extern RastPort *icon_page;             /* 28BE -> icon_rp */
extern char plot_key[];                 /* 28C0 "*PL0000": plot.txt section */
extern char date_str[];                 /* 2A0A "00:00 AM Jun 00" */
extern char unused_2afb;                /* 2AFB one unreferenced zero byte */
extern char *crime_names[];             /* 2D5C 13 */
extern char *mastermind_names[];        /* 2D76 26, by leader code */
extern char unused_2dd5;                /* 2DD5 one unreferenced zero byte */
extern char *vacation_prefix[];         /* 2F36 "lau", "off", "bch", "cas" */
extern int  vacations[21][5];           /* 2F3E kind, then up to 4 frame numbers (-1 none) */

/* _DATA, CASE.C */
extern char crime_file[];               /* 3276 "crime0.dta " */
extern char world_file[];               /* 3282 "world0.dta" */

/* _DATA, LOADGAME.C */
extern char save_name[];                /* 4834 "a:cv0.sve": [0] drive, [4] slot digit */

/* _BSS */
extern int  cursor;                     /* 5CB6 code name entry (NEWCHAR.C) */
extern int  cursor_w;                   /* 5CB8 */
extern int  cursor_x;                   /* 5CBA */
extern char num_buf[];                  /* 5CBC itoa scratch (ENDCASE.C) */
extern char report_num_buf[];           /* 5CCC */
extern char career_num_buf[];           /* 5CDC */
extern char vacation_num_buf[];         /* 5CEC */
extern char num_str[];                  /* 5D0C (FAME.C) */
extern char save_num_buf[];             /* 5DE0 (LOADGAME.C) */
extern int  save_loading;               /* 5DF0 select_drive asks for the saved game files */
extern int  save_error;                 /* 5DF2 errno of a failed write, 0 = ok */
extern int  save_fd;                    /* 5DF4 */
extern int  save_level;                 /* 5DF6 a save file's difficulty (word 2Ah) */

/* c_common */
extern unsigned case_items;             /* 7DE2 bit per item the plot moved */
extern int  cur_day;                    /* 7DEA */
extern int  history_len;                /* 7DEC */
extern unsigned items_taken;            /* 7DEE bit per item confiscated */
extern int  plot_num;                   /* 7DF2 current plot (plot_defs); start of the
                                           env.sve player block (ENV.C player_block) */
extern int  plot_episodes;              /* 7DF4 bit per episode already played */
extern int  leader_code;                /* 7DFE the MasterMind's leader code */
extern int  last_episode;               /* 7E00 */
extern int  episode_crime;              /* 7E02 crimeN.dta of the episode */
extern int  world_num;                  /* 7E04 worldN.dta */
extern int  career_points;              /* 7E06 */
extern int  career_rank;                /* 7E18 00nn */
extern char codename[];                 /* 7E6C */
extern unsigned char history[];         /* 7E7C per case: plot/episode, result, EP hi, lo,
                                           leader if arrested; FFh ends */
extern long masterminds_arrested;       /* 807C bit per leader code */
extern unsigned vacation_back;          /* 8082 image handles */
extern unsigned vacation_frames[5];     /* 8084 */
extern unsigned vacation_extra;         /* 808E */
extern int  f_96d6;                     /* 96D6 cleared with the clock at a case start */
extern int  city1, city2;               /* 96DA, 96DC cities of the main roles (env 2Ch, 2Eh) */
extern int  anim_active;                /* 98E0 */
extern int  ep_possible;                /* 9BE8 */
extern int  cur_minute;                 /* 9BEA */
extern int  cur_face;                   /* 9BEE */
extern char save_header[];              /* 9BF0 0x28E bytes at 3F0h of a save file: the
                                           player block of that game */
extern int  save_month;                 /* 9C06 its cur_month */
extern int  save_time;                  /* 9C08 its game_time */
extern char save_where[];               /* 9C0A its city */
extern int  save_rank;                  /* 9C16 its career_rank */
extern char save_codename[];            /* 9C6A its codename */
extern int  cur_hour;                   /* 9E82 */
extern int  anim_enabled;               /* 9E86 */
extern int  rand_seed;                  /* 9E8A (env 3Ch) */
extern int  org2;                       /* 9E94 (env 28h) */
extern int  org3;                       /* 9E98 (env 2Ah) */
extern int  icons[];                    /* 9E9C image handles of icons.pic (FACE.C's
                                           faces_f.. are parts of it) */
extern int  env_var_52;                 /* 9F8C env word 52h */
extern unsigned save_mask;              /* 9F8E bit per slot holding a saved game */
extern unsigned double_agents;          /* 9FA0 bit per organization with a mole (env 4Ah) */
extern int  start_mode;                 /* A5A6 1 first start, -1 back from a game, 0 end of case */
extern int  skill_levels;               /* A7B2 2 bits per skill (env 4Eh) */
extern int  org1;                       /* ABF6 */
extern unsigned case_result;            /* ABFA low bits arrests, 40h crime committed,
                                           80h MasterMind arrested */
extern int  default_sel;                /* AC1C menu item selected first (TEXTWIN.C) */
extern int  city3;                      /* AC1E */
extern struct Item items[4];            /* AC20 (crimeN.dta) */
extern int  num_masterminds;            /* AC68 MasterMinds arrested in the career */
extern int  briefed;                    /* AE32 */
extern int  mission_ended;              /* AE7A */
extern int  save_slot;                  /* B07C */
extern int  env_var_38;                 /* B07E env word 38h */
extern struct Fame hall_of_fame[6];     /* B1C0 */
extern int  ep_earned;                  /* B308 */
extern int  num_participants;           /* B30C suspects without the red herrings */
extern int  scene_vars[];               /* B30E animation script variables (anim_vars in ANIMOBJ.C);
                                           [0] is the briefing's verdict */

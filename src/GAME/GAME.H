/* GAME.H - Covert Action strategic game (GAME.EXE): shared types and globals.
 * Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style, no prototypes
 * for library routines (the original didn't include <string.h>).
 *
 * GAME links the MicroProse library (MPS.H) and the Covert Action game library
 * (GAMELIB.H): their tables (persons, sites, clues, cities, msgs, plots,
 * suspects, orgs, ...) are declared there and used here under the same names.
 * DGROUP offsets in GAME.EXE are given in the comments; tools/rebuild/syms/GAME.txt
 * is generated from this file (tools/rebuild/hsyms.py). */
#include "mps.h"
#include "gamelib.h"

/* Shared game state: COVERT.EXE stores a far pointer to it at 0000:04F0. */
#define ENV (*(unsigned char far * far *)0x4F0L)

/* Byte views of a word field (the original code reads and writes single bytes) */
#define LOBYTE(x) (*(unsigned char *)&(x))
#define HIBYTE(x) (*((unsigned char *)&(x) + 1))

/* One of our agents held in a city (TAC's struct Agent). */
struct Agent {              /* 18 bytes */
    char name[16];          /* +00 */
    char rank;              /* +10 */
    char person;            /* +11 suspect slot he can get at, -1 none */
};

struct diskinfo {           /* _bios_disk request */
    unsigned drive, head, track, sector, nsectors;
    char far *buffer;
};

/* Assembly segment / graphics driver (far) */
extern void far link_driver_stubs();
extern void far drv_play_sound();
extern void far drv_slot9();
extern int  far drv_slot12();
extern void far drv_call_gate();
extern void far drv_draw_image();      /* draws an image (asm entry at 1000:01E3) */

/* MS C runtime */
extern char *strcpy();
extern char *strcat();
extern int  strlen();
extern char *strstr();
extern char *itoa();
extern long lseek();
extern int  errno;                      /* 4F09 */

/* MicroProse and game library routines */
extern void init_face_parts();
extern void load_env();
extern void save_env();
extern void randomize();
extern int  random();
extern int  clamp();
extern void flush_input();
extern int  require_disk();
extern void anim_play_file();
extern void set_scene_var();
extern int  set_scene_background();
extern void load_picture_swapped();
extern void wait_retrace();
extern void clear_play_area();
extern void draw_face_parts();
extern int  wait_key_or_button();
extern void lookup_text();
extern void wrap_text_buffer();
extern void append_person_name();
extern int  append_building_type();
extern void append_number();
extern void clear_location();
extern int  set_location_known();
extern int  pick_clue();
extern int  city_distance();
extern int  org_alert_level();
extern void free_location_if_unused();
extern void format_message_event();
extern void suspect_dossier();

/* GAME's own routines that do not return int */
extern char *format_date_time();

/* ---- globals declared in MPS.H / GAMELIB.H, at their GAME addresses ----
 * GAME.C defines the ones from 0094 to 16c2 (the tables, pages and color maps);
 * the library modules define the rest.  Where a library .C file uses another
 * name for the address it is given in brackets (all of them: syms/GAME.lib.txt).
 *   persons 0094           sites 0494              clues 1094
 *   work_page 1468         back_page 147c          std_colormap 149e
 *   std_colormap2 14ae     tele_colors 14fe        face_colormap 151e
 *   first_names 1c2a       last_names 1d2a
 *   teletype_shapes 1e22   clue_kind_names 2b3e    bitcount 2b9e
 *   month_names 2bbe       rank_names 3022         number_prefix 3042
 *   clue_method_names 317c clue_keywords 31b8      subst_keys 3a10
 *   subst_vals 3a1e        anim_handle 42fa        cur_drive 42fc
 *   screen_width 42fe      g_gfx 436e              itoa_buf 5514
 *   msg_key 5554           text_buf 7202           difficulty 7604
 *   clock_base 7608        mm_known 760e           mm_org 7610
 *   mm_city 7612           mm_id 7614              cur_month 7620
 *   player_name 7634       player_org_name 765c    rnd_seed 7898
 *   options 789a           is_cga 789c             cities 7a9e
 *   num_persons 7cc0       msgs 7cc2               face_shown 83c2 [portrait]
 *   popup_flag 83c4        plots 83c6              num_msgs 8ec6
 *   num_sites 8ece         game_time 8ed0          menu_flag 93ec
 *   num_plots 9688         clue_icon 968c          msg_day 9690
 *   faces_f 969c           faces_m 96ec            face_part_imgs 973c
 *   face_hair 975c         face_extra_m 976c       face_img_a 9774
 *   face_img_b 9776        face_img_c 9778         face_img_d 977a
 *   face_extra_f 977c      num_suspects 97a2       suspects 97a6
 *   portrait_x 9fac        dossier_state 9fae [paused] (GAME: 1 = leaving / saving)
 *   portrait_y 9fb2        orgs 9fb4               default_sel a410
 *   subst_tail a45e        suspect_state a55e      video_mode a61e
 *   here_city a626         city_clue_count a628    org_clue_count a648
 *   seen_orgs a668         here_org aa58
 * Notes: game_time counts days (process_events increments it every midnight);
 * clock_base is the clock in minutes.  faces_f also holds the icons draw_sprite_a
 * shows.  anim_handle is also the picture on the back page (-1: none). */
extern int cur_drive;                   /* 42fc TEXTWIN: DOS drive, -1 not yet asked */
extern int anim_handle;                 /* 42fa TEXTWIN */
extern int menu_flag;                   /* 93ec show_menu: keep the menu on screen */
extern int portrait_x, portrait_y;      /* 9fac, 9fb2 */
extern int default_sel;                 /* a410 */

/* ---- GAME.C: game state and tables (initialized data) ---- */
extern int jailbreak_person;            /* 1454 env +42: suspect to free from jail, -1 no one */
extern RastPort work_rp, back_rp;       /* 1456, 146a pages 2 and 1 (work_page, back_page) */
extern char colormap_147e[], colormap_148e[];   /* 147e, 148e color maps nothing refers to */
extern char colormap_14be[], colormap_14ce[];   /* 14be, 14ce */
extern char colormap_14de[], colormap_14ee[];   /* 14de, 14ee */
extern char colormap_150e[], colormap_153e[];   /* 150e, 153e */
extern char colormap_154e[];            /* 154e */
extern char hq_colors[];                /* 155e color maps for the scenes */
extern char intel_colors[];             /* 156e */
extern char crypto_colors[];            /* 157e */
extern char data_colors[];              /* 158e */
extern char escape_colors[];            /* 159e */
extern char capture_colors[];           /* 15ae */
extern char binos_colors[];             /* 15be */
extern char building_colors[][16];      /* 15ce per kind of building */
extern char intrgate_colors[];          /* 161e */
extern char default_colors[];           /* 162e */
extern char wounded_colors[];           /* 163e */
extern char followed_colors[];          /* 164e */
extern char bugcar_colors[];            /* 165e */
extern char jail_colors2[];             /* 166e */
extern char jail_colors[];              /* 167e */
extern char briefing_colors[];          /* 168e */
extern char bustout_colors[];           /* 169e */
extern char status_colormap[];          /* 152e */
extern char game_palette[];             /* 16ae */
extern int  cur_disk;                   /* 16c0 game disk in the drive */
extern char anim_file[];                /* 16c2 "animation.pan" */

/* ---- the travel map (TRAVEL, BRIEFING) ---- */
extern char heading_dx[8], heading_dy[8];   /* 2750, 2758 */
extern char headings[3][3];             /* 2760 heading for sign(dx), sign(dy) */
extern int  city_pic_w, city_pic_h;     /* 8ed6, 8eda size of the loaded city picture */
extern int  shown_pic_w, shown_pic_h;   /* 5510, 5512 */

/* ---- the clock and the status bar (TIME) ---- */
extern char date_str[];                 /* 3cf8 "00:00 AM Jun 00" */
extern int  status_y;                   /* 3d0c status bar position */
extern int  tab_colors[];               /* 3d24 */
extern int  list_sel;                   /* 3d2c */
extern int  clock_minute;               /* 93ea */
extern int  clock_hour;                 /* 9682 */
extern int  clock_day;                  /* 7606 */
extern int  hiding_target;              /* 557e */
extern int  mastermind;                 /* 5580 */
extern int  time_unused;                /* 3c84 never referenced */

/* ---- the city (CITY) ---- */
extern char scene_name[];               /* 54dc */
extern int  left_building;              /* 54ec leave the building screen (also after a prisoner exchange) */
extern int  cia_proximity;              /* 54ee */
extern int  clear_pending;              /* 93ee not -1: show_menu clears the screen and redraws the status bar first */
extern int  first_visit;                /* 9686 */
extern int  alert_org;                  /* 9694 */
extern int  menu_count;                 /* 969a lines in menu_items */
extern int  heat;                       /* 978c env +52: general alertness */
extern unsigned mole_cities;            /* 97a0 env +4A: bit per city whose CIA contact is a double agent */
extern int  briefing_done;              /* a3e8 the mission briefing was shown (or we arrived by travel) */
extern int  city_exit;                  /* a3ee why the city loop ended */
extern struct Agent agents[];           /* a414 */
extern int  last_exit;                  /* a624 env +7: how we got here */
extern int  in_building;                /* a66a set while time passes off the street */
extern int  menu_items[];               /* a9b0 menu line -> item */

/* ---- data files (SCREENS) ---- */
extern char num_str[];                  /* 5524 */

/* ---- load / save (OFFICE) ---- */
extern char save_name[];                /* 3fa4 "a:cv0.sve": [0] drive, [4] slot digit */
extern char num_buf[];                  /* 5596 */
extern int  save_loading;               /* 55a6 select_drive asks for the load disk */
extern int  save_error;                 /* 55a8 errno of a failed write, 0 = ok */
extern int  save_fd;                    /* 55aa */
extern int  save_rank;                  /* 55ac word 2Ah of a save file: 0 local .. 3 global */
extern char save_header[];              /* 93f0 0x28E bytes at 0x3F0 in a save file */
extern int  save_month;                 /* 9406 */
extern int  save_time;                  /* 9408 */
extern char save_where[];               /* 940a */
extern int  save_score;                 /* 9416 */
extern char save_player[];              /* 946a */
extern unsigned save_mask;              /* 978e bit per slot with a save file */
extern int  save_slot;                  /* a86c */

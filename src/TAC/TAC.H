/* TAC.H - Covert Action building infiltration (TAC.EXE): shared types and globals.
 * DGROUP offsets of the original are given in the comments. Library globals
 * (g_gfx, options, bios_regs, back_page) come from MPS.H. */

/* TAC's own INT 10h register block (the library's bios_regs is a separate one) */
extern union { struct { unsigned char al, ah; } h; } tac_regs;

/* Shared game state: COVERT.EXE stores a far pointer to it at 0000:04F0. */
#define ENV (*(unsigned char far * far *)0x4F0L)
/* BIOS keyboard flags at 0040:0017 (20h = NumLock) */
#define KBD_FLAGS (*(unsigned char far *)0x00400017L)

/* A person in the plot (suspect); slot 0 is the mastermind. */
struct Person {         /* 0x10 bytes */
    int org;            /* +0 */
    int id;             /* +2 */
    int city;           /* +4 */
    unsigned known;     /* +6 1 photographed */
    int clues;          /* +8 clue bits held */
    int found;          /* +A clue bits found */
    int points;         /* +C */
    int status;         /* +E negative: caught or dead (-3: still usable) */
};

/* An organization site we know about. */
struct Site {           /* 0x0C bytes */
    int org;            /* +0 */
    int city;           /* +2 */
    unsigned flags;     /* +4 */
    int f6;
    long rooms_seen;    /* +8 bit per room of the building already explored */
};

struct City {           /* 0x22 bytes */
    char name[0x1c];
    unsigned orgs_known;/* +1C bit per organization */
    int f1e, f20;
};

struct Org {            /* 0x24 bytes (GAMELIB's struct Org) */
    char abbrev[6];
    char name[0x1E];
};

/* An agent of ours (or a role in the plot), possibly held in a city. */
struct Agent {          /* 0x12 bytes */
    char name[0x10];
    char rank;          /* +10 */
    char person;        /* +11 -1: none */
};

/* Kinds of room ("Office", ...) */
struct RoomType {       /* 0x16 bytes */
    char name[0x10];
    int value;          /* +10 worth of a photo or bug; tries a guard makes to find something to look at */
    unsigned sizes;     /* +12 1 small, 2 medium, 4 large */
    unsigned modes;     /* +14 matched against room_type_filter */
};

/* Kinds of object in a map cell ("Wall", "Door", "Chair", ...) */
struct ObjType {        /* 0x14 bytes */
    char name[0xc];
    int sx, sy;         /* +C sprite position on the sprite page */
    unsigned flags;     /* +10 1 solid, 2 opens, 4 bug, 8 photo, 10h door/passable, 20h blocks sight,
                           40h two cells wide, 100h against a wall, 200h terminal */
    unsigned rooms;     /* +12 bit per room type it may stand in */
};

/* A room of the building. */
struct Room {           /* 0x0E bytes */
    char x, y, w, h;    /* +0 in map cells */
    long links;         /* +4 bit per room a door leads to */
    unsigned flags;     /* +8 1 removed, 2 seen, 4 map visible / bugged, 8 guards alerted, 10h gas / lights out */
    int type;           /* +A index into room_types */
    int dist;           /* +C doors from the noise source, -1 unreached */
};

/* A door between two rooms (room 0 = outside). */
struct Door {           /* 5 bytes */
    char room_a, room_b;    /* +0, +1 */
    char x, y;              /* +2 map cell */
    char dir;               /* +4 */
};

/* A guard (0 = Max). */
struct Guard {          /* 0x1C bytes */
    unsigned flags;     /* +0 80h on the map, 1 going through a door, 2 ?, 4 halted / sneaking,
                           8 guarding (Max: 4 armored) */
    int x, y;           /* +2 pixels (16 per map cell) */
    int tx, ty;         /* +6 map cell the guard is walking to, -1 none */
    int anim;           /* +A walk animation */
    int dir;            /* +C 1-8 */
    int mode;           /* +E Max: 1 walk, 2 examine, 4 dive */
    int firing;         /* +10 */
    int room;           /* +12 */
    int wait;           /* +14 frames to stand still */
    int spotted;        /* +16 how long the guard has seen Max */
    int heard;          /* +18 how long the guard has heard noise */
    int stun;           /* +1A gas / stun level: 24+ dazed, 999+ out, 9999 knocked down */
};

/* A grenade, trap or explosion. */
struct Projectile {     /* 0x0A bytes */
    int x, y;           /* +0 pixels */
    int dir;            /* +4 */
    int timer;          /* +6 >0 flying, <0 exploding, -63 detonate, -9999 trap, -9998 remote control */
    int type;           /* +8 0 grenade, 1 gas, 2 stun; 80h Max's; -1 free */
};

struct Rect {
    int x0, y0, x1, y1;
};

/* Cursor moves between the items of the equipment room. */
struct Nav {
    int up, down, left, right;
};

struct Pos {
    int x, y;
};

/* Mission */
extern int tac_mode;                /* a1e4 0 break-in, 1 kidnap (env 7), 2 rescue (env 8), 3 bomb (env 10) */
extern int env_flags;               /* c600 env +4E: bits 0-1 skill, 8-9 game speed */
extern int game_speed;              /* 1bc8 0 slow, 1 normal, 2 fast */
extern int difficulty;              /* 91e0 */
extern int orig_difficulty;         /* cf42 as passed in by the game */
extern int alert_level;             /* 8dd0 env +48 */
extern int target_person;           /* bddc suspect inside the building, -1 none */
extern struct Person persons[];     /* 06fe */
extern int n_persons;               /* a1e2 */
extern struct Site sites[];         /* 0afe */
extern struct City cities[];        /* 9e18 */
extern struct Org orgs[];           /* c604 */
extern struct Agent agents[];       /* c99e */
extern int n_clues;                 /* bdf2 */
extern unsigned known_plans;        /* cbfc */
extern int cur_org, cur_city;       /* d48a, cbba building being entered */
extern unsigned clock_base;         /* 91e8 minutes (the game library's clock_base) */
extern int hour;                    /* bb62 */
extern int is_night;                /* 91de */
extern int real_mission;            /* bb66 always 1: show the face, photos give information */
extern unsigned game_seed;          /* bb74 */
extern unsigned raided_cities;      /* bdf0 bit per city */
extern int on_alert;                /* bb6a the building expects a raid */
extern int mission_over;            /* c86c */
extern int mission_flags;           /* bb7a env byte 10: 1 evidence taken, 2 arrested, 4 double agent,
                                       bit 4 -> env byte 13 */
extern int result_score;            /* c9e6 env byte 8 */
extern int violence;                /* cbb8 env byte 9: explosions, guards knocked out, shots at Max */
extern int guards_left;             /* cf88 guards still to come; env byte 9 is clamped to guards_left * 10 */
extern int wounds;                  /* cbac env byte 11 */
extern int frame_count;             /* a8ec env byte 15 = frame_count / 60 */
extern int message_shown;           /* c5fe */
extern int photos_taken;            /* a038 */
extern int photo_score;             /* 8dd2 */
extern int bugs_planted;            /* a8ea */
extern int bug_score;               /* bb58 */
extern int file_items[8];           /* 1f36 */
extern char *item_names[];          /* 20e0 */
extern char password[];             /* c846 */
extern char password_shown[];       /* c98c letters found so far, '.' for the others */

/* Pages, pictures and sound */
extern int page3;                   /* 1c24 */
extern int camera_img, camera_img2; /* 9b6e, 9b70 */
extern RastPort *sprite_page;       /* 06d4 */
extern RastPort *display_page;      /* 06e8 */
extern RastPort *work_page;         /* 06fc */
extern char tac_colormap[];         /* 1ba8 */
extern char terminal_colormap[];    /* 1b98 */
extern char tune_data[][17];        /* 1bce */
extern int sfx_tempo, sfx_variant;  /* cbb2, cbb6 drv_play_sound parameters */
extern int tune_on;                 /* 8dd8 */
extern int mono_display;            /* 9b6c */
extern int actor_imgs[];            /* bb8c */
extern int sprite_imgs[];           /* bc7c 8 rows of 20 sprites from sprites.pic */
extern int icon_imgs[6];            /* bdbc */
extern int cursor_img;              /* bdc8 */
extern int icon2_imgs[8];           /* bdcc */
extern int hit_flash_image;         /* a058 */
extern char hit_colors[];           /* 1c8c */
extern int flash_active;            /* 1c8a */
extern int flash_who;               /* 4314 */
extern int flash_x, flash_y;        /* 4316, 4318 */

/* The building */
extern int n_rooms;                 /* b3fa */
extern struct Room rooms[];         /* a05e */
extern struct RoomType room_types[];    /* 00b2 */
extern struct ObjType obj_types[];  /* 018e */
extern int room_type_filter;        /* 1bca */
extern char building[][32];         /* 91ee object in each map cell: 3fh type, 40h done, 80h open */
extern char room_map[][32];         /* b40a room number of each map cell */
extern char wall_map[][32];         /* cf8a wall bits per map cell: 1, 2, 4, 8 */
extern char wall_cells[];           /* 1ff0 building cell for each combination of wall bits */
extern struct Door doors[];         /* 96f8 */
extern int n_doors;                 /* cf46 */
extern int room_doors[];            /* 4354 doors per room */
extern int door_dx[], door_dy[];    /* 06ae, 06b8 per door direction */
extern int start_room;              /* b912 the target's room */
extern int post_room;               /* 96ee */
extern int cur_room;                /* bdde */
extern int goal_room;               /* c86e */
extern int room_none;               /* 2032 */
extern int room_noise[];            /* a1ae frame a guard last headed for each room */
extern int room_dist[];             /* b91a */
extern int room_alert;              /* 430a guards down in the current room */
extern int doors_open;              /* a1de objects opened in the current room */

/* Max */
extern int max_x, max_y;            /* bb72, bb7c position in pixels (16 per map cell) */
extern int cell_x, cell_y;          /* b3fc, b408 map cell */
extern int front_x, front_y;        /* b406, b90c map cell in front of Max */
extern int max_dir, want_dir;       /* 1c42, 1c44 */
extern int max_moved;               /* bb82 */
extern unsigned equipment;          /* 9b72 bit per item of the equipment room: 4 camera, 8 bugs,
                                       20h gas mask, 40h disguise */
extern int ammo, clips, bugs_left;  /* 96f6, 8dd6, bb6e rounds in the gun, spare clips, bugs */
extern int grenades[3];             /* b94c of each kind */
extern int cur_grenade;             /* 9d76 */
extern int player_mode;             /* b90e 1 walk, 2 examine, 4 dive */
extern int player_moving;           /* bb56 */
extern int player_anim;             /* bb64 */
extern int sneaking;                /* bb60 */
extern int sneak_steps;             /* 96f2 */
extern int disguised;               /* 91dc wearing a guard's uniform */
extern int fire_timer;              /* 96f4 */
extern int dive_count;              /* 91ec */
extern int throw_delay;             /* a8e8 */
extern int made_noise;              /* cf44 Max acted in front of the target */
extern int last_key;                /* 4312 */
extern int key_repeat;              /* 4310 */
extern int joy_dir_keys[];          /* 1c78 */

/* Guards */
extern struct Guard guards[];       /* c870 */
extern char guard_paths[][40][32];  /* 438e per guard: steps to its target cell */
extern int step_dx[9], step_dy[9];  /* 0666, 0678 walking step per direction 1-8 */
extern int dir_dx[9], dir_dy[9];    /* 068a, 069c unit step / neighbour cell per direction 1-8 */
extern int dir_from_sign[3][3];     /* 2020 direction for [sign dx + 1][sign dy + 1] */
extern int last_at_goal;            /* 91da guards_at_goal of the previous frame */
extern int guards_at_goal;          /* 96f0 */
extern int guard_in_room;           /* b402 */
extern int guards_near;             /* cbbc */
extern int guards_active;           /* cbaa */
extern int max_heard;               /* b3f4 */
extern int guard_saw_max;           /* b3f8 */
extern int see_bits;                /* bb70 line_of_sight: 1 near half visible, 2 far half */
extern int last_seen_x, last_seen_y;    /* a03a, a05c map cell where Max was last noticed */
extern int alarm_timer;             /* 91ea */
extern int alarm_heard;             /* bb6c */
extern int last_disguised, last_dark;    /* 430c, 430e status bar colours last drawn for */
extern int alarm_color;             /* c998 */
extern int last_grenade;            /* 708e */
extern struct Projectile projectiles[16];   /* 9d78 */
extern unsigned char queue_x[], queue_y[];  /* 709a, 719a path search queue (256) */

/* Screen */
extern int view_x0, view_y0;        /* c5fa, c602 screen position of the room's top left cell */
extern int room_left, room_top, room_right, room_bottom;   /* b910, b916, 9b6a, 9b74 room bounds in pixels */
extern int actor_x[9], actor_y[9];  /* 42e6, 42f8 where each actor was drawn, -1 none */
extern int actor_map_x[9], actor_map_y[9];  /* 42c2, 42d4 dots on the floor plan */
extern char msg_buf[];              /* 8dda */
extern char num_buf[];              /* 42b8 */
extern char film_buf[];             /* 729a */
extern int popup_x, popup_y;        /* 91e2, 91e6 draw_intercept_popup position */
extern int popup_face;              /* a8e6 portrait, -2 the camera image */
extern int cursor_pos;              /* 4334 terminal_input cursor */
extern int cursor_w, cursor_x;      /* 4336, 4338 */
extern int equip_images[];          /* a03c item images cut from equip2.pic */
extern struct Rect equip_pic_rects[];   /* 2194 where in equip2.pic */
extern struct Rect equip_rects[];   /* 220c items on the equipment room screen */
extern struct Nav equip_nav[];      /* 2100 */
extern struct Pos panel_icons[];    /* 2160 panel position of each item image */

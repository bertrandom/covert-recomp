/* GAMELIB.H - the Covert Action game library's shared tables and globals
 * (used by GAME, TAC, FINAL and BUG).  One view of every table; DGROUP
 * offsets in BUG.EXE are given in the comments.  K&R, MSC 5.1. */

/* A person (64 slots, 0x172).  Slot 0 is the mastermind. */
struct Person {             /* 16 bytes */
    int org;                /* +0 organization */
    int id;                 /* +2 random code, 0 = free slot: bit 0 sex,
                               bits 1-4 first name, 5-8 last name; also the face */
    int city;               /* +4 */
    unsigned known;         /* +6 what we know: 1 photo, 2 name, 4 org, 8 city,
                               10h participant, 20h more, 100h rank, 200h/400h recruiting */
    unsigned flags;         /* +8 site flags, 7FFFh = active */
    unsigned roles;         /* +A bit per suspect slot whose role he has */
    int points;             /* +C information gathered (FINAL: the known flags
                               from before the debriefing, see known_before) */
    int fate;               /* +E -1 arrested, -2 in hiding, -3 turned */
};

/* An organization site we know about (256 slots, 0x572). */
struct Site {               /* 12 bytes */
    int org;                /* +0 */
    int city;               /* +2 */
    unsigned flags;         /* +4 */
    int strength;           /* +6 wiretap / surveillance level, percent (GAME) */
    int f8, fa;
};

/* A clue found (80 slots, 0x1172). */
struct Clue {               /* 12 bytes */
    char org;               /* +0 organization the clue came from, -1 = free */
    char city;              /* +1 city it was found in */
    int suspect;            /* +2 suspect index, -1 = free slot */
    int kind;               /* +4 (kind << 8) | value */
    int text;               /* +6 (text flags << 8) | text number */
    int pad[2];
};

/* A city (16, 0x5E32). */
struct City {               /* 34 bytes */
    char name[12];          /* +00 */
    char country[12];       /* +0C */
    int code;               /* +18 low nibble x, high nibble y */
    int size;               /* +1A */
    unsigned orgs_known;    /* +1C bit per organization */
    unsigned orgs_visited;  /* +1E bit per organization contacted today (GAME) */
    unsigned char map_x;    /* +20 */
    unsigned char map_y;    /* +21 */
};

/* An intercepted message (0x6058, 128 slots). */
struct Msg {                /* 14 bytes */
    int type;               /* +0 0 message, else a chronology event (FINAL's
                               timeline: 1 left a city, 4 travel, 5 break-in,
                               6 arrest, 7 confiscation, 8 hiding, ...), -1 none */
    int time;               /* +2 minutes */
    int msg;                /* +4 plot step (index into plots), <0: generic */
    unsigned flags;         /* +6 bits 0-3 revealed details, 8000h decoded */
    int level;              /* +8 */
    char sender;            /* +A person */
    char sender_city;       /* +B */
    char receiver;          /* +C person */
    char receiver_city;     /* +D */
};

/* A step of the plot (0x6760). */
struct Plot {               /* 44 bytes */
    char suspect;           /* +00 suspect slot doing it, -1 ends crimeN.dta's list */
    char f1;
    int state;              /* +02 day it happened, 999 = due (the final crime) */
    int msg;                /* +04 message number */
    char name[32];          /* +06 */
    int flags;              /* +26 low byte: suspect slot receiving; 100h done,
                               200h message, 400h package, F00h kind, 2000h no sender */
    int items;              /* +28 bits 0-3: gets item n, bits 8-11: uses it up (GAME: the
                               parties taking part) */
    int severity;           /* +2A crime points when it happens */
};

/* A suspect: a role in the master plan (0x77B4). */
struct Suspect {            /* 48 bytes */
    int person;             /* +00 */
    int importance;         /* +02 */
    char name[32];          /* +04 role */
    unsigned char info;     /* +24 low byte of the random identity word
                               (FINAL.H suspect_id) */
    char f25;
    unsigned flags;         /* +26 100h: not shown on the master plan */
    unsigned found;         /* +28 clue kinds already revealed */
    int type;               /* +2A low byte: clue text set */
    int rank;               /* +2C */
    int f2e;
};

struct SuspectState {       /* 6 bytes per suspect (0x8378) */
    int time;               /* +0 */
    int progress;           /* +2 */
    int f4;
};

/* An organization (16, 0x7FC0). */
struct Org {                /* 36 bytes */
    char abbrev[6];         /* +00 */
    char name[20];          /* +06 */
    int home;               /* +1A city code of the headquarters */
    int strength;           /* +1C */
    int range;              /* +1E */
    unsigned flags;         /* +20 1 = known; in worldN.dta (FINAL) the leader code */
    char nationality;       /* +22 */
    char f23;
};

/* One entry of a shape list (0x2B62). */
struct shape {              /* 12 bytes */
    int type;               /* 0 line, 1 filled box, 2 repeat, 3 box outline, -1 end */
    int x1, y1, x2, y2;     /* repeat: dx, dy, count, entries back */
    int color;              /* repeat: running flag */
};

extern struct Person persons[];         /* 0172 */
extern struct Site sites[];             /* 0572 */
extern struct Clue clues[];             /* 1172 */
extern struct City cities[];            /* 5E32 */
extern struct Msg msgs[];               /* 6058 */
extern struct Plot plots[];             /* 6760 */
extern struct Suspect suspects[];       /* 77B4 */
extern struct Org orgs[];               /* 7FC0 */
extern struct SuspectState suspect_state[]; /* 8378 */
extern struct shape teletype_shapes[];  /* 2B62 */

extern int num_persons;                 /* 6054 */
extern int num_msgs;                    /* 7260 */
extern int num_sites;                   /* 7268 */
extern int num_plots;                   /* 7638 */
extern int num_suspects;                /* 77B0 */
extern int difficulty;                  /* 1652 0..3; the last 4*difficulty suspects are unused */

extern unsigned mm_known;               /* 5996 the mastermind's slot 0 defaults */
extern int mm_org;                      /* 5998 */
extern int mm_city;                     /* 599A */
extern int mm_id;                       /* 599C */
extern int cur_month;                   /* 59A8 */
extern char player_name[];              /* 59BC */
extern char player_org_name[];          /* 59E4 */
extern int here_city;                   /* 8C0E where the player is */
extern int here_org;                    /* 8FD8 */
extern int game_time;                   /* 726A minutes */
extern unsigned clock_base;             /* 594A minutes */
extern char clock_str[];                /* 2B4A "00:00:00" */
extern int msg_day;                     /* 7640 two-digit text section number */
extern int city_clue_count[];           /* 8C10 */
extern int org_clue_count[];            /* 8C30 */
extern unsigned seen_orgs;              /* 8C50 bit per organization whose file was viewed */
extern int dossier_state;               /* 7FBC */
extern int popup_flag;                  /* 675E */
extern int face_shown;                  /* 6758 face to show, -1 none, -2 building */
extern int clue_icon;                   /* 763C */
extern int is_cga;                      /* 5C2C */
extern char video_mode;                 /* 8438 'C' = CGA */

extern char text_buf[];                 /* 5542 assembled text */
extern char itoa_buf[];                 /* 3A0E */
extern char msg_key[];                  /* 3A2E "*MSG0000" etc. */
extern char *subst_keys[];              /* 230E placeholders replaced by text_substitute */
extern char *subst_vals[];              /* 231C */
extern char subst_tail[];               /* 8278 scratch for text_substitute */
extern char *clue_keywords[];           /* 20BA */
extern char *clue_method_names[];       /* 207E */
extern char *clue_kind_names[];         /* 1A40 */
extern char *number_prefix[][8];        /* 1F44 */
extern char *rank_names[];              /* 1F24 */
extern char *month_names[];             /* 1AC0 */
extern char bitcount[];                 /* 1AA0 bits set in 0..31 */
extern char *first_names[2][64];        /* 296A */
extern char *last_names[];              /* 2A6A */

extern char std_colormap[];             /* 157C */
extern char std_colormap2[];            /* 158C */
extern char tele_colors[];              /* 15DC color map while the teletype is shown */
extern char face_colormap[];            /* 15FC */
extern RastPort *work_page;             /* 1546 */
extern int face_part_imgs[16];          /* 76EC small 8x8 face overlays */
extern int faces_f[40];                 /* 764C female heads (facesf.pic) */
extern int faces_m[40];                 /* 769C male heads (faces.pic) */
extern int face_hair[7];                /* 770C */
extern int face_extra_m[4];             /* 771C */
extern int face_img_a, face_img_b, face_img_c, face_img_d; /* 7724.. */
extern int face_extra_f[4];             /* 772C */

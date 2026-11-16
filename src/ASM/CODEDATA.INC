; CODEDATA.INC - the rest of SEG0A's _DATA in CODE.EXE (DGROUP 006C-1041): notes
; from the MicroProse graphics library's documentation, unused, then the colour maps
; that CODE.C and TEXTWIN.C use, and a table of pointers to the notes.
	PUBLIC	_std_colormap, _std_colormap2, _colormap

note0	db	'The MicroProse Graphics Library is intended to be a collection of high quality routines',0
note1	db	'To perform the primitive graphic functions normally required in our games.',0
note2	db	'The routines are combined together to form a consistent interface between the '
	db	'applications.',0
note3	db	'As much as possible, graphics adapter specific logic has been hidden.To make the '
	db	'underlying hardware transparent to the user.',0
note4	db	'Each game will of necessity embellish the library with custom features.',0
note5	db	'Hopefully the library will at least provide the required primitives.',0
note6	db	'Many of the C-callable graphics routines get their parameters from a RastPort.',0
note7	db	'A RastPort is a definition of a window into a screen.',0
note8	db	'It defines the boundaries of that window for clipping and relative addressing.',0
note9	db	'As well as maintaining current pen colors and font info for text drawing.',0
note10	db	'The file RastPort contains a definition of the structure.',0
note11	db	'Map a graphic page to a memory segment.',0
note12	db	'Returns library specific data parameters one at a time.',0
note13	db	'Programs would have an include file with defines for the indexes.Conceptually, this '
	db	'facility should be for static data only.',0
note14	db	'Load in the selected overlay and setup vector table.',0
note15	db	'This is a software only function.',0
note16	db	'To load the new palette into the hardware registers, a SetPalette'
	db	9,'is required.',0
note17	db	'Set video mode for this library plus any other library specific initialization',0
note18	db	'The mode argument is the same value used for LibCanDo.',0
note19	db	'And is unused in libraries supporting',9,'a single video mode.',0
note20	db	'Determine what graphics modes are supported in the hardware.',0
note21	db	'Returns a code for the highest performance video system found.',0
note22	db	'It would be nice if this code was used system-wide.',0
note23	db	'This group of functions operate on entire graphic pages.',0
note24	db	'Display the selected graphics page on the CRT.',0
note25	db	'Otherwise a blast is performed, overwriting the data previously in video memory.',0
note26	db	'Display the selected graphics page on the CRT.',0
note27	db	'Otherwise a non-destructive ShowPage is performed, swapping the data with the video '
	db	'buffer.',0
note28	db	'A random dissolve is performed from',9,'page to the current video page.',0
note29	db	'This is a destructive copy in all video modes.',0
note30	db	'This group of functions operate on windows of graphic pages.',0
note31	db	'Copy a window from one graphics page to another.',0
note32	db	'Fill a window in a RastPort with a color.',0
note33	db	'These routines read a picture from a disk file into a graphics page.',0
note34	db	'Any conversion or decompression is performed automatically.',0
note35	db	'Currently two file formats are supported: IFF for development and CRUNCHED for production.',0
note36	db	'The picture file contains color palette data that is loaded as well.',0
note37	db	'For color pictures, the palette is 16 color values stored in bytes.',0
note38	db	'With the upper nibble being blank.',0
note39	db	'The following are used internally by LoadPicture.',0
note40	db	'The following code illustrates the intended usage.',0
note41	db	'Sprites are defined by a structure and are passed as arguments with pointers to that '
	db	'structure.',0
note42	db	'The header of the structure defines the size of the sprite and other parameter data.',0
note43	db	'Following the header is the compressed picture data.',0
note44	db	'Each scan line is defined by two size bytes and the variable length data.',0
note45	db	'The first size byte gives the relative offset to the first non-blank pixel.',0
note46	db	'The second size byte gives the length of data following.',0
note47	db	'There was a conceptual problem with building sprites off-line.',0
note48	db	'But I can''t remember what it is.',0
note49	db	'Sprites can be built online or offline.',0
note50	db	'An off-line sprite compiler will allow sprites to be extracted from graphic images.',0
note51	db	'Formed into structures and saved in disk files.',0
note52	db	'An on-line facility will exist to perform the same function at the expense of longer load '
	db	'times.',0
note53	db	'Sprites contain the destination page for writing and display.',0
note54	db	'Sprites ALWAYS exist in real memory and are in pixel format.',0
note55	db	'It is still an open issue as to whether or not a separate mask plane is required.',0

; colour maps (pairs of dither colours per palette entry)
	db	0,0,0,1,0,2,0,0,2,0,1,3,1,2,1,0
	db	3,0,1,11h,11h,2,0,2,3,30h,11h,13h,31h,22h,23h,33h
	db	33h
_std_colormap	db	0,0,1,0,2,0,0,2,0,1,2,3,2,1,1,3
_std_colormap2	db	0,0,11h,11h,22h,0,0,22h,0,22h,33h,33h,22h,11h,22h,33h
	db	0,0,11h,11h,22h,22h,22h,22h,0,22h,33h,33h,0,0,11h,33h
	db	0,22h,0,0,0,0,0,0,0,22h,22h,0,0,0,11h,33h
	db	0,12h,11h,10h,11h,0,12h,33h,22h,13h,33h,11h,33h,22h,33h,33h
	db	0,12h,0,0,22h,0,0,13h,2,11h,0,0,0,0,33h,33h
	db	0,11h,11h,11h,22h,0,22h,12h,0,11h,11h,33h,33h,22h,33h,33h
_colormap	db	0,11h,11h,11h,22h,0,22h,12h,0,11h,11h,33h,33h,22h,33h,33h
	db	0,11h,11h,1,22h,0,22h,22h,0,11h,11h,33h,33h,33h,33h,33h
	db	0,0,11h,11h,22h,0,0,11h,22h,22h,33h,33h,22h,11h,22h,33h
	db	0,0,11h,11h,22h,0,0,22h,0,22h,33h,33h,22h,11h,22h,33h
	db	0,0,11h,11h,22h,0,0,33h,22h,22h,11h,33h,22h,33h,22h,33h

; the notes, in order
	dw	offset DGROUP:note0, offset DGROUP:note1, offset DGROUP:note2, offset DGROUP:note3
	dw	offset DGROUP:note4, offset DGROUP:note5, offset DGROUP:note6, offset DGROUP:note7
	dw	offset DGROUP:note8, offset DGROUP:note9, offset DGROUP:note10, offset DGROUP:note11
	dw	offset DGROUP:note12, offset DGROUP:note13, offset DGROUP:note14, offset DGROUP:note15
	dw	offset DGROUP:note16, offset DGROUP:note17, offset DGROUP:note18, offset DGROUP:note19
	dw	offset DGROUP:note20, offset DGROUP:note21, offset DGROUP:note22, offset DGROUP:note23
	dw	offset DGROUP:note24, offset DGROUP:note25, offset DGROUP:note26, offset DGROUP:note27
	dw	offset DGROUP:note28, offset DGROUP:note29, offset DGROUP:note30, offset DGROUP:note31
	dw	offset DGROUP:note32, offset DGROUP:note33, offset DGROUP:note34, offset DGROUP:note35
	dw	offset DGROUP:note36, offset DGROUP:note37, offset DGROUP:note38, offset DGROUP:note39
	dw	offset DGROUP:note40, offset DGROUP:note41, offset DGROUP:note42, offset DGROUP:note43
	dw	offset DGROUP:note44, offset DGROUP:note45, offset DGROUP:note46, offset DGROUP:note47
	dw	offset DGROUP:note48, offset DGROUP:note49, offset DGROUP:note50, offset DGROUP:note51
	dw	offset DGROUP:note52, offset DGROUP:note53, offset DGROUP:note54, offset DGROUP:note55

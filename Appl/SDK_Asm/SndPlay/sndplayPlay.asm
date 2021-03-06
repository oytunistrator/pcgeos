COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS	

MODULE:		SndPlay

FILE:		sndplayPlay.asm

AUTHOR:		Todd Stumpf, Jun 10, 1993

ROUTINES:
	Name				Description
	----				-----------
	SoundPlayInitializeVoice	Allocate sound stream
	SoundPlayCloseVoice		Free the sound stream
	SoundPlayClearVoice		set all the voices to off
	SoundPlayToMusicStream		write an event to the stream
	SoundPlayPlayEvent		
	SoundPlayPlayNextNote
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/10/93   	Initial revision


DESCRIPTION:
		

	$Id: sndplayPlay.asm,v 1.1 97/04/04 16:32:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata			segment

	;
	;  In order to generate sound, we need to use the sound
	;  library.  One of the things the sound library will do
	;  for us is allocate a block to manage the sounds we
	;  produce.  We store the handle for this block in DGROUP
	;  so we can refer to it easily.

soundVoiceHandle		hptr.SoundControl

udata			ends

InitCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayInitializeVoice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up stream to play notes

CALLED BY:	SndPlayOpenApplication

PASS:		ds	= dgroup (udata)

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Allocates a SoundStream

PSEUDO CODE/STRATEGY:
		Allocate Sound Stream
		Store Handle in udata

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayInitializeVoice	proc	near
	uses	ax, bx, cx, dx, si
	.enter
	;
	;  Call the Sound Library and request a Music Stream
	;  so we can play notes.
	mov	ax, MUSIC_STREAM_SIZE			; small, really small
	mov	bx, STANDARD_PRIORITY			; low priority
	mov	cx, NUM_OF_VOICES			; just one voice, thanks
	mov	dx, STANDARD_TEMPO			; slow tempo
	call	SoundAllocMusicStream		; destroys ax

EC<	ERROR_C SOUND_PLAY_ERROR_VOICE_ALLOCATION_FAILED		>

	;
	;  Save the returned handle in idata (dgroup)
	;	so that we can get it again at a later time
	mov	ds:[soundVoiceHandle], bx		; save handle in udata

	;
	;  Clear the voice so the stream is in a known state
	call	SoundPlayClearVoice			; ahem.  Ahem.  Ahem....
	.leave
	ret
SoundPlayInitializeVoice	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayCloseVoice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close up the stream and free it

CALLED BY:	SoundPlayCloseApplication

PASS:		ds	-> dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Frees music stream

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayCloseVoice	proc	near
	uses	ax, bx
	.enter

	;
	;  Get and clear handle from dgroup
	clr	bx
	xchg	bx, ds:[soundVoiceHandle]

EC<	tst	bx							>
EC<	ERROR_Z	SOUND_PLAY_ERROR_VOICE_ALREADY_DESTROYED		>

	;
	;  Stop the music (just in case there is anything
	;  left on the stream)...
	call	SoundStopMusicStream		; destroys ax

EC<	ERROR_C	SOUND_PLAY_ERROR_MUSIC_STOP_FAILED			>

	;
	;  Free the stream so others can use the voice
	call	SoundFreeMusicStream		; destroys ax

	.leave
	ret
SoundPlayCloseVoice	endp

InitCode		ends


CommonCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayClearVoice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the stream and clear it

CALLED BY:	SoundPlayInitVoice, SoundPlayStop

PASS:		ds	-> dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	stops stream and flushes

PSEUDO CODE/STRATEGY:
		Get handle to SoundStream

		Call SoundStopMusicStream

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/10/93    	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SoundPlayClearVoice	proc	far
	uses	ax, bx, cx, dx, si
	.enter

	;
	;  Get handle of stream from dgroup
	mov	bx, ds:[soundVoiceHandle]		; bx <- handle of stream

	;
	;  Call library to stop the stream
	call	SoundStopMusicStream		; destroys ax

EC<	ERROR_C	SOUND_PLAY_ERROR_MUSIC_STOP_FAILED			>

	;
	;  Run the cleaner down the stream
	;	so we know what state it is in.
	mov	dx, cs					; dx:si <- buffer
	mov	si, offset startUpEventList
	mov	cx, size startUpEventList		; cx <- size of buffer

	call	SoundPlayToMusicStream		; destroys ax

EC<	ERROR_C SOUND_PLAY_ERROR_SOUND_LIBRARY_REPORTS_ERROR		>

	.leave
	ret
SoundPlayClearVoice	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayPlayEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a note to the sound stream

CALLED BY:	SoundPlayPlayNextNote

PASS:		bx	-> NoteType
		si	-> SoundNoteDuration
		ds	-> segment of dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Writes Sound Buffer events to music stream

PSEUDO CODE/STRATEGY:
		Use passed parameters as double index into
		array of note buffers.  Play the appropriate
		buffer to the stream, and then return...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayPlayEvent	proc	near
	uses	ax, bx, cx, dx, si
	.enter

	mov	dx, cs					; dx:si <- buffer
	lea	si, cs:eventRest[bx][si]

	mov	cx, LENGTH_OF_EVENT			; cx <- length of buffer
	mov	bx, ds:[soundVoiceHandle]		; bx <- handle of stream
	call	SoundPlayToMusicStream		; destroys ax

EC<	ERROR_C	SOUND_PLAY_ERROR_SOUND_LIBRARY_REPORTS_ERROR		>

	.leave
	ret
SoundPlayPlayEvent	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayPlayNextNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play the next note in the song

CALLED BY:	MSG_SND_PLAY_PLAY_NEXT_NOTE

PASS:		ds	-> dgroup
		cx	-> note to play

RETURN:		nothing

DESTROYED:	bx, di
		(bx, si, di, ds, es allowed)

SIDE EFFECTS:
		Writes and event to the stream

PSEUDO CODE/STRATEGY:
		Get the

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayPlayNextNote	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_PLAY_NEXT_NOTE
	uses	ax, cx, dx
	.enter

	;
	;  Try to retrieve the note's value.  If we fail,
	;  assume we have reached the end of the song...
	push	cx				; save trashed register

	call	SoundPlayGetNoteValue		; bx <- SoundNoteType
						; si <- SoundNoteDuration
						; ax, cx, dx destroyed
						; carry set on error

	pop	cx				; restore trashed register
	jc	done

	;
	;  Play the retrieved note
	;
	call	SoundPlayPlayEvent	; nothing destroyed

	;
	;  Send ourselves this message again, bumping
	;	up cx by one so we play the next note.
	;
	mov	ax, MSG_SND_PLAY_PLAY_NEXT_NOTE	; ax <- message
	inc	cx				; play next note

	call	GeodeGetProcessHandle	; bx <- process handle

	mov	di, mask MF_FORCE_QUEUE		; di <- MessageFlags
	call	ObjMessage		; di <- MessageError

done:
	.leave
	ret
SoundPlayPlayNextNote	endm


;-----------------------------------------------------------------------------
;
;		Event List
;
;-----------------------------------------------------------------------------

startUpEventList word	SSE_CHANGE, 0, IP_LEAD_SQUARE, 0,
			SSE_GENERAL, GE_SET_PRIORITY, STANDARD_PRIORITY


eventRest	word	\
	SSE_VOICE_OFF	, 	0,			; 2 words
	SSDTT_TICKS	,	WHOLE,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words

	SSE_VOICE_OFF	, 	0,			; 2 words
	SSDTT_TICKS	,	HALF,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words

	SSE_VOICE_OFF	, 	0,			; 2 words
	SSDTT_TICKS	,	QUARTER,		; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words

	SSE_VOICE_OFF	, 	0,			; 2 words
	SSDTT_TICKS	,	EIGHTH,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT,			; 2 words
	SSE_GENERAL	, GE_NO_EVENT			; 2 words


eventCNote	word	\
	SSE_VOICE_ON	, 	0,	MIDDLE_C,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(WHOLE*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	WHOLE/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_C,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(HALF*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	HALF/8,					; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_C,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(QUARTER*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	QUARTER/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_C,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(EIGHTH*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	EIGHTH/8				; 2
ForceRef	eventCNote		; reference eventCNote so ESP
					; doesn't complain

eventDNote	word	\
	SSE_VOICE_ON	, 	0,	MIDDLE_D,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(WHOLE*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	WHOLE/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_D,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(HALF*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	HALF/8,					; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_D,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(QUARTER*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	QUARTER/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_D,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(EIGHTH*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	EIGHTH/8				; 2
ForceRef	eventDNote		; reference eventDNote so ESP
					; doesn't complain

eventENote	word	\
	SSE_VOICE_ON	, 	0,	MIDDLE_E,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(WHOLE*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	WHOLE/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_E,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(HALF*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	HALF/8,					; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_E,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(QUARTER*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	QUARTER/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_E,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(EIGHTH*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	EIGHTH/8				; 2
ForceRef	eventENote		; reference eventENote so ESP
					; doesn't complain


eventFNote	word	\
	SSE_VOICE_ON	, 	0,	MIDDLE_F,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(WHOLE*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	WHOLE/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_F,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(HALF*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	HALF/8,					; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_F,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(QUARTER*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	QUARTER/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_F,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(EIGHTH*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	EIGHTH/8				; 2
ForceRef	eventFNote		; reference eventFNote so ESP
					; doesn't complain

eventGNote	word	\
	SSE_VOICE_ON	, 	0,	MIDDLE_G,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(WHOLE*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	WHOLE/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_G,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(HALF*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	HALF/8,					; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_G,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(QUARTER*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	QUARTER/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_G,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(EIGHTH*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	EIGHTH/8				; 2
ForceRef	eventGNote		; reference eventGNote so ESP
					; doesn't complain

eventANote	word	\
	SSE_VOICE_ON	, 	0,	MIDDLE_A,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(WHOLE*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	WHOLE/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_A,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(HALF*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	HALF/8,					; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_A,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(QUARTER*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	QUARTER/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_A,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(EIGHTH*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	EIGHTH/8				; 2
ForceRef	eventANote		; reference eventANote so ESP
					; doesn't complain

eventBNote	word	\
	SSE_VOICE_ON	, 	0,	MIDDLE_B,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(WHOLE*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	WHOLE/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_B,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(HALF*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	HALF/8,					; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_B,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(QUARTER*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	QUARTER/8,				; 2

	SSE_VOICE_ON	, 	0,	MIDDLE_B,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(EIGHTH*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	EIGHTH/8				; 2
ForceRef	eventBNote		; reference eventBNote so ESP
					; doesn't complain

eventHiCNote	word	\
	SSE_VOICE_ON	, 	0,	HIGH_C,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(WHOLE*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	WHOLE/8,				; 2

	SSE_VOICE_ON	, 	0,	HIGH_C,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(HALF*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	HALF/8,					; 2

	SSE_VOICE_ON	, 	0,	HIGH_C,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(QUARTER*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	QUARTER/8,				; 2

	SSE_VOICE_ON	, 	0,	HIGH_C,	DYNAMIC_FFFF,	; 4
	SSDTT_TICKS	,	(EIGHTH*7)/8,				; 2
	SSE_VOICE_OFF	,	0,					; 2
	SSDTT_TICKS	,	EIGHTH/8				; 2
ForceRef	eventHiCNote		; reference eventHiCNote so ESP
					; doesn't complain
CommonCode		ends



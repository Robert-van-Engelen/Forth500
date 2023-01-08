# Forth500 for expanded PC-E500(S) with over 64KB

An expanded PC-E500(S) should have 128KB or more internal memory or a 64KB or
greater RAM card installed with `MEM$="B"`.  A 32KB RAM card does not suffice.

On the PC-E500(S) execute:

    > POKE &BFE03,&1A,&FD,&0B,0,&FC,0: CALL &FFFD8

This reserves &B0000-&BFC00 and resets the machine.

Warning: memory cannot be allocated when in use by other programs.  To check if
memory was allocated:

    > PEEK &BFD1B
    0

The value 0 shows that memory was allocated from &B0000 up.

## When using a cassette interface, such as CE-126P or CE-124

First allocate memory as described in the first part of this README.

Play the Forth500.wav file and load Forth500 on the PC-E500(S) with `CLOADM`:

    > CLOADM

Type `CLOADM` first then play the wav file on your desktop PC.  If I/O errors
are persistent, then try loading Forth500 in three parts:

1. play Forth500-1.wav and `CLOADM` on the PC-E500
2. play Forth500-2.wav and `CLOADM` on the PC-E500
3. play Forth500-3.wav and `CLOADM` on the PC-E500

The three parts can be loaded in any order, as long as each is loaded without
I/O errors.  After loading `CALL &B0000`.

I get an acceptable success rate to load with MacOS `afplay` via the CE-126P
and CE-124 interfaces.  Headphone output volume should be close to max or max.
Start with a volume lower than max, because max may cause distortion.  Quit all
apps on your desktop PC that may produce sound (messaging etc).  Make sure that
the audio cable does not pick up electrical interference.

[PocketTools](https://www.peil-partner.de/ifhe.de/sharp/) was used to produce
the wav file as follows:

    $ bin2wav --pc=E500 --type=bin --addr=0xB0000 -dINV --sync=9 Forth500.bin

Mostly `-dINV` works best, but `-dMAX` should be used instead if loading fails.

## When using the serial interface

First allocate memory as described in the first part of this README.

Connect a serial cable and initialize the COM: port on the PC-E500(S):

    > OPEN "9600,N,8,1,A,L,&H1A,N,N": CLOSE

Set the terminal program's serial settings to 9600 8N1 with hardware flow
control enabled (RTS/CTS), no software flow control and append ^Z (hex 1A) to
signal end of file.

Transfer UUDECODE.BAS to the PC-E500(S) via serial:

    > TEXT
    < LOAD "COM:"
    < BASIC

RUN the program:

    UUENCODE SELF-DECODER 
    DATA_FILE = 'UUDECODE.MMM'
    OK? (Y / N) = Y <return>
    success

A new file UUDECODE.MMM of 1446 bytes was created.  The BASIC program currently
in use can be deleted with NEW.  Then execute the following on the PC-E500(S)
and transfer the FORTH500.UUE file to the PC-E500(S) via the serial interface:

    > LOADM "UUDECODE.MMM" 
    > CALL &BE000"COM:
    uudecode V1.1 by E.Kako
    filename = 'E:FORTH500.'
    decoded. 

A new file FORTH500. is created (the Forth500.bin file specified with the
uucode/BINTOPCE.EXE and uucode/UUENCODE.EXE tools but without filename
extension), which can be loaded and run with:

    > LOADM "FORTH500."
    > CALL &B0000

See the HP forum thread "FORTH for the SHARP PC-E500(S)"
<https://www.hpmuseum.org/forum/thread-17440-post-153815.html#pid153815>

## Run Forth500

To run Forth500:

    > CALL &B0000

To exit Forth500, type `bye`.  Call Forth500 again to continue where you left
off.  BASIC and Forth500 programs can co-exist.

## Saving a Forth500 image

Once Forth500 is loaded, you can save the entire Forth500 image to a RAM disk
drive on the PC-E500(S), either the E: or F: drive:

    > SAVEM "F:FORTH500.BIN",&B0000,&Bxxxx

where `xxxx` is the address returned by `HERE HEX.` minus 1.  If you just
loaded Forth500 without changing it, then you can save the image with:

    > SAVEM "F:FORTH500.BIN",&B0000,&B4D8D

This makes it possible to instantly reload Forth500, e.g. after a fatal error
or crash that damaged the Forth500 dictionary:

    > LOADM "F:FORTH500.BIN",&B0000

## Removing Forth500

To remove Forth500 from memory and release its allocated RAM space:

    > POKE &BFE03,&1A,&FD,&0B,0,0,0: CALL &FFFD8

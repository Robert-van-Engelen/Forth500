# Binary Forth500.bin for unexpanded PC-E500 with 32KB

On the PC-E500(S) execute:

    > POKE &BFE03,&1A,&FD,&0B,0,&FC-&90,0: CALL &FFFD8

This reserves &B9000-&BFC00 and resets the machine.

Warning: memory cannot be allocated when in use by other programs.  To check if
memory was allocated:

    > HEX PEEK &BFD1B
    90

The value 90 shows that memory was allocated from &B9000 up.

## When using a cassette interface, such as CE-126P or CE-124

Play the Forth500.wav file and load Forth500 on the PC-E500(S) with `CLOADM`:

    > CLOADM

Type `CLOADM` first then play the wav file on your desktop PC.  If I/O errors
are persistent, then try loading Forth500 in three parts:

1. play Forth500-1.wav and `CLOADM` on the PC-E500
2. play Forth500-2.wav and `CLOADM` on the PC-E500
3. play Forth500-3.wav and `CLOADM` on the PC-E500

The three parts can be loaded in any order, as long as each is loaded without
I/O errors.  After loading `CALL &B9000`.

I get an acceptable success rate to load with MacOS `afplay` via the CE-126P
and CE-124 interfaces.  Headphone output volume should be close to max or max.
Start with a volume lower than max, because max may cause distortion.  Quit all
apps on your desktop PC that may produce sound (messaging etc).  Make sure that
the audio cable does not pick up electrical interference.

[PocketTools](https://www.peil-partner.de/ifhe.de/sharp/) was used to produce
the wav file as follows:

    $ bin2wav --pc=E500 --type=bin --addr=0xB9000 -dMAX --sync=9 Forth500.bin

## When using the serial interface

See the HP forum thread "FORTH for the SHARP PC-E500(S)"
<https://www.hpmuseum.org/forum/thread-17440-post-153815.html#pid153815>

## Run Forth500

To run Forth500:

    > CALL &B9000

To exit Forth500, type `bye`.  Call Forth500 again to continue where you left
off.  BASIC and Forth500 programs can co-exist.

## Saving a Forth500 image

Once Forth500 is loaded, you can save the entire Forth500 image to a RAM disk
drive on the PC-E500(S), either the E: or F: drive:

    > SAVEM "F:FORTH500.BIN",&B9000,&Bxxxx

where `xxxx` is the address returned by `HERE HEX.` minus 1.  If you just
loaded Forth500 without changing it, then save the image with:

    > SAVEM "F:FORTH500.BIN",&B9000,&BDD61

This makes it possible to instantly reload Forth500, e.g. after a fatal error
or crash that damaged the Forth500 dictionary:

    > LOADM "F:FORTH500.BIN",&B9000

## Removing Forth500

To remove Forth500 from memory and release its allocated RAM space:

    > POKE &BFE03,&1A,&FD,&0B,0,0,0: CALL &FFFD8

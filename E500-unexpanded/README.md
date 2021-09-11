# Binary Forth500.bin for unexpanded PC-E500 with 32KB

Use a cassette interface, such as CE-126p or CE-124.

On the PC-E500 execute:

    > POKE &BFE03,&1A,&FD,&0B,0,&FC-&90,0: CALL &FFFD8

This reserves &B9000-&BFC00 and resets the machine.

Warning: memory cannot be allocated when in use by programs.  To check if
memory was allocated:

    > HEX PEEK &BFD1B
    90

The value 90 shows that memory was allocated from &B9000 on (&BFD1C contains
the low-order address byte, which is zero).

Play the Forth500.wav file, load, then run Forth on the PC-E500:

    > CLOADM
    > CALL &B9000

For best results, type `CLOADM` first, wait 2 seconds, then play the wav file.
If I/O errors are persistent, then try loading Forth500 in three parts:

1. play Forth500-1.wav and `CLOADM` on the PC-E500
2. play Forth500-2.wav and `CLOADM` on the PC-E500
3. play Forth500-3.wav and `CLOADM` on the PC-E500

The three parts can be loaded in any order, as long as each is loaded without
I/O errors.  After loading `CALL &B9000`.

I get an acceptable success rate to load with MacOS `afplay` via the CE-126P
and CE-124 interfaces.  Headphone output volume should be close to max or max.
Quit all apps that may produce sound (messaging etc).  Make sure that the audio
cable does not pick up electrical interference.

To remove Forth from memory and release its allocated RAM space:

    > POKE &BFE03,&1A,&FD,&0B,0,0,0: CALL &FFFD8

[PocketTools](https://www.peil-partner.de/ifhe.de/sharp/) was used to produce
the wav file as follows:

    $ bin2wav --pc=E500 --type=bin --addr=0xB9000 Forth500.bin

Instead of the wav file, a RS-232 interface can be used.  This requires a
uuencoded object file to transfer and install the binary.

# Binary Forth500.bin for unexpanded PC-E500 with 32KB

Use a cassette interface, such as CE-126p or CE-124, and
[PocketTools](https://www.peil-partner.de/ifhe.de/sharp/) to load:

    $ bin2wav --pc=E500 --type=bin --addr=0xB9000 Forth500.bin

On the PC-E500 execute:

    > POKE &BFE03,&1A,&FD,&0B,0,&FC-&90,0: CALL &FFFD8

This reserves &B9000-&BFC00 and resets the machine.

Warning: memory cannot be allocated when in use by programs.  To check if
memory was allocated:

    > HEX PEEK &BFD1B
    90

The value 90 shows that memory was allocated from &B9000 on (&BFD1C contains
the low-order address byte, which is zero).

Play the wav file, load and run Forth:

    > CLOADM
    > CALL &B9000

To remove Forth from memory and release its allocated RAM space:

    > POKE &BFE03,&1A,&FD,&0B,0,0,0: CALL &FFFD8

Instead of the wav file, a RS-232 interface can be used.  This requires a
uuencoded bin file to transfer and install the binary.

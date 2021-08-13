# Binary Forth500.bin for expanded PC-E500 with 256KB

Use a cassette interface, such as CE-126p or CE-124, and
[PocketTools](https://www.peil-partner.de/ifhe.de/sharp/) to load:

    $ bin2wav --pc=E500 --type=bin --addr=0xB0000 Forth500.bin

On the PC-E500 execute:

    > POKE &BFE03,&1A,&FD,&0B,0,&FC,0: CALL &FFFD8

This reserves &B0000-&BFC00 and resets the machine.

Play the wav file, load and run Forth:

    > CLOADM
    > CALL &B0000

To remove Forth from memory and release its allocated RAM space:

    > POKE &BFE03,&1A,&FD,&0B,0,0,0: CALL &FFFD8

Instead of the wav file, a RS-232 interface can be used.  This
requires a uuencoded bin file to transfer and install the binary.

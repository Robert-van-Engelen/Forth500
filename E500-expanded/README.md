# Binary Forth500.bin for expanded PC-E500 with 256KB

With a cassette interface such as CE-126p use PocketTools to load:
    $ bin2wav --pc=E500 --type=bin --addr=0xB0000 Forth500.bin

On the PC-E500 execute:
    > POKE &BFE03,&1A,&FD,&0B,0,&FC,0: CALL &FFFD8
This reserves &B0000-&BFC00 and resets the machine.

Play the wav file, load and run Forth:
    > CLOADM
    > CALL &B0000

To remove Forth from memory and release its allocated RAM space:
    > POKE &BFE03,&1A,&FD,&0B,0,0,0: CALL &FFFD8



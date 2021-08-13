# Binary Forth500.bin for unexpanded PC-E500 with 32KB

With a cassette interface such as CE-126p use PocketTools to load:
    $ bin2wav --pc=E500 --type=bin --addr=0xB9000 Forth500.bin

On the PC-E500 execute:
    > POKE &BFE03,&1A,&FD,&0B,0,&FC-&90,0: CALL &FFFD8
This reserves &B9000-&BFC00 and resets the machine.

Play the wav file, load and run Forth:
    > CLOADM
    > CALL &B9000

To remove Forth from memory and release its allocated RAM space:
    > POKE &BFE03,&1A,&FD,&0B,0,0,0: CALL &FFFD8



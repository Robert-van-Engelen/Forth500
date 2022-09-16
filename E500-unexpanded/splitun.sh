# first must compile with XASM then:
# tail -c +7 Forth500.OBJ > Forth500.bin

grep -q '\t\torg\t\$b9000' Forth500.s || echo '*** ERROR ***: FIRST MUST CHANGE: Forth500.s org $b9000'

./XASM Forth500.s -O -L -S -TB
tail -c +7 Forth500.OBJ > Forth500.bin

head -c 6144 Forth500.bin > Forth500-1.bin
tail -c +6145 Forth500.bin | head -c 6144 > Forth500-2.bin
tail -c +12289 Forth500.bin > Forth500-3.bin

bin2wav --pc=E500 --type=bin --addr=0xB9000 -dINV --sync=9 Forth500.bin
bin2wav --pc=E500 --type=bin --addr=0xB9000 -dINV --sync=9 Forth500-1.bin
bin2wav --pc=E500 --type=bin --addr=0xBA800 -dINV --sync=9 Forth500-2.bin
bin2wav --pc=E500 --type=bin --addr=0xBC000 -dINV --sync=9 Forth500-3.bin

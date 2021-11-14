\ DRAGON.FTH dragon curve fractal

.( Loading DRAGON...)

ANEW _DRAGON_

1 CONSTANT d	\ pixel drawing step size, e.g. 1 or 2
d NEGATE CONSTANT -d

0 VALUE a	\ angle 0 (0 deg), 1 (90 deg), 2 (180 deg), 3 (270 deg)
0 VALUE x	\ x coord
0 VALUE y	\ y coord

: table		CREATE DOES> a CELLS + @ ;

table sina 0 , d , 0 , -d ,	\ sine table for 4 angles
table cosa d , 0 , -d , 0 ,	\ cosine table for 4 angles

: curve		( dir level -- )
	DUP 2 < IF
		DROP
		x cosa + y sina -	\ dir (u=x+cos(a)) (v=y-sin(a))
		x y 2OVER -1 GLINE	\ line(x,y,u,v) pattern -1
		ROT			\ u v dir
		a SWAP - 3 AND TO a	\ a = (a-dir) mod 4
		OVER cosa + TO x	\ x = u+cos(a)
		DUP sina - TO y		\ y = v-sin(a)
		x y -1 GLINE		\ line(u,v,x,y) pattern -1
	ELSE
		1-			\ dir (level-1)
		1 OVER RECURSE		\ 1 (level-1) curve
		a ROT - 3 AND TO a	\ a = (a-dir) mod 4
		-1 SWAP RECURSE		\ -1 (level-1) curve
	THEN
;

: dragon	( levels -- )
	0 GMODE! PAGE
	DUP 2/ 3 AND TO a		\ a = levels/2 mod 4
	60 TO x				\ x = 60
	22 OVER 1 AND RSHIFT TO y	\ y = 24 >> (n mod 2)
	1 SWAP curve			\ 1 levels curve
;

10 dragon

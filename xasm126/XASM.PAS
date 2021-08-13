program xasm(input,output);
{$I-}
{$b-}
{$c-}
label
 aaa;
const
 maxreal=1048576.0;
 header:array [1..16] of byte=($ff,$00,$06,$01,$10,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$00,$0f);
type
 txttyp=string[255];
 hextyp=string[7];
 textfile=text; { was text[$4000]; }
 label_pnt=^label_typ;
 label_typ=record
            name:string[16];
            value:real;
            child:label_pnt;
            next:label_pnt
           end;
 file_pnt=^file_typ;
 file_typ=record
           name:txttyp;
           lines:integer;
           txt:textfile;
           pre:file_pnt;
           arg:array [1..10] of real;
           arg_cnt:byte;
	   l_stack_p:integer;
	  end;

var
 listing_on,object_on,symbol_on,count_on,warning_on,err_on:boolean;
 listing_txt,object_txt:textfile;
 new_line,undef_flag2:boolean;
 obj_typ:char;
 csum:byte;
 fatal_err:boolean;
 object_cnt:integer;
 asmtext,inbuf,x_label,source_name,object_name,listing_name:txttyp;
 undef_flag,pre_on,org_set:boolean;
 pass_sw:byte;
 endflag,label_exist,s_end:boolean;
 l_stack:array [1..16] of label_pnt;
 l_stack_p:integer;
 current_file,new_file:file_pnt;
 o_stack:array [0..16] of char;
 v_stack:array [1..16] of real;
 o_stack_p:integer;
 v_stack_p:integer;
 i,pp:integer;
 oprtxt:txttyp;
 err:integer;
 typ,offset:byte;
 slc,lc,x,y:real;
 next_pnt,equ_pnt,undefined_pnt:label_pnt;
 defined,undefined:boolean;
 lines,listing_count:integer;

{$i xasmproc}

begin
 object_on:=false;
 listing_on:=false;
 symbol_on:=false;
 count_on:=false;
 fatal_err:=false;
 warning_on:=false;
 err_on:=false;
 writeln('<<< Absolute-type CROSS assembler V1.26 for CPU-SC62015 / (c)1990 N.Kon >>>',^M^J);
 if paramcount<1 then
  begin
   writeln(' USAGE:XASM sourcefile[.ext] [options]');
   writeln;
   writeln('   - OPTIONS -');
   writeln;
   writeln(' -L[filename] : With listing file');
   writeln(' -E[filename] : With error report file (use with -L)');
   writeln(' -O[filename] : With object file');
   writeln(' -S           : With symbol list (use with -L)');
   writeln(' -T[type]     : Object type (type=Z    :ZSH format');
   writeln('                                  B    :Binary format');
   writeln('                                  H    :Hexadecimal format');
   writeln('                                  F    :FTX format');
   writeln('                                  other:Binary format with header)');
   writeln(' -C           : Count line number');
   writeln(' -W           : With warning');
   writeln;
   writeln('    ex.  XASM sourcefile -L -E -O -S -TZ -C -W ...full options')
  end
 else begin
 obj_typ:=#0;
 pp:=isorg(paramstr(1));
 if pp=0 then
   begin
    source_name:=paramstr(1)+'.ASM';
    object_name:=paramstr(1)+'.OBJ';
    listing_name:=paramstr(1)+'.LST'
   end
  else
   begin
    source_name:=paramstr(1);
    object_name:=copy(paramstr(1),1,pp)+'OBJ';
    listing_name:=copy(paramstr(1),1,pp)+'LST'
   end;
 for i:=2 to paramcount do
   begin
    inbuf:=paramstr(i);
    if inbuf[1]='-' then
      begin
       case upcase(inbuf[2]) of
         'L':
           begin
            listing_on:=true;
            if length(inbuf)>2 then
              listing_name:=copy(inbuf,3,length(inbuf));
            assign(listing_txt,listing_name);
            ioerr;
           end;
         'O':
           begin
            object_on:=true;
            if length(inbuf)>2 then
              object_name:=copy(inbuf,3,length(inbuf));
            assign(object_txt,object_name);
            ioerr;
            rewrite(object_txt);
            ioerr;
           end;
         'S':
           symbol_on:=true;
         'C':
           count_on:=true;
         'T':
           obj_typ:=upcase(inbuf[3]);
         'W':
           warning_on:=true;
         'E':
           err_on:=true;
        end
      end
   end;
 pass_sw:=1;
 l_stack[1]:=nil;
 writeln(' [ PASS1 ]');
 repeat

 org_set:=false;
 lc:=0;
 slc:=0;
 new(current_file);
 current_file^.name:=source_name;
 current_file^.pre:=nil;
 current_file^.arg_cnt:=1;
 current_file^.l_stack_p:=1;
 assign(current_file^.txt,current_file^.name);
 ioerr;
 reset(current_file^.txt);
 ioerr;
 if listing_on=true then
   begin
    rewrite(listing_txt);
    ioerr
   end;

 lines:=0;
 current_file^.lines:=0;
 l_stack_p:=1;
 endflag:=false;
 defined:=false;
 undefined:=false;
 pre_on:=false;
 repeat
 err:=0;
  repeat
   if eof(current_file^.txt)=true then
     begin
      err:=18;
      endflag:=true
     end
    else
     begin
      readln(current_file^.txt,asmtext);
      ioerr;
     end;
  until(err=18)or(asmtext<>'');
 current_file^.lines:=current_file^.lines+1;
 lines:=lines+1;
 if count_on=true then write('    ',lines,#13);
 listing_name:=asmtext;
 new_line:=true;
 asmtext:=asmtext+#$1a;
 label_exist:=false;
 pp:=1;
 if (err=0)and(asmtext[1]<>';') then begin
 if (asmtext[1]<>' ')and(asmtext[1]<>#9) then
   begin
    x_label:='';
    while islabel2(upcase(asmtext[pp]))=true do
     begin
      x_label:=x_label+upcase(asmtext[pp]);
      pp:=pp+1
     end;
    if (asmtext[pp]<>':')or(length(x_label)>16)or(x_label='') then
      err:=10
     else
      begin
       label_exist:=true;
       delete(asmtext,1,length(x_label)+1);
       if pass_sw=1 then
         begin
          err:=find_label(x_label,x,next_pnt);
          if err=11 then
            begin
             make_label(x_label,lc,next_pnt);
             err:=0
            end
           else
            if err=0 then err:=13
         end
        else
         begin
          i:=find_label(x_label,x,equ_pnt);
         end
      end
   end;
(* generate opecode *)
 if err=0 then begin
 slim(asmtext);
 if (asmtext[1]<>#$1a)and(asmtext[1]<>';') then begin
 pp:=1;
 inbuf:='';
 while delimiter(asmtext[pp])=false do
  begin
   inbuf:=inbuf+upcase(asmtext[pp]);
   pp:=pp+1
  end;
 i:=255;
 if inbuf='MV'   then begin i:=0;  goto aaa end;
 if inbuf='MVW'  then begin i:=1;  goto aaa end;
 if inbuf='MVP'  then begin i:=2;  goto aaa end;
 if inbuf='MVL'  then begin i:=3;  goto aaa end;
 if inbuf='MVLD' then begin i:=7;  goto aaa end;
 if inbuf='EX'   then begin i:=8;  goto aaa end;
 if inbuf='EXW'  then begin i:=9;  goto aaa end;
 if inbuf='EXP'  then begin i:=10; goto aaa end;
 if inbuf='EXL'  then begin i:=11; goto aaa end;
 if inbuf='SWAP' then
   begin
    i:=41;
    offset:=$ee;
    goto aaa
   end;
 if inbuf='ADD' then
   begin
    i:=16;
    offset:=$40;
    goto aaa
   end;
 if inbuf='SUB' then
   begin
    i:=16;
    offset:=$48;
    goto aaa
   end;
 if inbuf='ADC' then
   begin
    i:=16;
    offset:=$50;
    goto aaa
   end;
 if inbuf='SBC' then
   begin
    i:=16;
    offset:=$58;
    goto aaa
   end;
 if inbuf='AND' then
   begin
    i:=17;
    offset:=$70;
    goto aaa
   end;
 if inbuf='OR'  then
   begin
    i:=17;
    offset:=$78;
    goto aaa
   end;
 if inbuf='XOR' then
   begin
    i:=17;
    offset:=$68;
    goto aaa
   end;
 if inbuf='CMP' then
   begin
    i:=20;
    offset:=$60;
    goto aaa
   end;
 if inbuf='TEST' then
   begin
    i:=20;
    offset:=$64;
    goto aaa
   end;
 if inbuf='ADCL' then
   begin
    i:=22;
    offset:=$50;
    goto aaa
   end;
 if inbuf='SBCL' then
   begin
    i:=22;
    offset:=$58;
    goto aaa
   end;
 if inbuf='DADL' then
   begin
    i:=22;
    offset:=$c0;
    goto aaa
   end;
 if inbuf='DSBL' then
   begin
    i:=22;
    offset:=$d0;
    goto aaa
   end;
 if inbuf='INC' then
   begin
    i:=42;
    offset:=$6c;
    goto aaa
   end;
 if inbuf='DEC' then
   begin
    i:=42;
    offset:=$7c;
    goto aaa
   end;
 if inbuf='ROR' then
   begin
    i:=43;
    offset:=$E4;
    goto aaa
   end;
 if inbuf='ROL' then
   begin
    i:=43;
    offset:=$E6;
    goto aaa
   end;
 if inbuf='SHR' then
   begin
    i:=43;
    offset:=$F4;
    goto aaa
   end;
 if inbuf='SHL' then
   begin
    i:=43;
    offset:=$F6;
    goto aaa
   end;
 if inbuf='DSRL' then
   begin
    i:=44;
    offset:=$fb;
    goto aaa
   end;
 if inbuf='DSLL' then
   begin
    i:=44;
    offset:=$eb;
    goto aaa
   end;
 if inbuf='PMDF' then begin i:=30;
   goto aaa end;
 if inbuf='CMPW' then begin i:=31;
   goto aaa end;
 if inbuf='CMPP' then begin i:=32;
   goto aaa end;
 if inbuf='JP'   then begin i:=45;
   goto aaa end;
 if inbuf='JPF'  then begin i:=46;
   goto aaa end;
 if inbuf='JPZ'  then begin i:=47;
   goto aaa end;
 if inbuf='JPNZ' then begin i:=48;
   goto aaa end;
 if inbuf='JPC'  then begin i:=49;
   goto aaa end;
 if inbuf='JPNC' then begin i:=50;
   goto aaa end;
 if inbuf='CALL' then begin i:=51;
   goto aaa end;
 if inbuf='CALLF' then begin i:=52;
   goto aaa end;
 if inbuf='PUSHS' then begin i:=53;
   goto aaa end;
 if inbuf='PUSHU' then begin i:=54;
   goto aaa end;
 if inbuf='POPS' then begin i:=55;
   goto aaa end;
 if inbuf='POPU' then begin i:=56;
   goto aaa end;
 if inbuf='JR' then begin i:=59;
   goto aaa end;
 if inbuf='JRZ'  then begin i:=61;
   goto aaa end;
 if inbuf='JRNZ'  then begin i:=63;
   goto aaa end;
 if inbuf='JRC'  then begin i:=65;
   goto aaa end;
 if inbuf='JRNC' then begin i:=67;
   goto aaa end;
 if inbuf='RET'  then begin i:=no_operand(6);
   goto aaa end;
 if inbuf='RETF' then begin i:=no_operand(7);
   goto aaa end;
 if inbuf='RETI' then begin i:=no_operand(1);
   goto aaa end;
 if inbuf='WAIT' then begin i:=no_operand($ef);
   goto aaa end;
 if inbuf='NOP'  then begin i:=no_operand(0);
   goto aaa end;
 if inbuf='TCL'  then begin i:=no_operand($ce);
   goto aaa end;
 if inbuf='HALT' then begin i:=no_operand($de);
   goto aaa end;
 if inbuf='OFF'  then begin i:=no_operand($df);
   goto aaa end;
 if inbuf='IR'   then begin i:=no_operand($fe);
   goto aaa end;
 if inbuf='RESET' then begin i:=no_operand($ff);
   goto aaa end;
 if inbuf='SC'   then begin i:=no_operand($97);
   goto aaa end;
 if inbuf='RC'   then begin i:=no_operand($9f);
   goto aaa end;

 if inbuf='END' then
   begin
    i:=69;
    if current_file^.pre<>nil then
      begin
       new_file:=current_file^.pre;
       dispose(current_file);
       current_file:=new_file
      end
     else
      begin
       endflag:=true;
       if l_stack_p<>1 then err:=14
      end;
    if (err=0)and(current_file^.l_stack_p<>l_stack_p) then err:=33;
    goto aaa
   end;

 if inbuf='ORG' then
   begin
    get_operand(pp,oprtxt);
    if asmtext[pp]<>',' then
      begin
       err:=eval2(oprtxt,x);
       if err=0 then
         if undef_flag=false then
           if org_set=false then
             begin
              lc:=x;
              slc:=x;
              org_set:=true
             end
            else
	     if x<lc then
	       err:=26
	     else
	      begin
	       lc:=x;
	       err:=28
	      end
	  else
           err:=26
      end
     else
      err:=8;
    i:=60;
    goto aaa
   end;

 if inbuf='EQU' then
   begin
    i:=60;
    get_operand(pp,oprtxt);
    if asmtext[pp]<>',' then
      begin
       err:=eval2(oprtxt,x);
       if err=0 then
         if label_exist=true then
           if (undef_flag=false)and(undef_flag2=false) then
             if pass_sw=1 then
               equ_pnt^.value:=x
              else
               begin
                if equ_pnt^.value=-1 then
                  begin
                   defined:=true;
                   equ_pnt^.value:=x
                  end
               end
            else
             begin
              equ_pnt^.value:=-1;
              undefined:=true;
              undefined_pnt:=equ_pnt
             end
          else
           err:=15;
      end
     else
      err:=8;
    goto aaa
   end;

 if inbuf='LOCAL' then
   begin
   i:=69;
   if label_exist=true then
   begin
    l_stack_p:=l_stack_p+1;
    if l_stack_p<=16 then
      begin
       l_stack[l_stack_p]:=equ_pnt
      end
     else
      err:=16;
   end
   else
    err:=20;
    goto aaa
   end;

 if inbuf='ENDL' then
   begin
    i:=69;
    l_stack_p:=l_stack_p-1;
    if l_stack_p<=0 then
      err:=17;
    goto aaa;
   end;
 if (inbuf='DB')or(inbuf='DM') then
   begin
    i:=68;
    offset:=0;
    goto aaa
   end;
 if inbuf='PRE' then
   begin
    i:=68;
    offset:=1;
    goto aaa
   end;
 if inbuf='DW' then
   begin
    i:=68;
    offset:=2;
    goto aaa
   end;
 if inbuf='DP' then
   begin
    i:=68;
    offset:=4;
    goto aaa;
   end;
 if inbuf='DS' then
   begin
    y:=0;
    get_operand(pp,inbuf);
    err:=eval2(inbuf,x);
    if (err=0)and(undef_flag=false) then
      begin
       if asmtext[pp]=',' then
         begin
          pp:=pp+1;
          get_operand(pp,inbuf);
          if asmtext[pp]<>',' then
            err:=eval2(inbuf,y)
           else
            err:=8
         end;
       if err=0 then
	 if x<>0 then
	   begin
	    while x>0 do
	     begin
	      set_opecode(xlow(y));
	      x:=x-1
	     end
	   end
	  else
	   err:=32;
      end
     else
      if err=0 then err:=26;
    i:=60;
    goto aaa
   end;
 if inbuf='PRE_ON' then
   begin
    i:=69;
    pre_on:=true;
    goto aaa
   end;
 if inbuf='PRE_OFF' then
   begin
    i:=69;
    pre_on:=false;
    goto aaa;
   end;
 if inbuf='INCLUDE' then
   begin
    get_operand(pp,inbuf);
       new(new_file);
       slim(inbuf);
       assign(new_file^.txt,inbuf);
       ioerr;
       reset(new_file^.txt);
       ioerr;
       new_file^.pre:=current_file;
       new_file^.name:=inbuf;
       new_file^.lines:=0;
       new_file^.arg_cnt:=1;
       new_file^.l_stack_p:=l_stack_p;
       current_file:=new_file;
    while (asmtext[pp]=',')and(err=0) do
      begin
       pp:=pp+1;
       get_operand(pp,inbuf);
       err:=eval2(inbuf,y);
       if err=0 then
         begin
          i:=current_file^.arg_cnt;
          if i<=10 then
            current_file^.arg[i]:=y
           else
            err:=30;
          current_file^.arg_cnt:=i+1;
         end
      end;
    if (err<>0)and(current_file^.pre<>nil) then
      begin
       new_file:=current_file^.pre;
       dispose(current_file);
       current_file:=new_file
      end;
    i:=60
   end;

aaa:

 case i of
   0..7:
    err:=mv_operand(i,pp);
   8:
    err:=two_operand(6,$c0,pp);
   9..11:
    err:=two_operand(5,$c0+i-8,pp);
   16:
    err:=two_operand(1,offset,pp);
   17:
    err:=two_operand(2,offset,pp);
   20:
    err:=two_operand(3,offset,pp);
   22:
    err:=two_operand(4,offset,pp);
   30..32:
    err:=two_operand(i-23,0,pp);
   41..56:
    err:=one_operand(i-40,offset,pp);
   60:;
   59:
    err:=one_operand(18,0,pp);
   61..67:
    err:=one_operand(17,i-61,pp);
   68:
    repeat
     get_operand(pp,inbuf);
     slim(inbuf);
     i:=1;
     if inbuf[1]='''' then
       begin
        inbuf:=inbuf+#$1a;
        i:=2;
        s_end:=false;
        repeat
         case inbuf[i] of
           '''':
             if inbuf[i+1]='''' then
               begin
                set_opecode(ord(''''));
                i:=i+2
               end
              else
               begin
                s_end:=true;
                i:=i+1
               end;
           #$1a:
             begin
              err:=19;
              s_end:=true
             end
          else
           begin
            set_opecode(ord(inbuf[i]));
            i:=i+1;
           end
          end;
        until s_end=true;
        if i=3 then set_opecode(0);
        if inbuf[i]<>#$1a then err:=8
       end
      else
       begin
        err:=eval2(inbuf,x);
        if err=0 then
	  set_reg_opecode(offset,xlow(x),xmid(x),xhigh(x));
	if offset=1 then
	  if not(((x>=$21)and(x<=$27))or((x>=$30)and(x<=$37))) then
	    err:=1
	   else
	    if pre_on=true then
	      err:=29;
       end;
     pp:=pp+1;
    until (asmtext[pp-1]<>',')or(err<>0);
   69:
    begin
     get_operand(pp,inbuf);
     slim(inbuf);
     if (asmtext[pp]=',')or(inbuf<>'') then err:=8
    end;
  else
   err:=7
   end;

 end;
 end;
 end;
 if (pass_sw=3)and(listing_on=true)and(err_on=false) then
   begin
    if new_line=true then write_adr;
    if listing_count<6 then
      begin
       while listing_count<6 do
         begin
          write(listing_txt,'   ');
          ioerr;
          listing_count:=listing_count+1
         end;
       writeln(listing_txt,#9,listing_name);
       ioerr;
      end
   end;
 err_handle;

 until endflag=true;
 writeln('    ',lines,' line(s)');
 if fatal_err=false then
   begin
    case pass_sw of
      1:
       begin
        if undefined=false then
          begin
           writeln(' [ PASS2 ]');
           pass_sw:=3
          end
         else
          begin
           writeln(' [ EQU define ]');
           pass_sw:=2
          end
       end;
      2:
       begin
        if undefined=true then
          begin
           if defined=false then
             begin
              err:=27;
              err_handle
             end
          end
         else
          begin
           pass_sw:=3;
           writeln(' [ PASS2 ]');
          end;
       end;
      3:
       pass_sw:=0;
     end;
   end;
  if (pass_sw=3)and(object_on=true) then
    begin
     lc:=lc-slc+16;
     header[6]:=xlow(lc-16);
     header[7]:=xmid(lc-16);
     header[8]:=xhigh(lc-16);
     header[9]:=xlow(slc);
     header[10]:=xmid(slc);
     header[11]:=xhigh(slc);
     case obj_typ of
       'Z':
         begin
          writeln(object_txt,'----- ZSH FOR E500 [A.OUT]');
          ioerr;
          writeln(object_txt,'---( ',trunc((lc-1)/32)+1,' lines )---');
          ioerr;
          csum:=0;
          for i:=1 to 16 do
           begin
            csum:=csum+header[i];
            hex_write(object_txt,header[i]);
            ioerr;
           end;
          object_cnt:=16
         end;
       'H','B':
         begin
          for i:=6 to 11 do
            begin
             if obj_typ='H' then
               hex_write(object_txt,header[i])
              else
               write(object_txt,chr(header[i]));
             ioerr
            end;
          object_cnt:=6
         end
      else
       begin
	if obj_typ='F' then
	 begin
	  write(object_txt,chr(1),chr(xlow(lc)),chr(xmid(lc)),chr(xhigh(lc)),chr(0));
	  ioerr
	 end;
        for i:=1 to 16 do
         begin
          write(object_txt,chr(header[i]));
          ioerr;
         end
       end
      end
    end
 until (fatal_err=true)or(pass_sw=0);
 if fatal_err=false then
    begin
     inbuf:=^M^J+'  No fatal error.  Code: '+hex_string(slc)+' - '+hex_string(lc-1)+' [ ';
     writeln(inbuf,lc-slc:8:0,' byte(s)]');
     if object_on=true then
       begin
        case obj_typ of
          'Z','H':
            begin
             if object_cnt<>0 then
               begin
                for i:=1 to 32-object_cnt do
                 begin
                  hex_write(object_txt,0);
                  ioerr
                 end;
                if obj_typ='Z' then hex_write(object_txt,csum);
                ioerr;
                writeln(object_txt);
                ioerr;
               end;
             if obj_typ='Z' then
               begin
                writeln(object_txt,'( end of line )');
                ioerr
               end
            end;
         end
       end;
    if (symbol_on=true)and(listing_on=true) then
      begin
       writeln(listing_txt,^M^J,' - Symbols -',^M^J);
       ioerr;
       l_stack_p:=1;
       next_pnt:=l_stack[1];
       while (next_pnt<>nil)or(l_stack_p<>1) do
         begin
          if next_pnt=nil then
            begin
             l_stack_p:=l_stack_p-1;
             next_pnt:=l_stack[l_stack_p]^.next
            end
           else
            begin
             hex_write(listing_txt,xhigh(next_pnt^.value));
             ioerr;
             hex_write(listing_txt,xmid(next_pnt^.value));
             ioerr;
             hex_write(listing_txt,xlow(next_pnt^.value));
             ioerr;
             asmtext:=' : ';
             for i:=1 to l_stack_p-1 do
              asmtext:=asmtext+l_stack[i]^.name+' ! ';
             writeln(listing_txt,asmtext,next_pnt^.name);
             ioerr;
             if next_pnt^.child=nil then
               next_pnt:=next_pnt^.next
              else
               begin
                l_stack[l_stack_p]:=next_pnt;
                l_stack_p:=l_stack_p+1;
                next_pnt:=next_pnt^.child;
               end
            end
         end
      end;
    if listing_on=true then
      begin
      writeln(listing_txt,inbuf,lc-slc:8:0,' byte(s)]');
      ioerr;
      end;
   end
  else
   begin
    writeln(^M^J,' Fatal error occured.');
    writeln(' Assemble aborted.')
   end;
 if object_on=true then
   begin
    close(object_txt);
    ioerr
   end;
 if listing_on=true then
   begin
    close(listing_txt);
    ioerr
   end
 end;
 if fatal_err=true then
   halt(1)
  else
   halt(0)
end.

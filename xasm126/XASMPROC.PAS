 procedure ioerr;
 var ioerr:integer;
 begin
  ioerr:=IOresult;
  if ioerr<>0 then
    begin
     write(^M^J,' %% I/O Error (',ioerr,') :');
     case ioerr of
       1:  writeln('Source file not found');
       2:  writeln('Source file not open');
       3:  writeln('Output file not open');
       $20:writeln('Operation not allowed on a logical device');
       $22:writeln('Assign to STD files not allowed');
       $99:writeln('Unexpected EOF');
       $f0:writeln('Disk write error');
       $f1:writeln('Directory is full');
       $f2:writeln('File size overflow');
       $f3:writeln('Too many open files');
       $ff:writeln('File disappeared');
      else
       writeln('Some error happend');
      end;
       writeln(^M^J,' Assemble aborted.');
       halt(1)
    end
 end;
 function xlow(x:real):byte;
 begin
  xlow:=trunc(x-int(x/256)*256)
 end;

 function xmid(x:real):byte;
 begin
  x:=int(x/256);
  xmid:=xlow(x)
 end;

 function xhigh(x:real):byte;
 begin
  x:=int(x/65536.0);
  xhigh:=xlow(x)
 end;

 function isorg(tmp:txttyp):byte;
 var i,j,k:integer;
 begin
  j:=1;
  for i:=1 to length(tmp) do
   if tmp[i]='\' then j:=i;
  k:=0;
  for i:=j to length(tmp) do
   if tmp[i]='.' then k:=i;
  isorg:=k
 end;

 function find_label(label_name:txttyp;var value:real;var start_pnt:label_pnt):byte;
 var
  tmp_stack:integer;
  x:integer;
  found:boolean;
  err:byte;
  name:string[16];
  last:label_pnt;
 begin
  err:=0;
  tmp_stack:=l_stack_p;
  if tmp_stack=1 then
    start_pnt:=l_stack[1]
   else
    start_pnt:=l_stack[tmp_stack]^.child;
  last:=nil;
  case label_name[1] of
    '!':
      begin
       delete(label_name,1,1);
       start_pnt:=l_stack[1]
      end;
    '.':
      begin
       delete(label_name,1,1);
       while (label_name[1]='.')and(err=0) do
        begin
         delete(label_name,1,1);
         tmp_stack:=tmp_stack-1;
         if tmp_stack>0 then
           begin
            if tmp_stack=1 then
              start_pnt:=l_stack[1]
             else
              start_pnt:=l_stack[tmp_stack]^.child
           end
          else
           err:=10;
        end;
       if label_name[1]='!' then
         delete(label_name,1,1)
        else
         err:=10
      end;
   end;
  repeat
   x:=pos('!',label_name);
   if x<>0 then
     begin
      name:=copy(label_name,1,x-1);
      delete(label_name,1,x)
     end
    else
     begin
      name:=label_name;
      label_name:=''
     end;
   found:=false;
   while (found=false)and(start_pnt<>nil) do
    if start_pnt^.name=name then
      found:=true
     else
      begin
       last:=start_pnt;
       start_pnt:=start_pnt^.next
      end;
   if start_pnt<>nil then
     begin
      if label_name<>'' then
        start_pnt:=start_pnt^.child
     end
    else
     begin
      err:=11;
      start_pnt:=last
     end;
  until (label_name='')or(err<>0);
  if err=0 then
    value:=start_pnt^.value;
  find_label:=err
 end;

 procedure make_label(label_name:txttyp;value:real;start_pnt:label_pnt);
 var
  new_label:label_pnt;
 begin
  new(new_label);
  equ_pnt:=new_label;
  new_label^.name:=label_name;
  new_label^.value:=value;
  new_label^.child:=nil;
  new_label^.next:=nil;
  if start_pnt=nil then
    begin
     if l_stack_p=1 then
       l_stack[l_stack_p]:=new_label
      else
       l_stack[l_stack_p]^.child:=new_label
    end
   else
    start_pnt^.next:=new_label
 end;

 function regular(x:real):real;
 begin
  if x<0 then x:=maxreal-abs(x)+int((abs(x)-1)/maxreal)*maxreal;
  x:=x-int(x/maxreal)*maxreal;
  regular:=x
 end;

 function delimiter(c:char):boolean;
 begin
  case c of
    ' ',';',#9,#$1a:delimiter:=true
   else
    delimiter:=false
   end;
 end;

 function xpos(tmp:txttyp;var id,pp:byte):byte;
 begin
  tmp:=tmp+#$1a;
  pp:=1;
  while (tmp[pp]<>'+')and(tmp[pp]<>'-')and(tmp[pp]<>#$1a) do
   pp:=pp+1;
  if tmp[pp]<>#$1a then
    if tmp[pp]='+' then
      id:=2
     else
      id:=3
   else
    pp:=0;
  xpos:=pp;
 end;

 procedure hex_write(var object_txt:textfile;x:byte);
 var y:byte;
 begin
   y:=x div 16;
   if y<10 then write(object_txt,chr($30+y)) else write(object_txt,chr($37+y));
   ioerr;
   y:=x mod 16;
   if y<10 then write(object_txt,chr($30+y)) else write(object_txt,chr($37+y));
   ioerr;
 end;

 function hex_string(m:real):hextyp;
 var
  x,y,z:byte;
  st:hextyp;
 begin
  st:='';
  for z:=1 to 3 do
   begin
   x:=xlow(m);
   y:=x mod 16;
   if y<10 then st:=chr($30+y)+st else st:=chr($37+y)+st;
   y:=x div 16;
   if y<10 then st:=chr($30+y)+st else st:=chr($37+y)+st;
   m:=m/256
   end;
  hex_string:=st+'h'
 end;

 procedure write_adr;
      begin
       str(lines,object_name);
       hex_write(listing_txt,xhigh(lc));
       ioerr;
       hex_write(listing_txt,xmid(lc));
       ioerr;
       hex_write(listing_txt,xlow(lc));
       ioerr;
       write(listing_txt,' ');
       ioerr;
       new_line:=false;
       listing_count:=0
      end;

 procedure set_opecode(x:byte);
 var y:byte;
 begin
  if (pass_sw=3)and(listing_on=true)and(err_on=false) then
   begin
    if (new_line=true)or(listing_count=6) then write_adr;
    hex_write(listing_txt,x);
    ioerr;
    write(listing_txt,' ');
    ioerr;
    listing_count:=listing_count+1;
    if listing_count=6 then
      begin
       writeln(listing_txt,#9,listing_name);
       ioerr;
       listing_name:='';
      end
   end;
  if (pass_sw=3)and(object_on=true) then
    begin
     case obj_typ of
       'Z','H':
         begin
          csum:=csum+x;
          hex_write(object_txt,x);
          ioerr;
          object_cnt:=object_cnt+1;
          if object_cnt=32 then
            begin
             if obj_typ='Z' then hex_write(object_txt,csum);
             ioerr;
             writeln(object_txt);
             ioerr;
             csum:=0;
             object_cnt:=0
            end
         end;
      else
       begin
        write(object_txt,chr(x));
        ioerr
       end
      end
   end;
  lc:=lc+1;
 end;

 procedure set_reg_opecode(a,b,c,d:byte);
 begin
  set_opecode(b);
  if a>1 then set_opecode(c);
  if a>3 then set_opecode(d)
 end;

 function no_operand(offset:byte):byte;
 begin
  set_opecode(offset);
  no_operand:=69
 end;

 function prebyte(a,b:byte):byte;
 var c,d:byte;
 begin
  c:=255;
  d:=0;
  case b of
    5:c:=$32;
    0:c:=$30;
    2:c:=$33;
    4:c:=$31
   else
    d:=1
   end;
  case a of
    5:;
    0:c:=c-$10;
    1:c:=c+4;
    3:c:=c-$c
   else
    d:=1
   end;
  if (d=0)and(c<>$20)and(pre_on=true) then set_opecode(c);
  prebyte:=d
 end;

 procedure set_r3_opecode(a,b,c:byte);
 begin
  case a of
    1:set_opecode(b);
    2:
     begin
      set_opecode($80+b);
      set_opecode(c)
     end;
    3:
     begin
      set_opecode($c0+b);
      set_opecode(c)
     end;
    4:set_opecode($20+b);
    5:set_opecode($30+b);
    6:
     begin
      set_opecode(0);
      set_opecode(b)
     end;
    7:
     begin
      set_opecode($80);
      set_opecode(b);
      set_opecode(c)
     end;
    8:
     begin
      set_opecode($c0);
      set_opecode(b);
      set_opecode(c)
     end
   end;
 end;

 procedure set_mn_opecode(a,b,c,d:byte);
 begin
  case a of
    1:
     begin
      set_opecode(b);
      set_opecode(c)
     end;
    2:
     begin
      set_opecode($80+b);
      set_opecode(c);
      set_opecode(d)
     end;
    3:
     begin
      set_opecode($c0+b);
      set_opecode(c);
      set_opecode(d)
     end;
    4:
     begin
      set_opecode($20+b);
      set_opecode(c)
     end;
    5:
     begin
      set_opecode($30+b);
      set_opecode(c)
     end;
    6:
     begin
      set_opecode(0);
      set_opecode(b);
      set_opecode(c)
     end;
    7:
     begin
      set_opecode($80);
      set_opecode(b);
      set_opecode(c);
      set_opecode(d)
     end;
    8:
     begin
      set_opecode($c0);
      set_opecode(b);
      set_opecode(c);
      set_opecode(d)
     end
   end;
 end;

 function islabel(c:char):boolean;
 begin
  if (c>='A')and(c<='Z') then
    islabel:=true
   else
    if (c>='0')and(c<='9') then
      islabel:=true
     else
      if (c='_')or(c='.')or(c='!') then
        islabel:=true
       else
        islabel:=false
 end;

 function islabel2(c:char):boolean;
 begin
  if (c>='A')and(c<='Z') then
    islabel2:=true
   else
    if (c>='0')and(c<='9') then
      islabel2:=true
     else
      if c='_' then
        islabel2:=true
       else
        islabel2:=false
 end;

 procedure get_operand(var p:integer;var txt:txttyp);
 var
  c:char;
 begin
  txt:='';
  c:=asmtext[p];
  while (c<>',')and(c<>';')and(c<>#$1a) do
   begin
    if (c='''') then
      begin
       repeat
        txt:=txt+c;
        p:=p+1;
        c:=asmtext[p]
       until (c='''')or(c=#$1a);
       if c=#$1a then p:=p-1;
      end;
    txt:=txt+upcase(c);
    p:=p+1;
    c:=asmtext[p]
   end
 end;


 function taiou(tmp:txttyp):integer;
 var
  p,s,last:integer;
 begin
  tmp:=tmp+#$1a;
  p:=2;
  s:=2;
  while (tmp[p]<>#$1a)and(s>1) do
   begin
    if tmp[p]='''' then
      begin
       p:=p+1;
       while tmp[p]<>'''' do
        p:=p+1;
       p:=p+1
      end
    else if tmp[p]='(' then
          begin
           s:=s+1;
           p:=p+1
          end
    else if tmp[p]=')' then
          begin
           last:=p;
           s:=s-1;
           p:=p+1
          end
    else p:=p+1
   end;
  if s=1 then taiou:=last
   else
    taiou:=0
 end;

 procedure r_to_i32(x:real;var ih,il:integer);
 begin
  il:=trunc(x-int(x/256)*256);
  x:=int(x/256);
  il:=swap((il shl 8)+trunc(x-int(x/256)*256));
  x:=int(x/256);
  ih:=trunc(x-int(x/256)*256);
  x:=int(x/256);
  ih:=swap((ih shl 8)+trunc(x-int(x/256)*256));
 end;

 procedure i32_to_r(ih,il:integer;var x:real);
 begin
  x:=((hi(ih)*256.0+lo(ih))*256.0+hi(il))*256.0+lo(il);
 end;

 procedure slim(var tmp:txttyp);
 var
  p:integer;
 begin
  if length(tmp)<>0 then
    begin
     p:=1;
     while (tmp[p]=' ')or(tmp[p]=#9) do
      p:=p+1;
     delete(tmp,1,p-1);
     p:=length(tmp);
     while (tmp[p]=' ')or(tmp[p]=#9) do
      p:=p-1;
     tmp:=copy(tmp,1,p)
    end
 end;

 function operate(var x:real):integer;
 var ih1,ih2,il1,il2,op:integer;
 begin
  op:=0;
  case o_stack[o_stack_p-1] of
    '+':x:=v_stack[v_stack_p-1]+x;
    '-':x:=v_stack[v_stack_p-1]-x;
    '*':
     begin
      r_to_i32(v_stack[v_stack_p-1],ih1,il1);
      r_to_i32(x,ih2,il2);
      x:=lo(il1)*lo(il2)+256.0*(hi(il1)*lo(il2)+lo(il1)*hi(il2)+256.0*(lo(ih1)*lo(il2)+hi(il1)*hi(il2)+lo(il1)*lo(ih2)));
     end;
    '/':
     if x<>0 then
       x:=v_stack[v_stack_p-1]/x
      else
       op:=2;
    '|':
     begin
      r_to_i32(v_stack[v_stack_p-1],ih1,il1);
      r_to_i32(x,ih2,il2);
      i32_to_r(ih1 or ih2,il1 or il2,x)
     end;
    '&':
     begin
      r_to_i32(v_stack[v_stack_p-1],ih1,il1);
      r_to_i32(x,ih2,il2);
      i32_to_r(ih1 and ih2,il1 and il2,x)
     end;
    '%':
     if x<>0 then
       x:=v_stack[v_stack_p-1]-int(v_stack[v_stack_p-1]/x)*x
      else
       op:=2;
   else
    op:=3
   end;
  if op=0 then
    x:=regular(x);
  operate:=op;
 end;

 function oprlevel(c:char):integer;
 begin
  case c of
    'S':oprlevel:=1;
    '(':oprlevel:=2;
    '|':oprlevel:=3;
    '&':oprlevel:=4;
    '%':oprlevel:=5;
    '+':oprlevel:=6;
    '-':oprlevel:=6;
    '*':oprlevel:=7;
    '/':oprlevel:=7
   else
    oprlevel:=0;
   end
 end;

 function eval2(txt:txttyp;var z:real):integer;
 var
  c:char;
  minus,radix,i,x2:integer;
  c_str:txttyp;
  h,l:integer;
  err,txt_p,c_str_p:integer;
  set_x,txtend:boolean;
  j,pp:integer;
  x,y:real;

 begin
  o_stack[1]:='S';
  o_stack_p:=2;
  v_stack_p:=1;
  undef_flag:=false;
  undef_flag2:=false;
  slim(txt);
  if length(txt)>0 then begin
  txt:=txt+#$1a;
  txt_p:=1;
  txtend:=false;
  err:=0;
  minus:=0;
  set_x:=false;
  repeat
   c:=txt[txt_p];
   while (c=#9)or(c=' ') do
    begin
     txt_p:=txt_p+1;
     c:=txt[txt_p]
    end;
   if ((c>='0')and(c<='9'))or(c='$') then
     if set_x=true then err:=22
      else
       begin
        set_x:=true;
        c_str_p:=1;
        c_str:='';
        repeat
         c_str:=c_str+c;
         c_str_p:=c_str_p+1;
         txt_p:=txt_p+1;
         c:=txt[txt_p]
        until not(((c>='0')and(c<='9'))or((c>='A')and(c<='F'))or(c='_')or(c='O')or(c='H'));
        if c_str[1]='$' then
          begin
           delete(c_str,1,1);
           c_str:='0'+c_str+'H';
           c_str_p:=c_str_p+1
          end;
        c_str_p:=c_str_p-1;
        case c_str[c_str_p] of
          'B':radix:=2;
          'O':radix:=8;
          'D':radix:=10;
          'H':radix:=16
         else
          begin
           radix:=10;
           c_str_p:=c_str_p+1
          end
         end;
        x:=0;
        for i:=1 to c_str_p-1 do
          begin
           if c_str[i]<>'_' then
           begin
           c:=c_str[i];
           if (c>='0')and(c<='9') then x2:=ord(c)-$30
            else
             if (c>='A')and(c<='F') then x2:=ord(c)-$37
              else
               err:=23;
           if x2>=radix then err:=23
            else
             x:=x*radix+x2
           end;
          end;
        if minus=1 then
         begin
          x:=-x;
          minus:=0
         end;
        x:=regular(x)
       end
   else
    begin
     i:=oprlevel(c);
     if (i>2)and(i<=7) then
      begin
       txt_p:=txt_p+1;
       if set_x=false then
         case c of
           '+':;
           '-':minus:=1-minus;
           '*':
            begin
             set_x:=true;
             x:=lc
            end;
          else
           err:=24
          end
        else
         begin
          while (err=0)and(i<=oprlevel(o_stack[o_stack_p-1])) do
            begin
             err:=operate(x);
             o_stack_p:=o_stack_p-1;
             v_stack_p:=v_stack_p-1
            end;
            begin
             o_stack[o_stack_p]:=c;
             v_stack[v_stack_p]:=x;
             o_stack_p:=o_stack_p+1;
             v_stack_p:=v_stack_p+1;
             if (err=0)and(o_stack_p>16) then err:=25
            end;
          set_x:=false
         end
      end
      else if c='(' then
       if set_x=true then err:=22
         else
          begin
           txt_p:=txt_p+1;
           o_stack[o_stack_p]:='(';
           o_stack_p:=o_stack_p+1;
           if o_stack_p>16 then err:=25
          end
      else if c=')' then
       if set_x=false then err:=24
         else
          begin
           txt_p:=txt_p+1;
           while (err=0)and(o_stack[o_stack_p-1]<>'(') do
            begin
             err:=operate(x);
             o_stack_p:=o_stack_p-1;
             v_stack_p:=v_stack_p-1
            end;
           o_stack_p:=o_stack_p-1
           end
      else if c='''' then
       if set_x=true then err:=22
        else
         begin
          set_x:=true;
          x:=0;
          s_end:=false;
          txt_p:=txt_p+1;
          repeat
           case txt[txt_p] of
             '''':
               if txt[txt_p+1]='''' then
                 begin
                  x:=ord('''');
                  txt_p:=txt_p+2
                 end
                else
                 begin
                  s_end:=true;
                  txt_p:=txt_p+1
                 end;
             #$1a:
               begin
                err:=19;
                s_end:=true
               end
            else
             begin
              x:=ord(txt[txt_p]);
              txt_p:=txt_p+1
             end
            end;
          until s_end=true
         end
      else if c='@' then
       begin
        if set_x=false then
          begin
           txt_p:=txt_p+1;
           i:=ord(txt[txt_p])-$30;
           if (i>=0)and(i+1<current_file^.arg_cnt) then
             begin
              x:=current_file^.arg[i+1];
              txt_p:=txt_p+1;
              set_x:=true
             end
            else
             err:=31
          end
         else
          err:=22
       end
      else if c=#$1a then
       begin
        if set_x=false then err:=22 else begin
        txtend:=true;
        while (err=0)and(o_stack_p>2) do
         begin
          err:=operate(x);
          o_stack_p:=o_stack_p-1;
          v_stack_p:=v_stack_p-1
         end
        end
       end
      else if islabel(c)=true then
       if set_x=false then
         begin
          c_str:='';
          while islabel(c)=true do
           begin
            c_str:=c_str+c;
            txt_p:=txt_p+1;
            c:=txt[txt_p]
           end;
          err:=find_label(c_str,x,next_pnt);
          set_x:=true;
          if next_pnt=equ_pnt then
            undef_flag2:=true;
          if (pass_sw<>3)and((err=11)or(x=-1)) then
            begin
             err:=0;
             x:=0;
             undef_flag:=true;
            end;
          if minus=1 then
            begin
             x:=-x;
             minus:=0
            end;
          x:=regular(x)
         end
        else
         err:=22
      else
       err:=4
    end
  until (err<>0)or(txtend=true);
  z:=x;
  eval2:=err
  end
  else
   eval2:=21
 end;

 function regname(tmp:txttyp):byte;
 begin
  slim(tmp);
  if tmp='A' then regname:=0
  else if tmp='IL' then regname:=1
  else if tmp='BA' then regname:=2
  else if tmp='I'  then regname:=3
  else if tmp='X'  then regname:=4
  else if tmp='Y'  then regname:=5
  else if tmp='U'  then regname:=6
  else if tmp='S'  then regname:=7
  else if tmp='B'  then regname:=8
  else if tmp='F'  then regname:=9
  else if tmp='IMR' then regname:=10
  else regname:=255
 end;

 function int_ram_adr(tmp:txttyp;var id,n:byte):integer;
 var
  tmp2:txttyp;
  err:integer;
  z:real;
 begin
  err:=0;
  slim(tmp);
  tmp:=copy(tmp,1,length(tmp)-1);
  delete(tmp,1,1);
  slim(tmp);
  tmp2:=tmp;
  n:=0;
  if tmp='BP' then
    id:=0
  else if tmp='PX' then
    id:=1
  else if tmp='PY' then
    id:=2
  else if tmp='BP+PX' then
    id:=3
  else if tmp='BP+PY' then
    id:=4
  else if copy(tmp,1,2)='BP' then
         begin
          id:=0;
          delete(tmp,1,2);
          slim(tmp);
          if (tmp[1]='+')or(tmp[1]='-') then
            begin
             err:=eval2(tmp,z);
             if err=0 then n:=xlow(z)
            end
           else
	    begin
	     id:=5;
	     err:=eval2(tmp2,z);
	     if err=0 then n:=xlow(z)
	    end
         end
  else if copy(tmp,1,2)='PX' then
         begin
          id:=1;
          delete(tmp,1,2);
          slim(tmp);
          if (tmp[1]='+')or(tmp[1]='-') then
            begin
	     err:=eval2(tmp,z);
             if err=0 then n:=xlow(z)
            end
           else
	    begin
	     id:=5;
	     err:=eval2(tmp2,z);
	     if err=0 then n:=xlow(z)
	    end
         end
  else if copy(tmp,1,2)='PY' then
         begin
          id:=2;
          delete(tmp,1,2);
          slim(tmp);
          if (tmp[1]='+')or(tmp[1]='-') then
            begin
             err:=eval2(tmp,z);
             if err=0 then n:=xlow(z)
            end
           else
	    begin
	     id:=5;
	     err:=eval2(tmp2,z);
	     if err=0 then n:=xlow(z)
	    end
         end
  else
   begin
    id:=5;
    err:=eval2(tmp,z);
    if err=0 then n:=xlow(z)
   end;
  if err<>0 then int_ram_adr:=5 else int_ram_adr:=0
 end;

 function evalx(tmp:txttyp;var gid,id,low,mid,high:byte):integer;
 var
  err,n:integer;
  pp:byte;
  z:real;
 begin
  err:=0;
  slim(tmp);
  if length(tmp)>0 then begin
  if (tmp[1]='(')and(tmp[length(tmp)]=')') then
    begin
     gid:=2;
     n:=taiou(tmp);
     if n=length(tmp) then
       begin
        err:=int_ram_adr(tmp,id,low);
       end
      else
       begin
        gid:=0;
        err:=eval2(tmp,z);
        if err=0 then
         begin
          low:=xlow(z);
          mid:=xmid(z);
          high:=xhigh(z)
         end
       end
    end
  else if (tmp[1]='[')and(tmp[length(tmp)]=']') then
    begin
     gid:=3;
     tmp:=copy(tmp,1,length(tmp)-1);
     delete(tmp,1,1);
     slim(tmp);
     n:=regname(tmp);
     if (n>=0)and(n<=7) then
       begin
        id:=1;
        low:=n
       end
     else if (tmp[length(tmp)]='+')and(tmp[length(tmp)-1]='+') then
       begin
        tmp:=copy(tmp,1,length(tmp)-2);
        n:=regname(tmp);
        if (n>=0)and(n<=7) then
          begin
           id:=4;
           low:=n
          end
         else
          err:=4
       end
     else if (tmp[1]='-')and(tmp[2]='-') then
       begin
        delete(tmp,1,2);
        n:=regname(tmp);
        if (n>=0)and(n<=7) then
          begin
           id:=5;
           low:=n
          end
         else
          begin
           gid:=0;
           err:=eval2(tmp,z);
           if err=0 then
            begin
             low:=xlow(z);
             mid:=xmid(z);
             high:=xhigh(z)
            end
          end
       end
     else if tmp[1]='(' then
       begin
        n:=taiou(tmp);
        if n=length(tmp) then
          begin
           id:=6;
           err:=int_ram_adr(tmp,low,mid)
          end
         else
          if n<>0 then
            begin
             n:=n+1;
             while (tmp[n]=' ')or(tmp[n]=#9) do
              n:=n+1;
             if tmp[n]='+' then
               begin
                id:=7;
                err:=int_ram_adr(copy(tmp,1,n-1),low,mid);
                if err=0 then
                  begin
                   delete(tmp,1,n);
                   err:=eval2(tmp,z);
                   if err=0 then high:=xlow(z)
                  end
               end
             else if tmp[n]='-' then
               begin
                id:=8;
                err:=int_ram_adr(copy(tmp,1,n-1),low,mid);
                if err=0 then
                  begin
                   delete(tmp,1,n);
                   err:=eval2(tmp,z);
                   if err=0 then high:=xlow(z)
                  end
               end
             else
              begin
              id:=0;
              err:=eval2(tmp,z);
              if err=0 then
               begin
                low:=xlow(z);
                mid:=xmid(z);
                high:=xhigh(z)
               end
             end
            end
           else
            err:=6
       end
     else if xpos(tmp,id,pp)<>0 then
       begin
        n:=regname(copy(tmp,1,pp-1));
        if (n>=0)and(n<=7) then
          begin
           low:=n;
           delete(tmp,1,pp);
           err:=eval2(tmp,z);
           if err=0 then
             mid:=xlow(z)
          end
         else
          begin
           id:=0;
           err:=eval2(tmp,z);
           if err=0 then
            begin
             low:=xlow(z);
             mid:=xmid(z);
             high:=xhigh(z)
            end
          end
       end
      else
          begin
           id:=0;
           err:=eval2(tmp,z);
           if err=0 then
            begin
             low:=xlow(z);
             mid:=xmid(z);
             high:=xhigh(z)
            end
          end;
    end
  else
   begin
    id:=regname(tmp);
    if id<>255 then
      gid:=1
     else
      begin
       err:=eval2(tmp,z);
       if err=0 then
         begin
          gid:=0;
          low:=xlow(z);
          mid:=xmid(z);
          high:=xhigh(z)
         end
      end
   end;
 end
 else
  err:=21;
  evalx:=err
 end;

 function mv_operand(mvflag:byte;var pnt:integer):byte;
 var
  err:integer;
  oprtxt:txttyp;
  gid_1,gid_2,id_1,id_2,op1_1,op1_2,op2_1,op2_2,op3_1,op3_2:byte;
 begin
  get_operand(pnt,oprtxt);
  if asmtext[pnt]=',' then
    begin
     err:=evalx(oprtxt,gid_1,id_1,op1_1,op2_1,op3_1);
     if err=0 then
       begin
        pnt:=pnt+1;
        get_operand(pnt,oprtxt);
        if asmtext[pnt]<>',' then begin
        err:=evalx(oprtxt,gid_2,id_2,op1_2,op2_2,op3_2);
        if err=0 then
          begin
           if gid_1=1 then
             if mvflag<>0 then err:=7 else  begin
              case gid_2 of
                0:
                 if id_1<=7 then
                   begin
                    set_opecode(8+id_1);
                    set_reg_opecode(id_1,op1_2,op2_2,op3_2)
                   end
                  else
                   err:=7;
                1:
                 if (id_1<=7)and(id_2<=7) then
                   begin
                    set_opecode($fd);
                    set_opecode(id_1*16+id_2)
                   end
                  else if (id_1=0)and(id_2=8) then set_opecode($74)
                  else if (id_1=8)and(id_2=0) then set_opecode($75)
                  else
                   err:=7;
                2:
                 if (id_1<=7) then
                   begin
                    err:=prebyte(id_2,0);
                    set_opecode($80+id_1);
                    set_opecode(op1_2)
                   end
                  else
                   err:=7;
                3:
                 if (id_1<=7) then
                   case id_2 of
                     0:
                      begin
                       set_opecode($88+id_1);
                       set_opecode(op1_2);
                       set_opecode(op2_2);
                       set_opecode(op3_2)
                      end;
                     1..5:
                      if (id_1<=6)and(op1_2<=7) then
                        begin
                         set_opecode($90+id_1);
                         set_r3_opecode(id_2,op1_2,op2_2)
                        end
                       else
                        err:=7;
                     6..8:
                      if id_1<=6 then
                        begin
                         err:=prebyte(op1_2,0);
                         set_opecode($98+id_1);
                         set_r3_opecode(id_2,op2_2,op3_2)
                        end
                       else
                        err:=7;
                    end;
                  else
                   err:=7
               end
             end
           else if gid_1=2 then
            case gid_2 of
              0:
               begin
                err:=prebyte(id_1,0);
                if (err=0)and(mvflag<=2) then
                  begin
                   case mvflag of
                     0:set_opecode($cc);
                     1:set_opecode($cd);
                     2:set_opecode($dc)
                    end;
                   set_opecode(op1_1);
                   set_opecode(op1_2);
                   if mvflag>0 then set_opecode(op2_2);
                   if mvflag>1 then set_opecode(op3_2)
                  end
                 else
                  if err=0 then err:=7
               end;
              1:
               if mvflag<>0 then err:=7 else begin
                err:=prebyte(id_1,0);
                if (err=0)and(id_2<=7) then
                  begin
                   set_opecode($a0+id_2);
                   set_opecode(op1_1)
                  end
                 else
                  if err=0 then err:=7
                end;
              2:
               begin
               err:=prebyte(id_1,id_2);
               if err=0 then
                 begin
                  set_opecode($c8+mvflag);
                  set_opecode(op1_1);
                  set_opecode(op1_2)
                 end
               end;
              3:
               if err=0 then
                 case id_2 of
                   0:
                    begin
                    err:=prebyte(id_1,0);
                    if mvflag<=3 then
                      begin
                       set_opecode($d0+mvflag);
                       set_opecode(op1_1);
                       set_reg_opecode(4,op1_2,op2_2,op3_2)
                      end
                     else
                      if err=0 then err:=7
                    end;
                   1..3:
                    begin
                    err:=prebyte(id_1,0);
                    if (mvflag<=2)and(op1_2<=7) then
                      begin
                       set_opecode($e0+mvflag);
                       set_mn_opecode(id_2,op1_2,op1_1,op2_2);
                      end
                     else if (id_2<>1)and(mvflag=3)and(op1_2<=7) then
                      begin
                       set_opecode($56);
                       set_mn_opecode(id_2,op1_2,op1_1,op2_2)
                      end
                     else
                      if err=0 then err:=7
                    end;
                   4,5:
                    begin
                    err:=prebyte(id_1,0);
                    if (mvflag<=3)and(op1_2<=7) then
                      begin
                       set_opecode($e0+mvflag);
                       set_mn_opecode(id_2,op1_2,op1_1,op2_2)
                      end
                     else
                      if err=0 then err:=7
                    end;
                   6..8:
                    begin
                    err:=prebyte(id_1,op1_2);
                    if mvflag<=3 then
                      begin
                       set_opecode($f0+mvflag);
                       set_mn_opecode(id_2,op1_1,op2_2,op3_2)
                      end
                     else
                      if err=0 then err:=7
                    end
                  end
             end
           else if gid_1=3 then
            case id_1 of
              0:
               case gid_2 of
                 1:
		  if (id_2<=7)and(mvflag=0) then
                    begin
                     set_opecode($a8+id_2);
                     set_reg_opecode(4,op1_1,op2_1,op3_1)
                    end
                   else
                    err:=7;
                 2:
                  begin
                  err:=prebyte(id_2,0);
                  if (err=0)and(mvflag<=3) then
                    begin
                     set_opecode($d8+mvflag);
                     set_opecode(op1_1);
                     set_reg_opecode(4,op2_1,op3_1,op1_2)
                    end
                   else
                    if err=0 then err:=7
                  end
                else
                 err:=7
                end;
              1..5:
               case gid_2 of
                 1:
		  if (op1_1<=7)and(id_2<=6)and(mvflag=0) then
                    begin
                     set_opecode($b0+id_2);
                     set_r3_opecode(id_1,op1_1,op2_1)
                    end
                   else
                    err:=7;
                 2:
                  begin
                  err:=prebyte(id_2,0);
                  if (op1_1<=7)and(err=0) then
                    if (mvflag<=2)or((mvflag=3)and(id_1 in [4,5])) then
                      begin
                       set_opecode($e8+mvflag);
                       set_mn_opecode(id_1,op1_1,op1_2,op2_1)
                      end
                    else if (mvflag=3)and(id_1<>0) then
                      begin
                       set_opecode($5e);
                       set_mn_opecode(id_1,op1_1,op1_2,op2_1)
                      end
                    else
                     err:=7
                   else
                    if err=0 then err:=7
                  end
                else
                 err:=7
                end;
              6..8:
               case gid_2 of
                 1:
                  begin
                  err:=prebyte(op1_1,0);
                  if (err=0)and(id_2<=6)and(mvflag=0) then
                    begin
                     set_opecode($b8+id_2);
                     set_r3_opecode(id_1,op2_1,op3_1)
                    end
                   else
                    if err=0 then err:=7
                  end;
                 2:
                  begin
                   err:=prebyte(op1_1,id_2);
                   if (err=0)and(mvflag<=3) then
                     begin
                      set_opecode($f8+mvflag);
                      set_mn_opecode(id_1,op2_1,op1_2,op3_1)
                     end
                    else
                     if err=0 then err:=7
                  end
                else
                 err:=7
                end
             end
           else
            err:=7
          end
         end
        else
         err:=8;
       end
   end
  else
   err:=8;
  mv_operand:=err
 end;

 function two_operand(typ,offset:byte;var pnt:integer):byte;
 var
  gid_1,gid_2,id_1,id_2,op1_1,op1_2,op2_1,op2_2,op3_1,op3_2:byte;
  oprtxt:txttyp;
  err:integer;
 begin
  err:=0;
  get_operand(pnt,oprtxt);
  if asmtext[pnt]=',' then
    begin
     err:=evalx(oprtxt,gid_1,id_1,op1_1,op2_1,op3_1);
     if err=0 then
       begin
        pnt:=pnt+1;
        get_operand(pnt,oprtxt);
        if asmtext[pnt]<>',' then
          begin
           err:=evalx(oprtxt,gid_2,id_2,op1_2,op2_2,op3_2);
           if err=0 then
             begin
              if (typ in [1,2,3])and(gid_1=1)and(id_1=0)and(gid_2=0) then
                begin
                 set_opecode(offset);
                 set_opecode(op1_2)
                end
              else if (typ in [1,2,3,7])and(gid_1=2)and(gid_2=0) then
                begin
                 err:=prebyte(id_1,0);
                 if err=0 then
                   begin
                    if typ=7 then
                      set_opecode($47)
                     else
                      set_opecode(offset+1);
                    set_opecode(op1_1);
                    set_opecode(op1_2)
                   end
                end
              else if (typ in [2,3])and(gid_1=3)and(id_1=0)and(gid_2=0) then
                begin
                 set_opecode(offset+2);
                 set_reg_opecode(4,op1_1,op2_1,op3_1);
                 set_opecode(op1_2)
                end
              else if (typ in [1,2,3,4,7])and(gid_1=2)and(gid_2=1)and(id_2=0) then
                begin
                 err:=prebyte(id_1,0);
                 if err=0 then
                   begin
                    case typ of
                      4:set_opecode(offset+5);
                      7:set_opecode($57)
                     else
                      set_opecode(offset+3)
                     end;
                    set_opecode(op1_1)
                   end
                end
              else if (typ in [1,2])and(gid_1=1)and(id_1=0)and(gid_2=2) then
                begin
                 err:=prebyte(id_2,0);
                 if err=0 then
                   begin
                    case typ of
                      1:set_opecode(offset+2);
                      2:set_opecode(offset+7)
                     end;
                    set_opecode(op1_2)
                   end
                end
              else if ((typ in [2,4,5,6,8,9])or(offset=$60))and(gid_1=2)and(gid_2=2) then
                begin
                 err:=prebyte(id_1,id_2);
                 if err=0 then
                   begin
                    case typ of
                      2:  set_opecode(offset+6);
                      3:  set_opecode(offset+$57);
                      4:  set_opecode(offset+4);
                      5,6:set_opecode(offset);
                      8,9:set_opecode($c6+typ-8)
                     end;
                    set_opecode(op1_1);
                    set_opecode(op1_2)
                   end
                end
              else if (typ=1)and(offset in [$40,$48])and(gid_1=1)and(gid_2=1)and(id_2<=7) then
                begin
                 if id_1 in [0,1] then
                   begin
                    set_opecode(offset+6);
                   end
                 else if id_1 in [2,3] then
                   begin
                    set_opecode(offset+4);
                   end
                 else if id_1 in [4,5,6,7] then
                   begin
                    set_opecode(offset+5);
                   end
                 else err:=7;
                 if err=0 then set_opecode(id_1*16+id_2)
                end
              else if (typ=6)and(gid_1=1)and(gid_2=1) then
                begin
                 if (id_1=0)and(id_2=8) then
                   set_opecode($dd)
                  else
                   begin
                    if (id_1<=7)and(id_2<=7) then
                      begin
                       set_opecode($ed);
                       set_opecode(id_1*16+id_2)
                      end
                     else
                      err:=7
                   end
                end
              else if (typ in [8,9])and(gid_1=2)and(gid_2=1)and(id_2<=7) then
                begin
                 err:=prebyte(id_1,0);
                 if err=0 then
                   begin
                    set_opecode($d6+typ-8);
		    set_opecode(id_2);
		    set_opecode(op1_1)
		   end
                end
              else
               err:=7
             end
          end
         else
          err:=8
       end
    end
   else
    err:=8;
  two_operand:=err
 end;

 function one_operand(typ,offset:byte;var pnt:integer):byte;
 var
  gid_1,id_1,op1_1,op2_1,op3_1:byte;
  oprtxt:txttyp;
  err:integer;
  x:real;

 begin
  get_operand(pp,oprtxt);
  if asmtext[pp]<>',' then
    begin
     err:=evalx(oprtxt,gid_1,id_1,op1_1,op2_1,op3_1);
     if err=0 then
       begin
        if (typ in [1,3])and(gid_1=1)and(id_1=0) then
          set_opecode(offset)
        else if (typ in [2,3,4,5])and(gid_1=2) then
          begin
           err:=prebyte(id_1,0);
           if err=0 then
             begin
              if typ=5 then
                set_opecode($10)
               else
                set_opecode(offset+1);
              set_opecode(op1_1)
             end
          end
        else if (typ in [2,5])and(gid_1=1)and(id_1<=7) then
          begin
           if typ=5 then
             set_opecode($11)
            else
             set_opecode(offset);
           set_opecode(id_1)
          end
        else if (typ in [5,7,8,9,10,11])and(gid_1=0) then
          begin
           case typ of
             5:    set_opecode(2);
             7..10:set_opecode($14+typ-7);
             11:   set_opecode(4)
            end;
           set_reg_opecode(2,op1_1,op2_1,op3_1)
          end
        else if (typ in [6,12])and(gid_1=0) then
          begin
           case typ of
             6: set_opecode(3);
             12:set_opecode(5)
            end;
           set_reg_opecode(4,op1_1,op2_1,op3_1)
          end
        else if (typ in [14,16])and(gid_1=1) then
          begin
           case id_1 of
             0..5:set_opecode($28+id_1+8*(typ-14));
             9,10:set_opecode($2e+id_1-9+8*(typ-14))
            else
             err:=7
            end
          end
        else if (typ in [13,15])and(gid_1=1) then
          begin
           if id_1=9 then
             set_opecode($4f+8*(typ-13))
            else
             begin
              case id_1 of
                0..5:
                  begin
                   set_opecode($b0+id_1-$10*(typ-13));
                   set_opecode($37-8*(typ-13))
                  end;
                10:
                  begin
                   set_opecode($30);
                   set_opecode($e8-4*(typ-13));
                   set_opecode($37-8*(typ-13));
                   set_opecode($fb)
                  end
               else
                err:=7
               end
             end
          end
        else if (typ in [17,18])and(gid_1=0) then
          begin
           x:=(op3_1*256.0+op2_1)*256.0+op1_1-lc-2;
           if pass_sw=3 then
             if (x>=0)and(x<=255) then
               begin
                case typ of
                  17:set_opecode(offset+$18);
                  18:set_opecode($12);
                 end;
                set_opecode(trunc(x))
               end
             else if (x<0)and(x>=-255) then
               begin
                case typ of
                  17:set_opecode(offset+$19);
                  18:set_opecode($13);
                 end;
                set_opecode(trunc(-x))
               end
             else
              err:=9
            else
             set_reg_opecode(2,0,0,0)
          end
        else
          err:=7
       end
    end
   else
    err:=8;
  one_operand:=err
 end;

 procedure err_handle;
 var warning:boolean;
 begin
 warning:=false;
 if err<>0 then
   begin
    fatal_err:=true;
 case err of
   1:inbuf:='Prebyte error';
   2:inbuf:='Division by zero';
   3:inbuf:='Operator error';
   4:inbuf:='Unevaluetable operand';
   5:inbuf:='Bad internal RAM addressing';
   6:inbuf:='Bad external MEMORY addressing';
   7:inbuf:='Undefined instruction';
   8:inbuf:='Bad separater';
   9:inbuf:='Branch too far';
  10:inbuf:='Label format error';
  11:inbuf:='Label not found';
  13:inbuf:='Duplicate label';
  14:inbuf:='"LOCAL" not closed';
  15:inbuf:='No label before EQU';
  16:inbuf:='LOCAL nesting too deep';
  17:inbuf:='ENDL used without LOCAL';
  18:inbuf:='EOF comes before END';
  19:inbuf:=''' unmatch';
  20:inbuf:='No label before LOCAL';
  21:inbuf:='Missing operand';
  22:inbuf:='Missing operator';
  23:inbuf:='Numeric format error';
  24:inbuf:='Missing numeric';
  25:inbuf:='Too complex operand';
  26:inbuf:='Location counter wandered';
  27:inbuf:='EQU undefinable(suspicious label is "'+undefined_pnt^.name+'")';
  28:
    begin
     inbuf:='Warning: Location counter already set';
     warning:=true;
    end;
  29:
    begin
     inbuf:='Warning: Used PRE while auto-prebyte is active';
     warning:=true;
    end;
  30:inbuf:='Too many arguments';
  31:inbuf:='Bad argument number';
  32:
    begin
     inbuf:='Warning: No effective code';
     warning:=true
    end;
  33:
    begin
     inbuf:='Warning: LOCAL and ENDL not match in included file';
     warning:=true
    end;
  end;
  if (warning=false)or(warning_on=true) then
   begin
    str(current_file^.lines,asmtext);
    asmtext:=current_file^.name+^I+asmtext+^I+inbuf;
    writeln('                 ',#13,asmtext);
    if listing_on=true then
      begin
       writeln(listing_txt,asmtext);
       ioerr;
      end;
   end;
  if warning=true then
    fatal_err:=false
 end;
 end;


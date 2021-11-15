unit DPlanning;

{$mode objfpc}{$H+}

interface

uses
  Classes, Objects, SysUtils, DateUtils,DataAccess, SQLDB, BufDataset, DB, Variants,Da_table,
  Generics.Collections,Generics.Defaults,
  fpjson,jsonparser,Graphics,
  RessourcesStrings,clipbrd;


type TIntervention = Class
     public
          dt : TdateTime;
          week_day : integer;
          h_start :  integer;
          h_end : integer;
          planning : longint;
          w_id : longint;
          c_id : longint;
          col_index : integer;

          constructor create (d : tdatetime; hs,he : integer; p,w,c : longint);
          constructor create (i_day,hs,he : integer; p,w,c : longint);
          function gethstart : shortstring;
          function gethend : shortstring;
     end;

Type
  TInterventions = specialize  TObjectList<TIntervention>;

Type   TLine = record
                    sy_id : longint;
                    index : integer;
                    colums : array of TIntervention;
              end;

Type TLPlanning = class
     private

     public
          start_date : tdatetime;
          end_date   : tdatetime;
          linescount : integer;
          colscount  : integer;
          libs       : array of record
                             id : longint;
                             code : shortstring;
                             caption : string;
                       end;
          lines : array of Tline;

          constructor create;
          constructor create(s,e : tdatetime);
          procedure add_inter(inter : TIntervention);
          function add_line : integer;
          function CreateJson : string;
          function isLineEmpty(l : integer) : boolean;
          procedure load(l : TInterventions);
          procedure load(s : string);
          function loadID(s_id : longint) : integer;
          procedure normalize;
          procedure reset;
          destructor destroy();override;
     end;



type
  TPlanning = class(TDa_table)
  private

       procedure add_json_planning(s : string; dstart,dend : tdatetime; p_id, w_id : longint; result : TInterventions);
  public
       procedure init (D : TMainData);
       function loadW(sy_worker : longint; start, endDate : tdatetime) : TInterventions;

       function ToIsoDate (dt : TDateTime) : shortstring;

  end;

function IsoStrToDate(s : shortstring) : TdateTime;

var
  Planning: TPlanning;

const

  cdays : array[1..7] of shortstring = (rs_days_01,rs_days_02,rs_days_03,rs_days_04,rs_days_05,rs_days_06,rs_days_07);

implementation

uses UException;

{$R *.lfm}

function IsoStrToDate(s : shortstring) : TdateTime;

var y,m,d : integer;

begin
  {$IFDEF WINDOWS}
  if not TryIsostrtodate(s,result) then
  {$ENDIF}
  begin
       if TryStrToInt(copy(s,1,4),y) and tryStrToInt(copy(s,5,2),m) and TryStrToInt(copy(s,7,2),d) then
         result:=EncodeDate(y,m,d);
  end;
end;


constructor TIntervention.create (d : tdatetime;  hs,he : integer; p,w,c : longint);

begin
  dt:=d;
  h_start:=hs;
  h_end:=he;
  planning:=p;
  w_id:=w;
  c_id:=c;
  week_day:=DayOfTheWeek(dt);
end;

constructor TIntervention.create (i_day,hs,he : integer; p,w,c : longint);

begin
     h_start:=hs;
     h_end:=he;
     planning:=p;
     w_id:=w;
     c_id:=c;
     week_day:=i_day;
end;

function TIntervention.gethstart : shortstring;
begin
//  result:=inttostr(h_start)+':'+inttostr(m_start);
  result:=format('%0.2d:%1.2d',[h_start div 100,h_start mod 100]);
end;

function TIntervention.gethend : shortstring;

begin
//  result:=inttostr(h_end)+':'+inttostr(m_end);
  result:=format('%0.2d:%1.2d',[h_end div 100,h_end mod 100]);
end;


procedure Tplanning.add_json_planning(s : string; dstart,dend : tdatetime; p_id, w_id : longint; result : TInterventions);

var json : TJSONData;
    Data, Data1,Data2: TJSONData;
    jo1 : TJSONData;
    i,j : integer;
    c_id : int64;
    i_day,i_start,i_end,i_freq : integer;


    procedure add_planning;

    var dtemp : tdatetime;
        dw : integer;
        inter : Tintervention;

    begin
      dtemp:=dstart;
      while CompareDateTime(dtemp,dend)<0 do
      begin
           dw:=DayOfTheWeek(dtemp);
           if i_day=dw then
           begin
                inter:=Tintervention.create(dtemp,i_start,i_end,p_id,w_id,c_id);
                result.Add(inter);
                inter.col_index:=DaysBetween(dstart,dtemp)+1;
            end;
            dtemp:=IncDay(dtemp);
       end;
    end;

begin
  //todo : tester planning au 01/01/2020
  json:=GetJson(s);
  (*
  {
    "PLANNING": [
      {
        "CID": 10,
        "INTERV": [
          {
            "DAY": 1,
            "START": 1030,
            "END": 1130,
            "FREQ": 1
          },
          {
            "DAY": 3,
            "START": 1030,
            "END": 1130,
            "FREQ": 1
          },
          {
            "DAY": 5,
            "START": 910,
            "END": 1020,
            "FREQ": 1
          }
        ]
      },
      {
        "CID": 20,
        "INTERV": [
          {
            "DAY": 1,
            "START": 1430,
            "END": 1530,
            "FREQ": 1
          },
          {
            "DAY": 2,
            "START": 1030,
            "END": 1130,
            "FREQ": 1
          }
        ]
      }
    ]
  }          *)

  IF assigned(json) then
  begin
    data:=Json.findPath('PLANNING');
    if assigned(data) and (data.JSONType=jtarray) then
    begin
         for I:=0 to Data.Count-1 do
         begin
              c_id:=-1;
              jo1:=TJSONArray(Data).Objects[i];
              Data1:=jo1.FindPath('CID');
              if assigned(data) then c_id:=Data1.AsInt64;
              Data1:=jo1.FindPath('INTERV');
              if (assigned(Data1)) and (data1.JSONType=jtarray) then
              begin
                   for j:=0 to Data1.Count-1 do
                   begin
                        i_day:=-1;i_start:=0;i_end:=0;i_freq:=0;
                        jo1:=TJSONArray(Data1).Objects[j];
                        Data2:=jo1.FindPath('DAY');
                        if assigned(data2) then i_day:=Data2.AsInteger;
                        Data2:=jo1.FindPath('START');
                        if assigned(data2) then i_start:=Data2.AsInteger;
                        Data2:=jo1.FindPath('END');
                        if assigned(data2) then i_end:=Data2.AsInteger;
                        Data2:=jo1.FindPath('FREQ');
                        if assigned(data2) then i_freq:=Data2.AsInteger;
                        add_planning;
                   end;
              end;
         end;
    end;
    freeAndNil(json);
  end;
end;



procedure TPlanning.init(D:TMainData);
begin
  inherited init(D);
  table:='PLANNING';
  cle:= 'SY_ID';
  checkcrc:=true;
end;

function TPlanning.loadW(sy_worker : longint; start, enddate : tdatetime) : TInterventions;

var Query : TdataSet;
    sql,s : string;
    s1 : shortstring;
    i,dw, pdw : integer;
    W_id, f_id, p_id : longint;
    dstart, dend,dtemp : tdatetime;
    inter : Tintervention;




begin
  Query:=nil;
  result:=nil;
  sql:=Maindata.getQuery('QPL01','SELECT SY_ID, SY_WID, SY_FORMAT, SY_START, SY_END, SY_DETAIL FROM PLANNING WHERE SY_WID=%w AND SY_START<=''%end'' AND SY_END>=''%start''');
  sql:=sql.Replace('%w',inttostr(sy_worker));
  sql:=sql.Replace('%start',ToIsoDate(start));
  sql:=sql.Replace('%end',ToIsoDate(endDate));
  MainData.readDataSet(Query,sql,true);
  if query.RecordCount>0 then result:=TInterventions.Create();
  WHILE (NOT query.EOF) DO
  BEGIN
    p_id:=query.fields[0].AsInteger;
    w_id:=query.fields[1].AsInteger;
    f_id:=query.fields[2].AsInteger;
    s:=query.fields[3].AsString;
    dstart:=IsostrToDate(s);
    if CompareDateTime(start,dstart)>0 then dstart:=start;
    s:=query.fields[4].AsString;
    dend:=IsoStrToDate(s);
    if CompareDatetime(enddate,dend)<0 then dend:=enddate;
    s:=query.fields[5].AsString;
    if f_id=0 then   // Json Format
    begin
         add_json_planning(s,dstart,dend,p_id,w_id,result);
    end;
   (* i:=1;
    while i<s.Length do
    begin
         s1:=copy(s,i,10);
         trystrtoint(copy(s1,1,1),pdw);
         dtemp:=dstart;
         while CompareDateTime(dtemp,dend)<0 do
         begin
             dw:=DayOfTheWeek(dtemp);
             if pdw=dw then
             begin
                  inter:=Tintervention.create(dtemp,strtoint(copy(s1,2,2)),strtoint(copy(s1,4,2)),strtoint(copy(s1,6,2)),strtoint(copy(s1,8,2)),p_id,w_id,c_id);
                  result.Add(inter);
                  inter.col_index:=DaysBetween(start,dtemp)+1;
             end;
             dtemp:=IncDay(dtemp);
         end;
         i:=i+10;
    end; *)
    query.Next;
  END;
end;


function TPlanning.ToIsoDate (dt : TDateTime) : shortstring;

begin
   result:=FormatDateTime('YYYYMMDD',dt);
end;

constructor TLPlanning.create();

var i : integer;

begin
  colscount:=7;
  linescount:=20;
  setlength(lines,linescount);
  for i:=0 to linescount-1 do
  begin
       setLength(lines[i].colums,colscount);
  end;
  setLength(libs,10);
end;

constructor TLPlanning.create(s,e : tdatetime);

var i : integer;

begin
  start_date:=s;
  end_date:=e;
  colscount:=DaysBetween(start_date,end_date)+1;
  for i:=1 to 2 do
  begin
       add_line;
  end;
  setLength(libs,10);
end;

procedure TLPlanning.add_inter(inter : TIntervention);
var
     nline,col,ncol : integer;
     i,j : integer;
     found : boolean;
     num_index : integer;

begin
     nline:=0; found:=false;
     ncol:=inter.week_day - 1;
     while not found do
     begin
       if lines[nline].SY_ID<=0 then
       begin
            num_index:=loadID(inter.c_id);
            lines[nline].sy_id:=inter.c_id;
            lines[nline].index:=num_index;
       end;
       if lines[nline].SY_ID=inter.c_id then
       begin
            if not assigned(lines[nline].colums[ncol]) then
            begin
                 lines[nline].colums[ncol]:=inter;
                 found:=true;
            end;
       end;
       if not found then
       begin
            if nline>=(linescount-1) then add_line;
            inc(nline);
       end;
     end;
     assert(found=true,'not found');
end;

function TLPlanning.add_line : integer;

var i,j : integer;

begin
     inc(linescount);
     setLength(lines,linescount);
     i:=linescount - 1;
     lines[i].SY_ID:=-1;
     setLength(lines[i].colums,colscount);
     for j:=0 to colscount - 1 do
     begin
          lines[i].colums[j]:=nil;
     end;
end;

function TLPlanning.CreateJson : string;

var jsonobj,lst,objline,objcol : TJSONObject;
    l, c : integer;
    old : longint;
    inter : TIntervention;

begin
     jsonobj := TJSONObject.create();
     jsonobj.add ('PLANNING',TJSONArray.Create);
     for l:=0 to linescount-1 do
     begin
          if (lines[l].SY_ID<>old) and (lines[l].SY_ID>0) then
          begin
            old:=lines[l].SY_ID;
            objline:=TJSONObject.Create(['CID',inttostr(old)]);
            objline.add ('INTERV',TJSONArray.Create);
            jsonobj.Arrays['PLANNING'].add(objline);
          end;
          if (lines[l].SY_ID>0) and (assigned(objline)) then
          begin
            for c:=0 to colscount -1 do
            begin
                   inter:=lines[l].colums[c];
                   if assigned(inter) then
                   begin
                     objcol:=TJSONObject.create();

                     objcol.add('DAY',inttostr(inter.week_day));
                     objcol.add('START',inttostr(inter.h_start));
                     objcol.add('END',inttostr(inter.h_end));
                   //  if inter.freq<>1 then objcol.add('FREQ',inttostr(inter.freq));
                     objline.Arrays['INTERV'].add(objcol);
                   end;
            end;
          end;
     end;

     result:=jsonobj.FormatJson([foSingleLineArray,foSingleLineObject,foDoNotQuoteMembers,foUseTabchar,foSkipWhiteSpace],1);
     //Clipboard.AsText:=result;

     jsonobj.Free;
end;

function TLPlanning.isLineEmpty(l : integer) : boolean;

var i : integer;

begin
  assert((l>0) and (l<linescount),'Incorrect line number');
  result:=true;
  i:=0;
  while (result) and (i<colscount) do
  begin
       if assigned(lines[l-1].colums[i]) then result:=false else inc(i);
  end;
 // assert((not result) and (i=colscount),'Error searching in line');
end;

(*
  {
    "PLANNING": [
      {
        "CID": 10,
        "INTERV": [
          {
            "DAY": 1,
            "START": 1030,
            "END": 1130,
            "FREQ": 1
          },
          {
            "DAY": 3,
            "START": 1030,
            "END": 1130,
            "FREQ": 1
          },
          {
            "DAY": 5,
            "START": 910,
            "END": 1020,
            "FREQ": 1
          }
        ]
      },
      {
        "CID": 20,
        "INTERV": [
          {
            "DAY": 1,
            "START": 1430,
            "END": 1530,
            "FREQ": 1
          },
          {
            "DAY": 2,
            "START": 1030,
            "END": 1130,
            "FREQ": 1
          }
        ]
      }
    ]
  }          *)

procedure TLPlanning.load(l : TInterventions);

var  inter : Tintervention;
     nline,col,ncol : integer;
     i,j : integer;
     found : boolean;
     num_index : integer;

begin
     reset;
     if assigned(l) then
     begin
          for inter in l do
          begin
               add_inter(inter);
               {nline:=0; found:=false;
               ncol:=DaysBetween(start_date,inter.dt);
               while not found do
               begin
                 if lines[nline].SY_ID<=0 then
                 begin
                      num_index:=loadID(inter.c_id);
                      lines[nline].sy_id:=inter.c_id;
                      lines[nline].index:=num_index;
                 end;
                 if lines[nline].SY_ID=inter.c_id then
                 begin
                      if not assigned(lines[nline].colums[ncol]) then
                      begin
                           lines[nline].colums[ncol]:=inter;
                           found:=true;
                      end;
                 end;
                 if not found then
                 begin
                      inc(nline);
                      if nline>=(linescount-1) then
                      begin
                          linescount:=linescount+20;
                          setlength(lines,linescount);
                          for i:=nline to linescount-1 do
                          begin
                               lines[i].SY_ID:=-1;
                               setLength(lines[i].colums,colscount);
                               for j:=0 to colscount - 1 do
                               begin
                                    lines[i].colums[j]:=nil;
                               end;
                          end;
                      end;
                 end;
               end; }
          end;
          normalize;
     end;
end;

procedure TLPlanning.load(s : String);

var json : TJSONData;
    Data, Data1,Data2: TJSONData;
    jo1 : TJSONData;
    i,j : integer;
    c_id : int64;
    i_day,i_start,i_end,i_freq : integer;

    procedure add_planning;

    var dtemp : tdatetime;
        dw : integer;
        inter : Tintervention;

    begin
       inter:=Tintervention.create(i_day,i_start,i_end,0,0,c_id);
       inter.col_index:=i_day;
       add_inter(inter);
    end;

begin
     reset();
     json:=GetJson(s);
     IF assigned(json) then
     begin
       data:=Json.findPath('PLANNING');
       if assigned(data) and (data.JSONType=jtarray) then
       begin
            for I:=0 to Data.Count-1 do
            begin
                 c_id:=-1;
                 jo1:=TJSONArray(Data).Objects[i];
                 Data1:=jo1.FindPath('CID');
                 if assigned(data) then c_id:=Data1.AsInt64;
                 Data1:=jo1.FindPath('INTERV');
                 if (assigned(Data1)) and (data1.JSONType=jtarray) then
                 begin
                      for j:=0 to Data1.Count-1 do
                      begin
                           i_day:=-1;i_start:=0;i_end:=0;i_freq:=0;
                           jo1:=TJSONArray(Data1).Objects[j];
                           Data2:=jo1.FindPath('DAY');
                           if assigned(data2) then i_day:=Data2.AsInteger;
                           Data2:=jo1.FindPath('START');
                           if assigned(data2) then i_start:=Data2.AsInteger;
                           Data2:=jo1.FindPath('END');
                           if assigned(data2) then i_end:=Data2.AsInteger;
                           Data2:=jo1.FindPath('FREQ');
                           if assigned(data2) then i_freq:=Data2.AsInteger;
                           add_planning;
                      end;
                 end;
            end;
       end;
       freeAndNil(json);
     end;
     normalize;
end;

function TLPlanning.loadID(s_id : longint) : integer;

var i, j : integer;
    found : boolean;
    query : Tdataset;
    sql : string;

begin
     j:=length(libs);
     found:=false;
     for i:=0 to j-1 do
     begin
       if libs[i].ID=s_id then
       begin
           found:=true;
           result:=i;
           break;
       end else
       if libs[i].id<0 then break;
     end;
     if not found then
     begin
         if i=j-1 then
         begin
             setlength(libs,j + 10);
             for i:=j to j+9 do
             begin
               libs[i].ID:=-1;
             end;
             i:=j + 1;
         end;
         query:=nil;
         sql:=MainData.getQuery('Q0014','SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM WORKER WHERE SY_ID=%id');
         sql:=sql.Replace('%id',inttostr(s_id));
         Maindata.readDataSet(query,sql,true);
         if query.RecordCount>0 then
         begin
              libs[i].id:=s_id;
              libs[i].code:=query.fields[0].asString;
              libs[i].caption:=query.fields[1].asString+' '+query.fields[2].asString;
         end;
         query.close;
         query.free;
         result:=i;
     end;
end;

procedure TLPlanning.reset;

var i,j : integer;

begin
     for i:=0 to linescount - 1 do
     begin
       lines[i].SY_ID:=-1;
       for j:=0 to colscount - 1 do
       begin
         freeAndNil(lines[i].colums[j]);
       end;
     end;
     j:=length(libs);
     for i:=0 to j - 1 do
     begin
       libs[i].id:=-1;
       libs[i].code:='';
       libs[i].caption:='';
     end;
end;

procedure TLPlanning.normalize;

var swap : boolean;
    l,c : integer;
    tmp_line : Tline;
    temp : TIntervention;
    minl,minl1 : integer;

begin
     swap:=true;
     // Sort on sy_id
     while swap do
     begin
       swap:=false;
       l:=1;
       while (l<linescount) do
       begin
         if (lines[l].sy_id>0) and (lines[l-1].sy_id>0) and (lines[l-1].sy_id>lines[l].sy_id) then
         begin
              swap:=true;
              tmp_line:=lines[l];
              lines[l]:=lines[l-1];
              lines[l - 1]:=tmp_line;
         end;
         inc(l);
       end;
     end;
     //If the planning is on several lines, sort on hours.
     swap:=true;
     while (swap) do
     begin
       swap:=false;
       l:=1;
       while (l<linescount) do
       begin
         if (lines[l].sy_id>0) and (lines[l].sy_id=lines[l-1].sy_id) then
         begin
              for c:=0 to colscount-1 do
              begin
                if assigned(lines[l].colums[c]) and assigned(lines[l-1].colums[c]) then
                begin
                     if lines[l-1].colums[c].h_start>lines[l].colums[c].h_start then
                     begin
                          temp:=lines[l].colums[c];
                          lines[l].colums[c]:=lines[l-1].colums[c];
                          lines[l-1].colums[c]:=temp;
                          swap:=true;
                     end;
                end;
              end;
         end;
         inc(l);
       end;
     end;
     //
     for l:=0 to linescount - 2 do
     begin
          if (lines[l].sy_id>0) and (lines[l+1].sy_id=lines[l].sy_id) then
          begin
              minl:=2400;
              minl1:=2400;
              for c:=0 to colscount -1 do
              begin
                   if assigned(lines[l].colums[c]) then if lines[l].colums[c].h_start<minl then minl:=lines[l].colums[c].h_start;
                   if assigned(lines[l+1].colums[c]) then if lines[l+1].colums[c].h_start<minl1 then minl1:=lines[l+1].colums[c].h_start;
              end;
              for c:=0 to colscount -1 do
              begin
                   if assigned(lines[l].colums[c]) and (not assigned(lines[l+1].colums[c])) then
                   begin
                        if abs(lines[l].colums[c].h_start-minl)>abs(lines[l].colums[c].h_start-minl1) then
                        begin
                            lines[l+1].colums[c]:=lines[l].colums[c];
                            lines[l].colums[c]:=nil;
                        end;
                   end;
              end;

          end;
     end;
end;

destructor TLPlanning.destroy();

var i,j : integer;

begin
    // reset;
end;

end.


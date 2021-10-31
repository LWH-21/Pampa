unit DPlanning;

{$mode objfpc}{$H+}

interface

uses
  Classes, Objects, SysUtils, DateUtils,DataAccess, SQLDB, BufDataset, DB, Variants,Da_table,
  Generics.Collections,Generics.Defaults,
  fpjson,jsonparser,
  RessourcesStrings;


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
          function gethstart : shortstring;
          function gethend : shortstring;
     end;

Type
  TInterventions = specialize  TObjectList<TIntervention>;

Type TLPlanning = class
     private

     public
          start_date : tdatetime;
          end_date   : tdatetime;
          linescount : integer;
          colscount : integer;

          lines : array of record
                                  sy_id : longint;
                                  colums : array of TIntervention;
                            end;

          constructor create(s,e : tdatetime);
          procedure load(l : TInterventions);
          procedure normalize;
          procedure reset;
     end;



type
  TPlanning = class(TDa_table)
  private

       procedure add_json_planning(s : string; dstart,dend : tdatetime; p_id, w_id : longint; result : TInterventions);
  public
       procedure init (D : TMainData);
       function loadW(sy_worker : longint; start, endDate : tdatetime) : TInterventions;

       function IsoStrToDate(s : shortstring) : TdateTime;
       function ToIsoDate (dt : TDateTime) : shortstring;

  end;



var
  Planning: TPlanning;

const

  cdays : array[1..7] of shortstring = (rs_days_01,rs_days_02,rs_days_03,rs_days_04,rs_days_05,rs_days_06,rs_days_07);

implementation

uses UException;

{$R *.lfm}

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

function TPlanning.IsoStrToDate(s : shortstring) : TdateTime;

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

function TPlanning.ToIsoDate (dt : TDateTime) : shortstring;

begin
   result:=FormatDateTime('YYYYMMDD',dt);
end;

constructor TLPlanning.create(s,e : tdatetime);

var i : integer;

begin
  start_date:=s;
  end_date:=e;
  colscount:=DaysBetween(start_date,end_date)+1;
  linescount:=20;
  setlength(lines,linescount);
  for i:=0 to linescount-1 do
  begin
       setLength(lines[i].colums,colscount);
  end;
end;

procedure TLPlanning.load(l : TInterventions);

var  inter : Tintervention;
     nline,col,ncol : integer;
     i,j : integer;
     found : boolean;

begin
     reset;
     if assigned(l) then
     begin
          for inter in l do
          begin
               nline:=0; found:=false;
               ncol:=DaysBetween(start_date,inter.dt);
               while not found do
               begin
                 if lines[nline].SY_ID<=0 then
                 begin
                      lines[nline].sy_id:=inter.c_id;
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
               end;
          end;
          normalize;
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
         lines[i].colums[j]:=nil;
       end;
     end;
end;

procedure TLPlanning.normalize;

var swap : boolean;
    l,c : integer;
    temp : TIntervention;

begin
     swap:=true;
     //If the planning is on several lines, sort on hours.
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

end;

end.


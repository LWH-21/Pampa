unit DPlanning;

{$mode objfpc}{$H+}

interface

uses
  Classes, Objects, SysUtils, DateUtils,DataAccess, SQLDB, BufDataset, DB, Variants,Da_table,
  Generics.Collections,Generics.Defaults,
  RessourcesStrings;


type TIntervention = Class
     public
          dt : TdateTime;
          week_day : integer;
          h_start :  integer;
          m_start : integer;
          h_end : integer;
          m_end : integer;
          planning : longint;
          w_id : longint;
          c_id : longint;
          col_index : integer;

          constructor create (d : tdatetime; h,m,he, me : integer; p,w,c : longint);
          function gethstart : shortstring;
          function gethend : shortstring;
     end;

Type
  TInterventions = specialize  TObjectList<TIntervention>;

type
  TPlanning = class(TDa_table)
  private

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

constructor TIntervention.create (d : tdatetime; h,m,he, me : integer; p,w,c : longint);

begin
  dt:=d;
  h_start:=h;m_start:=m;
  h_end:=he; m_end:=me;
  planning:=p;
  w_id:=w;
  c_id:=c;
  week_day:=DayOfTheWeek(dt);
end;


function TIntervention.gethstart : shortstring;
begin
//  result:=inttostr(h_start)+':'+inttostr(m_start);
  result:=format('%0.2d:%1.2d',[h_start,m_start]);
end;

function TIntervention.gethend : shortstring;

begin
//  result:=inttostr(h_end)+':'+inttostr(m_end);
  result:=format('%0.2d:%1.2d',[h_end,m_end]);
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
    W_id, c_id, p_id : longint;
    dstart, dend,dtemp : tdatetime;
    inter : Tintervention;




begin
  Query:=nil;
  result:=nil;
  sql:=Maindata.getQuery('QPL01','SELECT SY_ID, W_ID, C_ID, SY_START, SY_END, SY_DETAIL FROM PLANNING WHERE W_ID=%w AND SY_START<=''%end'' AND SY_END>=''%start''');
  sql:=sql.Replace('%w',inttostr(sy_worker));
  sql:=sql.Replace('%start',ToIsoDate(start));
  sql:=sql.Replace('%end',ToIsoDate(endDate));
  MainData.readDataSet(Query,sql,true);
  if query.RecordCount>0 then result:=TInterventions.Create();
  WHILE (NOT query.EOF) DO
  BEGIN
    p_id:=query.fields[0].AsInteger;
    w_id:=query.fields[1].AsInteger;
    c_id:=query.fields[2].AsInteger;
    s:=query.fields[3].AsString;
    dstart:=IsostrToDate(s);
    if CompareDateTime(start,dstart)>0 then dstart:=start;
    s:=query.fields[4].AsString;
    dend:=IsoStrToDate(s);
    if CompareDatetime(enddate,dend)<0 then dend:=enddate;
    s:=query.fields[5].AsString;
    i:=1;
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
    end;
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

end.


unit DPlanning;

{$mode objfpc}{$H+}

interface

uses
  Classes, Types, SysUtils, DateUtils,DataAccess, SQLDB, BufDataset, DB, Variants,Da_table,
  Generics.Collections,Generics.Defaults,
  fpjson,jsonparser,Graphics,BGRABitmap, BGRABitmapTypes,
  RessourcesStrings,clipbrd;


type TIntervention = Class
     private
          dh_start : real;
          dh_end : real;
          bounds : Trect;
     public
          dt : TdateTime;
          selected : boolean;
          week_day : integer;
          h_start :  integer;
          h_end : integer;
          planning : longint;
          w_id : longint;
          c_id : longint;
          col_index : integer;
          line_index: integer;


          constructor create (d : tdatetime; hs,he : integer; p,w,c : longint);
          constructor create (i_day,hs,he : integer; p,w,c : longint);
          function Contains(x,y : integer) : boolean;
          function getBounds : Trect;
          function gethstart : shortstring;
          function gethend : shortstring;
          function getDecimalHstart : real;
          function getDecimalHEnd : real;
          function getHint : string;
          procedure setBounds(r : trect);
          function test : boolean;
     end;

Type
  TInterventions = specialize  TList<TIntervention>;

  TInterComparer = class (specialize TComparer <TIntervention>)
                    function Compare(constref Left, Right: TIntervention): Integer;override;
                   end;


Type   TLine = record
                    sy_id : longint;
                    index : integer;
                    colums : array of TIntervention;
              end;

Type Tlibs =  array of record
                             id : longint;
                             code : shortstring;
                             caption : string;
                             color : TBGRAPixel;
                       end;

Type TLPlanning = class
     private
          src : char; // C=collection, J=json
          p_id : longint; // Plannind ID
          w_id : longint; // Worker ID

     public
          start_date : tdatetime;
          end_date   : tdatetime;
          linescount : integer;
          colscount  : integer;
          libs       : Tlibs;
          lines : array of Tline;

          constructor create;
          constructor create(s,e : tdatetime);
          procedure add_inter(inter : TIntervention);
          function add_line : integer;
          function CreateJson(id : longint = 0) : string;
          function getColor(l: integer) : TBGRAPixel;
          function getInterventions : TInterventions;
          function getEnd : integer;
          function getStart : integer;
          function getPlanningId(): longint;
          function getInterAt(x,y : integer) : TIntervention;
          function getWorkerId() : longint;
          function isLineEmpty(l : integer) : boolean;
          procedure load(l : TInterventions);
          procedure load(s : string; w, p : longint);
          function loadID(s_id : longint) : integer;
          procedure normalize;
          procedure reset;
          procedure setBounds(line,col : integer;r : trect);
          destructor destroy();override;
     end;



type
  TPlanning = class(TDa_table)
  private
       refdate : tdatetime;
       procedure add_json_planning(s : string; dstart,dend : tdatetime; p_id, w_id : longint; result : TInterventions);
  public
       procedure init (D : TMainData);
       function loadW(sy_worker : longint; start, endDate : tdatetime) : TInterventions;

       function ToIsoDate (dt : TDateTime) : shortstring;
       function Write(mat : TLPlanning ): boolean;
  end;

function IsoStrToDate(s : shortstring) : TdateTime;
function formatdate(dt : tdatetime) : shortstring;
function resumeplanning(s : string) : string;

var
  Planning: TPlanning;

const

  cdays : array[1..7] of shortstring = (rs_days_01,rs_days_02,rs_days_03,rs_days_04,rs_days_05,rs_days_06,rs_days_07);

implementation

uses Main, UException;

{$R *.lfm}

Const
   colcount = 189;
   colors: array [1..colcount] of string =
       (
       '#810541', '#7D0541', '#7D0552', '#872657', '#7E354D', '#7F4E52', '#7F525D', '#7F5A58', '#997070', '#B38481',
       '#BC8F8F', '#C5908E', '#C48189', '#C48793', '#E8ADAA', '#C4AEAD', '#ECC5C0', '#FFCBA4', '#F8B88B', '#EDC9AF',
       '#FFDDCA', '#FDD7E4', '#FFE6E8', '#FFE4E1', '#FFDFDD', '#FFCCCB', '#FBCFCD', '#FBBBB9', '#FFC0CB', '#FFB6C1',
       '#FAAFBE', '#FAAFBA', '#F9A7B0', '#FEA3AA', '#E7A1B0', '#E799A3', '#E38AAE', '#F778A1', '#E56E94', '#DB7093',
       '#D16587', '#C25A7C', '#C25283', '#E75480', '#F660AB', '#FF69B4', '#FC6C85', '#F6358A', '#F52887', '#FF1493',
       '#F535AA', '#FD349C', '#E45E9D', '#E3319D', '#E4287C', '#E30B5D', '#DC143C', '#C32148', '#C21E56', '#C12869',
       '#C12267', '#CA226B', '#C71585', '#C12283', '#B3446C', '#B93B8F', '#DA70D6', '#DF73D4', '#EE82EE', '#F433FF',
       '#FF00FF', '#E238EC', '#D462FF', '#C45AEC', '#BA55D3', '#A74AC7', '#B048B5', '#D291BC', '#915F6D', '#7E587E',
       '#614051', '#583759', '#5E5A80', '#4E5180', '#6A5ACD', '#6960EC', '#736AFF', '#7B68EE', '#7575CF', '#6C2DC7',
       '#6A0DAD', '#5453A6', '#483D8B', '#4E387E', '#571B7E', '#4B0150', '#36013F', '#461B7E', '#4B0082', '#342D7E',
       '#663399', '#6A287E', '#8B008B', '#800080', '#86608E', '#9932CC', '#9400D3', '#8D38C9', '#A23BEC', '#B041FF',
       '#842DCE', '#8A2BE2', '#7A5DC7', '#7F38EC', '#9D00FF', '#8E35EF', '#893BFF', '#967BB6', '#9370DB', '#8467D7',
       '#9172EC', '#9E7BFF', '#CCCCFF', '#DCD0FF', '#E0B0FF', '#D891EF', '#B666D2', '#C38EC7', '#C8A2C8', '#DDA0DD',
       '#E6A9EC', '#F2A2E8', '#F9B7FF', '#C6AEC7', '#D2B9D3', '#D8BFD8', '#E9CFEC', '#FCDFFF', '#EBDDE2', '#E9E4D4',
       '#EDE6D6', '#FAF0DD', '#F8F0E3', '#FFF0F5', '#FDEEF4', '#FFF9E3', '#FDF5E6', '#FAF0E6', '#FFF5EE', '#FF0000',
       '#00FF00', '#FF00FF', '#C0C0C0', '#00FFFF', '#800000', '#FFFF00', '#008000', '#800080', '#008080', '#A4C400',
       '#87794E', '#60A917', '#76608A', '#008A00', '#647687', '#00ABA9', '#6D8764', '#00AFF0', '#825A2C', '#1BA1E2',
       '#E3C800', '#0050EF', '#F0A30A', '#6A00FF', '#FA6800', '#AA00FF', '#CE352C', '#DC4FAD', '#A20025', '#D80073',
       '#4390DF', '#59CDE2', '#7AD61D', '#FFC194', '#F472D0', '#00CCFF', '#45FFFD', '#78AA1C', '#DA5A53'
        ) ;



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

function formatdate(dt : tdatetime) : shortstring;

begin
  if yearof(dt)>=2499 then result:='???' else  result:=datetostr(dt);
end;

function resumeplanning(s : string) : string;

var json : TJSONData;
    Data, Data1,Data2: TJSONData;
    jo1 : TJSONData;
    i,j,i_day,i_start,i_end : integer;

begin
    result:='';
     json:=GetJson(s);
     IF assigned(json) then
     begin
       data:=Json.findPath('PLANNING');
       if assigned(data) and (data.JSONType=jtarray) then
       begin
            for i:=0 to Data.Count-1 do
            begin
                 jo1:=TJSONArray(Data).Objects[i];
                 Data1:=jo1.FindPath('INTERV');
                 if (assigned(Data1)) and (data1.JSONType=jtarray) then
                 begin
                      for j:=0 to Data1.Count-1 do
                      begin
                           i_day:=-1;i_start:=0;i_end:=0;
                           jo1:=TJSONArray(Data1).Objects[j];
                           Data2:=jo1.FindPath('DAY');
                           if assigned(data2) then i_day:=Data2.AsInteger;
                           Data2:=jo1.FindPath('START');
                           if assigned(data2) then i_start:=Data2.AsInteger;
                           Data2:=jo1.FindPath('END');
                           if assigned(data2) then i_end:=Data2.AsInteger;
                           result:=result+inttostr(i_day)+' '+inttostr(i_start)+' '+inttostr(i_end)+'; ';
                      end;
                 end;
            end;
       end;
       freeAndNil(json);
     end;
end;

function TIntercomparer.Compare(constref left,right : TIntervention) : integer;

begin
    result:=comparedate(left.dt, right.dt);
     if result=0 then
     begin
       if left.h_start<right.h_start then result:=-1 else
         if left.h_start>right.h_start then result:=1;
     end;
     if result=0 then
     begin
       if left.h_end<right.h_end then result:=-1 else
         if left.h_end>right.h_end then result:=1;
     end;
     if result=0 then
     begin
       if left.c_id<right.c_id then result:=-1 else
         if left.c_id>right.c_id then result:=1;
     end;
end;

constructor TIntervention.create (d : tdatetime;  hs,he : integer; p,w,c : longint);

begin
  selected:=false;
  dt:=d;
  h_start:=hs;
  h_end:=he;
  planning:=p;
  w_id:=w;
  c_id:=c;
  week_day:=DayOfTheWeek(dt);
  dh_start:=(h_start div 100)+((h_start mod 100) / 60);
  dh_end:=(h_end div 100)+((h_end mod 100) / 60);
  bounds.left:=0;bounds.right:=0;bounds.top:=0;bounds.bottom:=0;
end;

constructor TIntervention.create (i_day,hs,he : integer; p,w,c : longint);

begin
     selected:=false;
     h_start:=hs;
     h_end:=he;
     planning:=p;
     w_id:=w;
     c_id:=c;
     week_day:=i_day;
     dh_start:=(h_start div 100)+((h_start mod 100) / 60);
     dh_end:=(h_end div 100)+((h_end mod 100) / 60);
     bounds.left:=0;bounds.right:=0;bounds.top:=0;bounds.bottom:=0;
     col_index:=i_day;
end;

function TIntervention.Contains(x,y : integer) : boolean;

var p : tpoint;

begin
     assert((x>=0) and (y>=0),'Invalid coordinates');
     p.x:=x;
     p.y:=y;
     result:=false;
     result:=bounds.Contains(p);
end;

function TIntervention.getDecimalHstart : real;

begin
     result:=dh_start;
end;

function TIntervention.getDecimalHEnd : real;

begin
     result:=dh_end;
end;

function TIntervention.getBounds : Trect;

begin
     result:=bounds;
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

function TIntervention.getHint : string;

begin
  result:= datetostr(dt)+' ('+cdays[week_day]+')'+LineEnding;
  result:=result+gethstart+'-'+gethend+' '+LineEnding;
end;

procedure TIntervention.setBounds(r : trect);

begin
  bounds:=r;
end;

function TIntervention.test : boolean;

begin
  result:=true;
  if h_start>=h_end then result:=false;
  if (week_day<1) or (week_day>7) then result:=false;
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
                inter.col_index:=DaysBetween(refdate,dtemp)+1;
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

function TPlanning.Write(mat : TLPlanning ): boolean;

var script : string;
    wid, id,crc : longint;
    sql,s : string;
    i : integer;

begin
  result:=true;
  script:='';
  wid:=mat.getWorkerId();
  id:=mat.getPlanningId();
  if id<0 then
  begin
       id:=getNextId();
  end;
  sql:='INSERT OR REPLACE INTO PLANNING(SY_ID, SY_WID, SY_START, SY_END, SY_LASTUSER, SY_ROWVERSION, SY_CRC) VALUES (%id, %wid, ''%start'', ''%end'',''%user'',''%ts'',''%crc'')';
  sql:=sql.Replace('%id',inttostr(id));
  sql:=sql.Replace('%wid',inttostr(mat.w_id));
  s:=intTostr(mat.getStart());
  sql:=sql.Replace('%start',s);
  s:=intTostr(mat.getEnd());
  sql:=sql.Replace('%end',s);
  s:=Mainform.username;
  sql:=sql.Replace('%user',s);
  s:=DateToISO8601(now);
  sql:=sql.Replace('%ts',s);
  s:=mat.CreateJson;
  crc:=crc32(0,s+inttostr(mat.getEnd())+inttostr(mat.getStart()));
  sql:=sql.Replace('%crc',inttostr(crc));
  sql:=sql+';'+LineEnding;;
  sql:=sql+'UPDATE DPLANNING SET SY_DETAIL='''' WHERE PL_ID=%id';
  sql:=sql.Replace('%id',inttostr(id));
  sql:=sql+';'+LineEnding;

  for i:=0 to length(mat.libs)-1 do
  begin
       if mat.libs[i].ID>0 then
       begin
         s:=mat.CreateJson(mat.libs[i].id);
         sql:=sql+'INSERT OR REPLACE INTO DPLANNING(PL_ID, C_ID, SY_DETAIL) VALUES (%id, %cid, ''%dt'')';
         sql:=sql.Replace('%id',inttostr(id));
         sql:=sql.Replace('%cid',inttostr(mat.libs[i].id));
         sql:=sql.Replace('%dt',s);
         sql:=sql+';'+LineEnding;
       end;
  end;

  sql:=sql+'DELETE FROM DPLANNING WHERE PL_ID=%id AND SY_DETAIL<='' ''';
  sql:=sql.Replace('%id',inttostr(id));
  sql:=sql+';'+LineEnding;
  Clipboard.AsText:=sql;
  Maindata.doScript(sql);
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
    W_id, p_id,c_id : longint;
    dstart, dend,dtemp : tdatetime;
    inter : Tintervention;

begin
  refdate:=start;
  Query:=nil;
  result:=nil;
  sql:=Maindata.getQuery('QPL01','SELECT P.SY_ID, P.SY_WID, D.C_ID, P.SY_START, P.SY_END, D.SY_DETAIL FROM PLANNING P INNER JOIN DPLANNING D ON D.PL_ID=P.SY_ID WHERE P.SY_WID=%w AND P.SY_START<=''%end'' AND P.SY_END>=''%start''');
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
    add_json_planning(s,dstart,dend,p_id,w_id,result);

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
  start_date:=today();
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
     ncol:=inter.col_index - 1;
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
                 inter.col_index:=ncol;
                 inter.line_index:=nline;
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

function TLPlanning.CreateJson(id : longint = 0) : string;

var jsonobj,lst,objline,objcol : TJSONObject;
    l, c : integer;
    old : longint;
    inter : TIntervention;

begin
     jsonobj := TJSONObject.create();
     jsonobj.add ('PLANNING',TJSONArray.Create);
     for l:=0 to linescount-1 do
     begin
          if (lines[l].SY_ID<>old) and (lines[l].SY_ID>0) and ((id=0) or (lines[l].SY_ID=id)) then
          begin
            old:=lines[l].SY_ID;
            objline:=TJSONObject.Create(['CID',inttostr(old)]);
            objline.add ('INTERV',TJSONArray.Create);
            jsonobj.Arrays['PLANNING'].add(objline);
          end;
          if (lines[l].SY_ID>0) and ((id=0) or (lines[l].SY_ID=id)) and (assigned(objline)) then
          begin
            for c:=0 to colscount -1 do
            begin
                   inter:=lines[l].colums[c];
                   if assigned(inter) then
                   begin
                     if inter.test() then
                     begin
                          objcol:=TJSONObject.create();
                          objcol.add('DAY',inttostr(inter.week_day));
                          objcol.add('START',inttostr(inter.h_start));
                          objcol.add('END',inttostr(inter.h_end));
                          objline.Arrays['INTERV'].add(objcol);
                     end;
                   end;
            end;
          end;
     end;

     result:=jsonobj.FormatJson([foSingleLineArray,foSingleLineObject,foDoNotQuoteMembers,foUseTabchar,foSkipWhiteSpace],1);
     //Clipboard.AsText:=result;

     jsonobj.Free;
end;

function TLPlanning.getColor(l : integer) : TBGRAPixel;

begin
     result:=BGRAWhite;
     assert((l>=0) ,'Invalid coordinates line:'+inttostr(l));
     assert(l<linescount,'Invalid line: '+inttostr(l));
     if (lines[l].sy_id>0) then
     begin
          assert( (lines[l].index>=0) and (lines[l].index<length(libs)),'Invalid index');
          result := libs[lines[l].index].color;
     end;
end;

function TLPlanning.getInterventions : TInterventions;

var l,c : integer;
    comp : TInterComparer;

begin
     result:=TInterventions.Create;
     for l:=0 to linescount-1 do
     begin
            for c:=0 to colscount-1 do
            begin
                   if assigned(lines[l].colums[c]) then
                   result.add(lines[l].colums[c]);
            end;
     end;
     comp:=TInterComparer.Create;
     result.sort(comp);
     freeAndNil(comp);
end;

function TLPlanning.getEnd : integer;

begin
     result:=Yearof(self.end_date)*10000+
     MonthOf(self.end_date)*100+
     DayOf(self.end_date);
     if result<=19500101 then result:=24991231;
end;

function TLPlanning.getStart : integer;

begin
     result:=Yearof(start_date)*10000+
     MonthOf(start_date)*100+
     DayOf(start_date);
end;

function TLPlanning.getPlanningId(): longint;

begin
     result:=self.p_id;
end;

function TLPlanning.getInterAt(x,y : integer) : TIntervention;

var i, j : integer;

begin
     assert((x>=0) and (y>=0),'Invalid coordinates x:'+inttostr(x)+' y:'+inttostr(y));
     result:=nil;
     for i:=0 to linescount-1 do
     begin
          for j:=0 to colscount-1 do
          begin
               if assigned(lines[i].colums[j]) then
               begin
                 if lines[i].colums[j].contains(x,y) then
                 begin
                   result:=lines[i].colums[j];
                   exit;
                 end;
               end;
          end;
     end;
end;

function TLPlanning.getWorkerId() : longint;

begin
     result:=self.w_id;
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
       while (l.Count>0) do
       begin
            inter:=l.ExtractIndex(0);
            add_inter(inter);
       end;
       normalize;
     end;
(*     if assigned(l) then
     begin
          for inter in l do
          begin
               add_inter(inter);
          end;
          normalize;
     end; *)
end;

procedure TLPlanning.load(s : String; w, p : longint);

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
     self.w_id:=w;
     self.p_id:=p;
     src:='C';
     if s<=' ' then exit;
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


    function calc_code (s : string) : integer;

    var i : integer;

    begin
      result:=0;
      for i:=1 to s.Length do
      begin
           result:=result+i*ord(s[i]);
           result:=result+i;
       end;
    end;

begin
     src:='J';
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
         sql:=MainData.getQuery('Q0014','SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM CUSTOMER WHERE SY_ID=%id');
         sql:=sql.Replace('%id',inttostr(s_id));
         Maindata.readDataSet(query,sql,true);
         if query.RecordCount>0 then
         begin
              libs[i].id:=s_id;
              libs[i].code:=query.fields[0].asString;
              libs[i].caption:=query.fields[1].asString+' '+query.fields[2].asString;
         end;

         sql := libs[i].code+'-'+libs[i].caption;
         j:=calc_code(sql);
         j:=(j mod colcount) + 1;
         libs[i].color.FromString(colors[j]);
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

procedure TLPlanning.setBounds(line,col : integer;r : trect);

begin
     assert((col<colscount) and (col>=0) ,'Invalid column : '+inttostr(col));
     assert((line<linescount) and (line>=0),'Invalid line : '+inttostr(line));
     assert( not r.IsEmpty,'Rectangle is empty');
     assert( assigned(lines[line].colums[col]),'Nothing at line '+inttostr(line)+' column '+inttostr(col));
     if assigned(lines[line].colums[col]) then
     begin
          lines[line].colums[col].setBounds(r);
     end;
end;

destructor TLPlanning.destroy();

var i,j : integer;

begin
   //  if (src='J') then
//     begin
         for i:=0 to linescount-1 do
         begin
           for j:=0 to colscount-1 do
           begin
             if (assigned(lines[i].colums[j])) then freeAndNil(lines[i].colums[j]);
           end;
         end;
  //   end;
     inherited;
end;



end.


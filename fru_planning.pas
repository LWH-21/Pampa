unit Fru_planning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Buttons, ExtCtrls, GR32,
  LCLType, EditBtn,
  DB,DataAccess,
  ressourcesStrings,
  fpjson,jsonparser,
  GR32_Image, dw_f, DWorker, Dateutils, FSearch, DPlanning;

type

  TPlanMode = (pm_week, pm_month, pm_graphweek, pm_graphmonth);

  { TFr_planning }

  TFr_planning = class(TW_F)
    SB_previous: TBitBtn;
    Ed_date: TDateEdit;

    Ed_code: TEdit;
    Ed_name: TEdit;
    plan: TPaintBox32;
    SB_next: TBitBtn;
    ScrollBar1: TScrollBar;
    SB_rech: TSpeedButton;


    procedure Ed_dateChange(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure planPaintBuffer(Sender: TObject);
    procedure SB_rechClick(Sender: TObject);
    procedure SB_previousClick(Sender: TObject);
    procedure SB_nextClick(Sender: TObject);

  private
    mode : TPlanMode;

    startdate : tdatetime;
    col : TInterventions;
    lines : array[1..255] of record
                                  sy_id : longint;
                                  caption:shortstring;
                                  colums : array[1..31] of TIntervention;
                            end;


  public
    function CanClose : boolean;override;
    procedure draw_week;
    function getcode : shortstring;override;
    function getinfos : shortstring;override;
    procedure init(Data: PtrInt); override;
    procedure init(p_id : longint;j : string);override;
    procedure remplir_planning;
    procedure reset_planning;
    procedure setid(p_id : longint);
    destructor Destroy;override;
  end;

implementation

{$R *.lfm}

uses Main;

function TFr_planning.CanClose : boolean;

begin
  if id>0 then
  begin
    MainForm.HistoManager.AddHisto(self, id, 'R');
  end;
  result:=true;
end;

procedure TFr_planning.init(Data: PtrInt);

begin
  mode:=pm_week;
  Caption := rs_planning;
  startdate:=Today();
  startdate:=StartOfTheWeek(startdate);
  ed_date.date:=StartDate;
  id:=-1;
  if parent is TWincontrol then
  begin
    TWincontrol(parent).Caption := Caption;
  end;
  remplir_planning;
end;

procedure TFr_planning.init(p_id : longint;j : string);

var data,fjson : TJsonData;
    s : shortstring;
    y,m,d : integer;

begin
  mode:=pm_week;
  Caption := rs_planning;
  startdate:=Today();
  reset_planning;
  if assigned(col) then freeandnil(col);
  if j>' ' then
  begin
    try
       try
          fjson:=GetJson(j);
          data:=fjson.findPath('histo.caption');
          if assigned(data) then caption:=data.AsString;
          data:=fjson.findPath('histo.infos');
          if assigned(data) then
          begin
              s:=data.AsString;
              if copy(s,3,2)='WT' then mode:=pm_week;
              if copy(s,3,2)='MT' then mode:=pm_month;
              if copy(s,3,2)='WG' then mode:=pm_graphweek;
              if copy(s,3,2)='MG' then mode:=pm_graphmonth;
              if not trystrtodate(copy(s,6,8),startdate,'yyyymmdd') then
              begin
                if trystrtoint(copy(s,6,4),y) and
                trystrtoint(copy(s,10,2),m) and
                trystrtoint(copy(s,12,2),d) then
                begin
                  tryEncodeDateTime(y,m,d,0,0,0,0,startdate);
                end;
              end;
          end;
       except
         j:='';
       end;
    finally
      freeAndNil(fjson)
    end;
  end;
  setid(p_id);
  startdate:=StartOfTheWeek(startdate);
 // ed_date.date:=StartDate;


  if parent is TWincontrol then
  begin
    TWincontrol(parent).Caption := Caption;
  end;
  remplir_planning;
end;

procedure TFr_planning.planPaintBuffer(Sender: TObject);


var w,h : integer;

begin
  w:=plan.Width;
  h:=Plan.height;

  Plan.Buffer.Clear(color32(255,255,250,255));
  plan.Buffer.FrameRectS(0,1,w,h-1,color32(255,0,0,0));

  case mode of
       pm_week : draw_week;
  end;

end;

procedure TFr_planning.FrameResize(Sender: TObject);

var w,h,header,hline,limite : integer;

begin
  w:=plan.Width;
  h:=Plan.height;
  header:=80;
  hline:=60;
  limite:=w div 4;

  ed_date.Top:=plan.Top+5;
  ed_date.left:=plan.left+((limite - ed_date.Width) div 2);
  sb_previous.Top:=ed_date.top;
  sb_previous.Left:=ed_date.left - sb_previous.Width - 10;
  sb_next.top :=ed_date.top;
  sb_next.Left:=ed_date.Left+ed_date.Width + 10;
  sb_next.BringToFront;
  sb_previous.bringToFront;
  ed_date.BringToFront;
end;

procedure TFr_planning.Ed_dateChange(Sender: TObject);

var start : Tdatetime;

begin
  start:=Ed_date.Date;
  start:=StartOfTheWeek(start);
  Ed_date.Date:=start;
  if start<>startdate then
  begin
    startdate:=start;
    remplir_planning;
  end;
end;

procedure TFr_planning.SB_rechClick(Sender: TObject);

var num : longint;
    start : Tdatetime;
    f,l,c : shortstring;

begin
  if not assigned(FSearch.Search) then
  begin
       FSearch.Search:= TSearch.create(MainForm);
  end;
  FSearch.Search.init(worker);
  FSearch.Search.showModal;
  Fsearch.Search.get_result(num,f,l,c);
  id:=num;
  Ed_code.Text:=c;
  ed_name.Caption:=l+' '+f;

  remplir_planning;
  if id>0 then
  begin
    Caption := rs_planning+' ('+TRIM(c)+') '+trim(l);
    MainForm.HistoManager.AddHisto(self, id, 'R');
    if parent is TWincontrol then
    begin
         TWincontrol(parent).Caption := Caption;
    end;
  end;

end;

procedure TFr_planning.SB_previousClick(Sender: TObject);
begin
  startdate:=incday(startdate,-7);
  remplir_planning;
end;

procedure TFr_planning.SB_nextClick(Sender: TObject);
begin
  startdate:=incday(startdate,7);
  remplir_planning;
end;

procedure TFr_planning.draw_week;

var w,h : integer;
  limite : integer;
  header, hline  : integer;
  tsem : integer;
  i,l,c : integer;
  s : shortstring;
  r : trect;
  tmpdate : tdatetime;


begin

     w:=plan.Width;
     h:=Plan.height;
     header:=60;
     hline:=60;

     limite:=w div 4;

     tsem := (w - limite) div 7;

     //Header
     plan.Buffer.FillRect(1,1,w-1,header-1,color32(255,255,255));
     plan.Buffer.FrameRectS(0,1,w,header-1,color32(255,0,0,0));
     plan.Buffer.line(1,header,w-1,header ,color32(0,0,0,0));
     plan.Buffer.line(1,header-1,w-1,header-1 ,color32(0,0,0,0));

     plan.Buffer.Line(limite,1,limite,h - 1,color32(0,0,128,255),true);
     tmpdate:=startdate;
     for i:=0 to 6 do
     begin
       if i>0 then plan.Buffer.Line(limite + i*tsem,1,limite+ i*tsem,h - 1,color32(0,0,128,255),true);
       r.Left:=limite + i*tsem;r.right:=r.left+tsem;
       r.top:=2;r.bottom:=header;
       s:=cdays[DayOfTheWeek(tmpdate)];

       {$IFDEF WINDOWS}
       plan.Buffer.Textout(r,DT_CENTER,s);
       {$else}
       plan.Buffer.Textout(100, 2,s);
       {$ENDIF}
       r.top:=20;
       s:=datetostr(tmpdate);
       {$IFDEF WINDOWS}
       plan.Buffer.Textout(r,DT_CENTER,s);
       {$ENDIF}
       tmpdate:=incday(tmpdate,1);
     end;


     plan.Buffer.Line(0,header,w,header,color32(0,0,128,255),true);

     l:=1;
     while (lines[l].sy_id>0) and (l<255) do
     begin
       plan.Buffer.Line(0,header+hline*l,w,header+hline*l,color32(0,0,128,255),true);
       r.left:=10;r.right:=limite;
       r.bottom:=header+hline*l;r.top:=r.bottom-hline;
       plan.Buffer.Textout(r,DT_LEFT,lines[l].caption);
       for c:=0 to 6 do
       begin
         if assigned(lines[l].colums[c + 1]) then
         begin
               plan.Buffer.Textout(limite + c*tsem,header+hline*(l - 1)+10,lines[l].colums[c + 1].gethstart);
               plan.Buffer.Textout(limite + c*tsem,header+hline*(l - 1)+30,lines[l].colums[c + 1].gethend);
         end;
       end;
       inc(l);
     end;

end;

function TFr_planning.getcode : shortstring;

var code : char;

begin
//   result:='F'+copy(table.table,1,3)+'|'+intToHex(id,4);
  code:='W'; // W=Worker, C=Customer
  result:='PLN'+code;
  result:=result+'|'+intToHex(id,4);
end;

function TFr_planning.getinfos : shortstring;
begin
  result:='W'+'-'; // W=Worker, C=Customer
  case mode of
       pm_week : result:=result+'WT';
       pm_month : result:=result+'MT';
       pm_graphweek : result:=result+'WG';
       pm_graphmonth : result:=result+'MG';
  end;
  result:=result+'-';
  result:=result+FormatDateTime('YYYYMMDD',startdate);

end;



procedure TFr_planning.remplir_planning;

var  inter : Tintervention;
     enddate : tdatetime;
     l, c : integer;
     old : longint;
     query : tdataset;
     sql,s : string;

begin
   if assigned(col) then freeAndNil(col);
   query:=nil;
   old:=-1;
   reset_planning;
   ed_date.Caption:=datetostr(startdate);
   if id>0 then
   begin
     enddate:=EndOfTheWeek(startdate);
     col:=Planning.loadW(id,startdate, enddate);
     if assigned(col) then
     begin
       for inter in col do
       begin
         for l:=1 to 255 do
         begin
           if lines[l].sy_id<0 then
           begin
             lines[l].sy_id:=inter.c_id;
             if old<>inter.c_id then
             begin
               sql:='SELECT SY_CODE,SY_LASTNAME,SY_FIRSTNAME FROM CUSTOMER WHERE SY_ID=%i';
               sql:=sql.Replace('%i',inttostr(inter.c_id));
               Maindata.readDataSet(query,sql,true);
               if query.RecordCount>0 then
               begin
                    s:=query.Fields[0].AsString;
                    s:=s+' '+query.Fields[1].AsString;
                    s:=s+' '+query.Fields[2].AsString;
               end;
               query.Close;
               old:=inter.c_id;
             end;
           end;
           if (lines[l].sy_id=inter.c_id) and (lines[l].colums[inter.col_index]=nil) then
           begin
             lines[l].colums[inter.col_index]:=inter;
             lines[l].caption:=s;
             break;
           end;
         end;
       end;
     end;
   end;
   //planPaintBuffer(self);
   plan.ForceFullInvalidate;
end;

procedure TFr_planning.reset_planning;

var i,j : integer;

begin
  for i:=1 to 255 do
  begin
       lines[i].sy_id:=-1;
       lines[i].caption:='';
       for j:=1 to 31 do
       begin
            lines[i].colums[j]:=nil;
       end;
  end;
end;

procedure Tfr_planning.setid(p_id : longint);

var Query : tdataset;
    sql : string;

begin
  if id<>p_id then
  begin
    Query:=nil;
    id:=p_id;
    sql:=Maindata.getQuery('<Q0014>','SELECT SY_CODE, SY_FIRSTNAME, SY_LASTNAME FROM WORKER WHERE SY_ID=%id');
    sql:=sql.replace('%id',inttostr(id));
    MainData.readDataSet(Query,sql,true);
    if Query.RecordCount>0 then
    begin
         Ed_code.Text:=Query.Fields[0].AsString;
         ed_name.Caption:=Query.Fields[2].AsString+' '+Query.Fields[1].AsString;;
    end;
    Query.close;
    Query.Free;
    if parent is TWincontrol then
    begin
         TWincontrol(parent).Caption := Caption;
    end;
  end;
end;

destructor TFr_planning.Destroy;

begin
  inherited;
  if assigned(col) then freeAndNil(col);
end;

end.


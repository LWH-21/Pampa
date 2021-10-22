unit Fru_planning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Buttons, ExtCtrls, GR32,
  LCLType,
  DB,DataAccess,
  GR32_Image, dw_f, DWorker, Dateutils, FSearch, DPlanning;

type

  TPlanMode = (pm_week, pm_month, pm_graphweek, pm_graphmonth);

  { TFr_planning }

  TFr_planning = class(TW_F)

    Edit1: TEdit;
    Ed_date: TEdit;
    Ed_name: TEdit;
    plan: TPaintBox32;
    ScrollBar1: TScrollBar;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;


    procedure FrameResize(Sender: TObject);
    procedure planPaintBuffer(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);

  private
    mode : TPlanMode;
    s_id : longint;
    startdate : tdatetime;
    col : TInterventions;
    lines : array[1..255] of record
                                  sy_id : longint;
                                  caption:shortstring;
                                  colums : array[1..31] of TIntervention;
                            end;


  public
    function CanClose : boolean;override;
    procedure init(Data: PtrInt); override;

    procedure draw_week;
    procedure remplir_planning;
    procedure reset_planning;
    destructor Destroy;override;
  end;

implementation

{$R *.lfm}

uses Main;

procedure TFr_planning.init(Data: PtrInt);

begin
  mode:=pm_week;
  Caption := 'Planning';
  startdate:=Today();
  startdate:=StartOfTheWeek(startdate);
  ed_date.Caption:=datetostr(startdate);
  s_id:=-1;
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
begin

end;

procedure TFr_planning.SpeedButton1Click(Sender: TObject);

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
  s_id:=num;
  ed_name.Caption:=c+' '+l+' '+f;
  start:=Today();
  start:=StartOfTheWeek(start);
  startdate:=start;

  remplir_planning;


end;

procedure TFr_planning.SpeedButton2Click(Sender: TObject);
begin
  startdate:=incday(startdate,-7);
  remplir_planning;
end;

procedure TFr_planning.SpeedButton3Click(Sender: TObject);
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
     header:=80;
     hline:=60;

     limite:=w div 4;

     tsem := (w - limite) div 7;

     plan.Buffer.FillRect(1,1,w-1,header-1,color32(255,255,255));
     plan.Buffer.FrameRectS(0,1,w,h-1,color32(255,0,0,0));
     plan.Buffer.Line(limite,1,limite,h - 1,color32(0,0,128,255),true);

     tmpdate:=startdate;
     for i:=0 to 6 do
     begin
       if i>0 then plan.Buffer.Line(limite + i*tsem,1,limite+ i*tsem,h - 1,color32(0,0,128,255),true);
       r.Left:=limite + i*tsem;r.right:=r.left+tsem;
       r.top:=2;r.bottom:=header;
       s:=cdays[DayOfTheWeek(tmpdate)];
       plan.Buffer.Textout(r,DT_CENTER,s);
       r.top:=20;
       s:=datetostr(tmpdate);
       plan.Buffer.Textout(r,DT_CENTER,s);
       tmpdate:=incday(tmpdate,1);
     end;
     header:=50;
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

function TFr_planning.CanClose : boolean;

begin

     result:=true;
end;

procedure TFr_planning.remplir_planning;

var  inter : Tintervention;
     enddate : tdatetime;
     l, c : integer;
     old : longint;
     query : tdataset;
     sql,s : string;

begin
   if assigned(col) then col.free;
   query:=nil;
   old:=-1;
   reset_planning;
   ed_date.Caption:=datetostr(startdate);
   if s_id>0 then
   begin
     enddate:=EndOfTheWeek(startdate);
     col:=Planning.loadW(s_id,startdate, enddate);
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

destructor TFr_planning.Destroy;

begin
  inherited;
  if assigned(col) then freeAndNil(col);
end;

end.


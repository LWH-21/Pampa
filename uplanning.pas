unit UPlanning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls,LMessages, StdCtrls, EditBtn,  Dialogs,
  dateutils, Clipbrd,
  DB,DataAccess,DA_table,
  DPlanning,UPlanning_enter,RessourcesStrings,
  Graphics, ComCtrls, Menus,BGRABitmap, BGRABitmapTypes, Types;

type

  TLWPaintBox = class(TPaintBox)

    protected

    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;

  end;

  { TGPlanning }

  Planning_kind=(pl_week,pl_2weeks, pl_month, pl_graphic, pl_text, pl_edit, pl_consult, pl_worker, pl_customer);
  TPlanning_kind= set of Planning_kind;

  TGPlanning = class(TFrame)
      Label_start: TLabel;
      Label_end: TLabel;
      MReset: TMenuItem;
      MSep01: TMenuItem;
      MWorker: TMenuItem;
      Mexcept: TMenuItem;
      MCustomer: TMenuItem;
      SB_planning_time: TScrollBar;
      Start_planning: TDateEdit;
      M2weeks: TMenuItem;
      Mchange: TMenuItem;
      MCopy: TMenuItem;
      MDel: TMenuItem;
      Minsert: TMenuItem;
      MMonth: TMenuItem;
      MPaste: TMenuItem;
      MWeek: TMenuItem;
      Mtexte: TMenuItem;
      MPdf: TMenuItem;
      Mexcel: TMenuItem;
      PopM_planning: TPopupMenu;
      PopM_export: TPopupMenu;
      PopM_freq: TPopupMenu;
      End_planning: TDateEdit;
      TB_date: TDateEdit;
      PToolbar: TToolBar;
      TB_prev: TToolButton;
      TB_next: TToolButton;
      TB_graph: TToolButton;
      TB_export: TToolButton;
      ToolButton1: TToolButton;
      ToolButton2: TToolButton;
      TB_freq: TToolButton;
      TB_refresh: TToolButton;
      TB_zoom: TTrackBar;
      procedure End_planningChange(Sender: TObject);
      procedure FrameClick(Sender: TObject);
      procedure M2weeksClick(Sender: TObject);
      procedure MchangeClick(Sender: TObject);
      procedure MCustomerClick(Sender: TObject);
      procedure MDelClick(Sender: TObject);
      procedure MPlanningClick(Sender: TObject);
      procedure MexcelClick(Sender: TObject);
      procedure MResetClick(Sender: TObject);
      procedure MtexteClick(Sender: TObject);
      procedure MWeekClick(Sender: TObject);
      procedure MMonthClick(Sender: TObject);
      procedure MWorkerClick(Sender: TObject);
      procedure PB_planningMouseDown(Sender: TObject; Button: TMouseButton;
        Shift: TShiftState; X, Y: Integer);
      procedure PB_planningMouseWheel(Sender: TObject; Shift: TShiftState;
        WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
      procedure PopM_planningPopup(Sender: TObject);
      procedure SB_planningChange(Sender: TObject);
      procedure SB_planning_timeChange(Sender: TObject);
      procedure Start_planningChange(Sender: TObject);
      procedure TB_dateChange(Sender: TObject);
      procedure TB_exportClick(Sender: TObject);
      procedure TB_graphClick(Sender: TObject);
      procedure TB_nextClick(Sender: TObject);
      procedure TB_prevClick(Sender: TObject);
      procedure TB_refreshClick(Sender: TObject);
      procedure TB_zoomChange(Sender: TObject);

    private

    old_start_date : tdatetime;
    old_end_date   : tdatetime;
    old_crc : cardinal;

    id : longint;
    colplan : TInterventions;
    start : tdatetime;
    dateref : tdatetime;
    update_scrollbar : boolean;
    FKind: TPlanning_kind;
    FColNumber : integer;
    w, h : integer;
    mat : TLPlanning;
    selection : tpoint;
    margin, hline, header, colwidth : integer;
    cache : TBGRABitmap;
    PB_planning :  TLWPaintBox;
    EnterPlanning: TFPlanning_enter;

    procedure draw_frame(bmp : TBGRABitmap);
    procedure draw_header(bmp : TBGRABitmap);
    procedure draw_header_week(bmp : TBGRABitmap);
    procedure draw_header_2weeks(bmp : TBGRABitmap);
    procedure draw_header_month(bmp : TBGRABitmap);
    procedure draw_text(bmp : TBGRABitmap);
    function getSelInter() : Tintervention;
    procedure redraw_dest(c : TBGRABitmap; r : trect);
    procedure prepare_graphics();
    procedure prepare_text();
    procedure draw_graphics(bmp : TBGRABitmap);


  published
    SB_planning: TScrollBar;
    procedure SetKind(k : TPlanning_kind);
    property Mode : TPlanning_kind READ FKind WRITE SetKind;
    procedure FrameResize(Sender: TObject);
    procedure PB_planningPaint(Sender: TObject);
    procedure TimeScroll(var Msg: TLMessage); message LM_SCROLL;


  public
    constructor create(aowner: TComponent);override;
    procedure Delete(num : longint; days : shortstring; hs,he : word; inter : Tintervention);
    function getHint(pt : Tpoint) : string;
    function getCurrent(m : char) : longint;
    function getInfos : string;
    function getStartDate : tdatetime;
    function ismodified : boolean;
    procedure load(lid : longint; startdate : tdatetime; m : char = '_'; period : char = '_'; display : char='_');
    procedure load(col :  TInterventions;startdate,enddate : tdatetime);
    procedure load(planning_def : string;wid,pid : longint; s,e : tdatetime);
    procedure load(pl_id : longint);

    procedure modify(num : longint; days : shortstring; hs,he : word; inter : Tintervention);
    procedure reload;
    procedure refresh;
    procedure refreshPlanningEnter;
    function save : boolean;
    procedure setDateref(d : tdatetime);
    procedure setEditMode;
    destructor destroy; override;
  end;

implementation

uses Main, PL_export, UF_planning_01;

{$R *.lfm}

{ TGPlanning }

procedure TLWPaintBox.CMHintShow(var Message: TCMHintShow);

var aparent : TGPlanning;
    s : string;
begin
   inherited;
   if (parent is TGPlanning) then
   begin
     aparent:=parent as TGPlanning;
     s:=aparent.getHint(TCMHintShow(Message).HintInfo^.CursorPos);
     TCMHintShow(Message).HintInfo^.HintStr:=s;
   end;
end;

constructor TGPlanning.create(aowner: TComponent);

begin
   inherited create(aOwner);
   PB_planning:=TLWPaintBox.create(self);
   PB_planning.Parent:=self;
   PB_planning.onMouseDown:=@PB_planningMouseDown;
   PB_planning.OnMouseWheel:=@PB_planningMouseWheel;

   PB_planning.OnPaint:=@PB_planningPaint;
   PB_planning.ShowHint:=true;
   FKind:=[pl_week, pl_text, pl_consult, pl_worker];
   start:=StartOfTheWeek(Today());
   TB_date.Date:=start;
   margin:=SB_planning.Width div 4;
   header:=40;
   hline:=30;
   selection.x:=-1;
   selection.y:=-1;
   dateref := start;
   update_scrollbar:=true;
   start_planning.visible:=false;
   end_planning.visible:=false;
   Label_start.visible:=false;
   label_end.visible:=false;
   SB_planning_time.Min:=-50;SB_planning_time.Max:=50;SB_planning_time.Position:=0;
   setKind(Fkind);
end;

procedure TGPlanning.delete(num : longint; days : shortstring; hs,he : word; inter : Tintervention);

var col,line : integer;
    oldinter : Tintervention;

begin
     assert(length(days)=7,'Invalid parameters : days = '+days);
     assert(num>0,'Invalid parameters : num='+inttostr(num));
     assert(he>hs,'Invalid parameters hs='+inttostr(hs)+' he='+inttostr(he));
     assert(assigned(mat),'Mat not assigned');

     for line:=0 to mat.linescount-1 do
     begin
         for col:=0 to mat.colscount-1 do
         begin
              if assigned(mat.lines[line].colums) then
              begin
                  oldinter:=mat.lines[line].colums[col];
                  if assigned(oldinter) then
                  begin
                      if (oldinter.c_id=num) and (oldinter.h_start=hs) and (oldinter.h_end=he) then
                      begin
                          if days[oldinter.week_day]<>'_' then
                          begin
                           freeAndNil(mat.lines[line].colums[col]);
                           mat.setModified(true);
                          end;
                      end;
                  end;
              end;
         end;
     end;

     mat.normalize;
     refresh;
end;

{ Get the Hint in relation with the mouse position }
function TGPlanning.getHint(pt : Tpoint) : string;(* ************************ *)

var ny, lh : integer;
    inter : Tintervention;
begin
   result:='';
   if assigned(mat) then
   begin
         if (pt.x>margin) and (pt.y>0) and (assigned(cache)) then
         begin
              lh := h - header;
              ny:=round((SB_planning.position / SB_planning.max)*(cache.height - lh));
              ny:=ny+pt.y-header;
              if ((ny>0) and (ny<cache.height)) then
              begin
                assert(ny <= cache.height,'Error calculing coordinates y: '+inttostr(pt.y));
                inter:=mat.getInterAt(pt.x,ny);
                if assigned(inter) then
                begin
                     result:=inter.getHint;
                end;
              end;
         end;
     end;
end;

function TGPlanning.getCurrent(m : char) : longint;

begin
   assert(false,'not implemented');
   result:=-1;
end;

function TGPlanning.getInfos : string;

begin
   if pl_customer in FKind then result:='C' else result:='W';
   result:=result+'-';
   if pl_month in Fkind then result:=result+'M' else
   if pl_2weeks in Fkind then result:=result+'2' else
   result:=result+'W';
   if pl_graphic in Fkind then result:=result+'G' else
   result:=result+'T';
   result:=result+'-';
   result:=result+FormatDateTime('YYYYMMDD',getStartDate);
end;

function TGPlanning.getStartDate : tdatetime;

begin
   result:=self.start;
   if assigned(self.mat) then result:=mat.start_date;
end;

function TGPlanning.ismodified : boolean;

begin
   result:=false;
   if assigned(self.mat) then result:=mat.ismodified();
end;

procedure TGPlanning.PB_planningMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

var c, l,lh,ny,ox,oy  : integer;
    inter : TIntervention;
    selchanged : boolean;
    s : string;

begin
   assert(colwidth>0,'Col width equals to 0');
   assert(hline>0,'Line height equals to 0');
   assert(SB_planning.max>0,'Sb_planning.max = '+inttostr(SB_planning.max));
   assert(hline>0,'Hline = '+inttostr(hline));
   assert(colwidth>0,'Colwidth = '+inttostr(colwidth));
   if assigned(EnterPlanning) then
   begin
     EnterPlanning.visible:=false;
   end;

   s:='';
   ox:=selection.x;oy:=selection.y;
   selection.x:=-1;selection.y:=-1;
   if (selection.Y<0) and (pl_text in FKind) and (y>0) then
   begin
     lh := h - header;
     l:=round((SB_planning.position / SB_planning.max)*(cache.height - lh));
     oy:=(y - header + l) div self.hline + 1;
     if (x>margin) then
     begin
          ox:=(x-margin) div colwidth + 1 ;
          selection.x:=ox;
     end else
     begin
       selection.x:=0;
     end;
     selection.y:=oy;
     if (ox<>selection.x) or (oy<>selection.y) then selchanged:=true;
   end;


   if assigned(mat) then
   begin
     if (x>margin) and (y>0) and (assigned(cache)) then
     begin
          mat.deselectLines;
          lh := h - header;
          ny:=round((SB_planning.position / SB_planning.max)*(cache.height - lh));
          ny:=ny+y-header;
          if ((ny>0) and (ny<cache.height)) then
          begin
               assert(ny <= cache.height,'1 Error calculing coordinates y: '+inttostr(y));
               if assigned(mat) then inter:=mat.getInterAt(x,ny);
               if assigned(inter) then
               begin
                    s:=inter.getHint;
                    if not inter.selected then
                    begin
                        inter.selected:=true;
                        selchanged:=true;
                    end;
               end;
          end;
     end else
     if (y>0) and assigned(cache) then
     begin
       lh := h - header;
       ny:=round((SB_planning.position / SB_planning.max)*(cache.height - lh));
       ny:=ny+y-header;
       if ((ny>0) and (ny<cache.height)) then
       begin
            assert(ny <= cache.height,'2 Error calculing coordinates y: '+inttostr(y));
            if assigned(mat) then selchanged:= mat.SelLineAt(x,ny);
       end;
     end;
     for l:=0 to mat.linescount -1 do
     begin
         for c:=0 to mat.colscount-1 do
         begin
              if assigned(mat.lines[l].colums[c]) then
              begin
                  if (mat.lines[l].colums[c].selected) then
                  begin
                      if (not assigned(inter)) or (inter<>mat.lines[l].colums[c]) then
                      begin
                           mat.lines[l].colums[c].selected:=false;
                           selchanged:=true;
                      end;
                  end;
              end;
         end;
     end;
   end;

   if selchanged then
   begin
        refresh();
        MainForm.setMicroHelp(s);
   end;
end;

procedure TGPlanning.MexcelClick(Sender: TObject);
begin

end;

procedure TGPlanning.MResetClick(Sender: TObject);


begin
    if not assigned(mat) then exit;
    mat.reset();
    refresh();
end;

procedure TGPlanning.MtexteClick(Sender: TObject);
begin
   export_planning(mat,FKind);
end;

procedure TGPlanning.M2weeksClick(Sender: TObject);

var k : TPlanning_kind;

begin
   k:=FKind;
   k:=k - [pl_week];
   k:=k - [pl_month];
   k:=k + [pl_2weeks];
   SetKind(k);
   reload;
end;

procedure TGPlanning.End_planningChange(Sender: TObject);
begin
  if assigned(mat) then mat.end_date:=End_planning.Date;
end;

procedure TGPlanning.FrameClick(Sender: TObject);
begin

end;

procedure TGPlanning.MchangeClick(Sender: TObject);

var inter : TIntervention;
    r : Trect;
    uid,plid : longint;
    f: TF_planning_01;

begin
   if not assigned(mat) then exit;
   inter:=getSelInter();
//   if not assigned(inter) then exit;


   if (pl_edit in Fkind)  then
   begin
     if (pl_text in FKind) then
     begin
         refreshPlanningEnter;
         EnterPlanning.setInter(selection.Y, selection.X,inter);
         if assigned(inter) then
         begin
              r:=inter.getBounds;
         end else
         begin
             r.top:=header+selection.y*hline;
             r.right:=margin+selection.x*colwidth;
             r.left:=r.right - colwidth;
         end;
         EnterPlanning.Top :=r.Top;
         EnterPlanning.Left:=r.Right;
         if (EnterPlanning.left+EnterPlanning.Width)>(PB_planning.Width) then
         begin
           EnterPlanning.left:=r.Left - EnterPlanning.Width;
         end;
         if ((EnterPlanning.top+Enterplanning.Height) > self.height) then
         begin
           EnterPlanning.top:=r.top-Enterplanning.Height;
         end;
     end;
   end else
   begin
       uid := -1;
       plid:=-1;
       if (pl_worker in Fkind) then
       begin
         uid:=self.id;
         if uid<0 then uid:=mat.getWorkerId();
       end;
       if assigned(inter) then
       begin
              plid:=inter.planning;
              if (pl_customer in Fkind) then uid:=inter.getWorkerId();
       end;
       if uid >= 0 then
       begin
            f := TF_planning_01.Create(MainForm);
            f.init(uid,plid);
            f.DefaultMonitor := dmActiveForm;
            f.ShowModal;
            self.reload;
       end;
   end;
end;

procedure TGPlanning.MCustomerClick(Sender: TObject);

var l : integer;
    uid : longint;

begin
     uid:=-1;
     if not (pl_worker in FKind) then exit;
     if pl_graphic in Fkind then
     begin
          for l:=0 to mat.linescount-1 do
          begin
              if mat.lines[l].selected then
              begin
                uid:=mat.lines[l].sy_id;
                break;
              end;
          end;
     end;
     if pl_text in Fkind then
     begin
          l:=selection.y-1;
          if (l<=length(mat.lines)) and (mat.lines[l].sy_id>0) then uid:=mat.lines[l].sy_id;
     end;
    if uid>0 then
    begin
      FKind:=FKind - [pl_worker]+[pl_customer];
      setKind(Fkind);
      load( uid,self.start);
      if assigned(parent) and ((parent is TFrame) or (parent is TForm)) then
         parent.Perform(LM_PLANNING_DEST_CHANGE, 2,uid );
    end;
end;

procedure TGPlanning.MDelClick(Sender: TObject);

var inter : Tintervention;

begin
    if not assigned(mat) then exit;
    inter:=getSelInter();
    if not assigned(inter) then exit;
    mat.delete(inter);
    refresh();
end;

procedure TGPlanning.MPlanningClick(Sender: TObject);
begin

end;

procedure TGPlanning.MWeekClick(Sender: TObject);

var k : TPlanning_kind;

begin
   k:=FKind;
   k:=k - [pl_2weeks];
   k:=k - [pl_month];
   k:=k + [pl_week];
   SetKind(k);
   reload;
end;

procedure TGPlanning.MMonthClick(Sender: TObject);

var k : TPlanning_kind;

begin
   k:=FKind;
   k:=k - [pl_2weeks];
   k:=k - [pl_week];
   k:=k + [pl_month];
   SetKind(k);
   reload;
end;

procedure TGPlanning.MWorkerClick(Sender: TObject);

var l : integer;
    uid : longint;

begin
    uid:=-1;
    if not (pl_customer in FKind) then exit;
    if not (assigned(mat)) then exit;
    if pl_graphic in Fkind then
    begin
         for l:=0 to mat.linescount-1 do
         begin
             if mat.lines[l].selected then
             begin
               uid:=mat.lines[l].sy_id;
               break;
             end;
         end;
    end;
    if pl_text in Fkind then
    begin
         l:=selection.y-1;
         if (l<=length(mat.lines)) and (mat.lines[l].sy_id>0) then uid:=mat.lines[l].sy_id;
    end;
   if uid>0 then
   begin
     FKind:=FKind + [pl_worker]-[pl_customer];
     setKind(Fkind);
     load( uid,self.start);
     if assigned(parent) and ((parent is TFrame) or (parent is TForm)) then
        parent.Perform(LM_PLANNING_DEST_CHANGE, 1,uid );
   end;
end;


procedure TGPlanning.PB_planningMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);


begin
     if SB_planning.enabled then
     begin
       if wheeldelta>0 then
       begin
            if SB_planning.Position>SB_planning.Min then
            begin
                SB_planning.Position:=SB_planning.Position - 1;
            end;
       end else
       if wheeldelta<0 then
       begin
            if SB_planning.Position<SB_planning.Max then
            begin
                SB_planning.Position:=SB_planning.Position + 1;
            end;
       end;
     end;
end;

procedure TGPlanning.PopM_planningPopup(Sender: TObject);

var l : integer;
    c : integer;

begin
   Mchange.visible:=true;
   Mchange.Caption:='Saisie du planning';
   if  self.id<0 then Mchange.visible:=false;
   Mdel.visible:=false;
   MInsert.visible:=false;
   MCopy.visible:=false;
   MPaste.visible:=false;
   MExcept.visible:=false;
   MCustomer.visible:=false;
   MWorker.visible:=false;
   if assigned(mat) then
   begin
     l:=selection.y-1;
     if (pl_edit in Fkind)  then
     begin
          if (l>=0) and (selection.X>0) and (l<high(mat.lines)) then
          begin
             Mchange.visible:=true;
             if not assigned(mat.lines[l].colums[selection.X-1]) then
             begin
                Mchange.Caption:='Ajouter une intervention';
                Mdel.visible:=false;
             end else
             begin
                 Mchange.caption:='Modifier';
                 Mdel.visible:=true;
             end;
          end;
          MInsert.visible:=true;
          MCopy.visible:=true;
          MPaste.visible:=true;
     end;
     if  (pl_consult in FKind) then
     begin
       if  (pl_text in FKind) then
       begin
         if (selection.x=0) then
         begin
           if (l<length(mat.lines)) and (mat.lines[l].sy_id>=0) then
           begin
                    if (pl_worker in FKind) then MCustomer.visible:=true
                    else Mworker.visible:=true;
           end;
         end else
         begin
              MExcept.visible:=true;
              if (l<length(mat.lines)) and (mat.lines[l].sy_id>=0) and assigned(mat.lines[l].colums[selection.x-1]) then Mchange.visible:=true;
         end;
       end else
       if (pl_graphic in Fkind) then
       begin
              for l:=0 to mat.linescount -1 do
              begin
                  if mat.lines[l].selected then
                  begin
                       if (pl_worker in FKind) then MCustomer.visible:=true
                       else Mworker.visible:=true;
                       break;
                  end;
                  for c:=0 to mat.colscount-1 do
                  begin
                       if assigned(mat.lines[l].colums[c]) then
                       begin
                           if (mat.lines[l].colums[c].selected) then
                           begin
                                if c>0 then
                                begin
                                  Mchange.visible:=true;
                                  MExcept.visible:=true;
                                  break;
                                end else
                                begin
                                     if (pl_worker in FKind) then MCustomer.visible:=true
                                     else Mworker.visible:=true;
                                end;
                           end;
                       end;
                  end;
              end;
       end;
     end;
   end;
end;

procedure TGPlanning.SB_planningChange(Sender: TObject);
begin
   PB_planning.Refresh;
end;

procedure TGPlanning.SB_planning_timeChange(Sender: TObject);

var p : integer;

begin
     p := SB_planning_time.Position;
     if p<>0 then
     begin
       Application.ProcessMessages;
       Perform(LM_SCROLL, P, 0);
     end;
end;

procedure TGPlanning.Start_planningChange(Sender: TObject);
begin
  if assigned(mat) then mat.start_date:=Start_planning.Date;
end;

procedure TGPlanning.TB_dateChange(Sender: TObject);

var d : tdatetime;

begin
     d:=TB_date.Date;
     if pl_week in FKind then
     begin
          d:=StartOfTheWeek(d);
     end;
     if  CompareDate(start,d) <> 0 then
     begin
         load(id,d);
     end;
     if update_scrollbar then
     begin
         setDateRef(start);
     end;
end;

procedure TGPlanning.TB_exportClick(Sender: TObject);
begin
   export_planning(mat,FKind);
end;

procedure TGPlanning.TB_graphClick(Sender: TObject);

var k : TPlanning_kind;

begin
   k:=FKind;
   if  TB_graph.Down then
   begin
        k:=k - [pl_text];
        k:=k + [pl_graphic];
   end else
   begin
     k:=k + [pl_text];
     k:=k - [pl_graphic];
   end;
   SetKind(k);
end;

procedure TGPlanning.TB_nextClick(Sender: TObject);
begin
  if pl_week in FKind then
  begin
       start:=incday(start,7);
       load(id,start);
  end else
  if pl_2weeks in Fkind then
  begin
       start:=incday(start,14);
       load(id,start);
  end else
  if pl_month in Fkind then
  begin
      start:=incday(start,32);
      load(id,start);
  end;
end;

procedure TGPlanning.TB_prevClick(Sender: TObject);
begin
  if pl_week in FKind then
  begin
       start:=incday(start,-7);
       load(id,start);
  end else
  if pl_2weeks in Fkind then
  begin
       start:=incday(start,-14);
       load(id,start);
  end else
  if pl_month in Fkind then
  begin
      start:=incday(start,-20);
      load(id,start);
  end;
end;

procedure TGPlanning.TB_refreshClick(Sender: TObject);
begin
  reload;
end;

procedure TGPlanning.TB_zoomChange(Sender: TObject);
begin
  hline:=  TB_zoom.position;
  if pl_graphic in Fkind then
  begin
       prepare_graphics;
  end else
  if pl_text in FKind then
  begin
       prepare_text;
  end;
  PB_planning.Refresh;
end;

procedure TGPlanning.draw_frame(bmp : TBGRABitmap);

begin
   bmp.RectangleAntialias(0,0,w-1,h,BGRABlack,1,BGRAWhite);
end;

{ Afficher les destinataires du planning }
procedure TGPlanning.redraw_dest(c : TBGRABitmap; r : trect); (* ************ *)

var nb_dest : integer;
    j, nline, carwidth : integer;
    textrect,rect : trect;
    s : string;

begin
  c.FillRect(r,BGRAWhite,dmset,65535);
  c.FontHeight:=14;
  nb_dest:=0;
  for j:=0 to length(mat.libs)-1 do
  begin
    if mat.libs[j].id>0 then inc(nb_dest);
  end;

  if nb_dest<=0 then exit;
  j:=1;
  if nb_dest<12 then
  begin
        j:=2;
        rect.top := 12*hline - (nb_dest div 2)*hline*j;
  end else
  if nb_dest<20 then
  begin
       j:=1;
       rect.top := 12*hline - (nb_dest div 2)*hline;
  end;
  carwidth:=10;

  if rect.Top>r.top then
  begin
    rect.top := r.top+5;
  end else
  if (rect.top -10 + (hline*j)* nb_dest)>r.bottom then
  begin
    rect.top := r.bottom - (hline*j* nb_dest) - 10;
  end;
  rect.left:=5;rect.right:=margin - carwidth - 20;
  for nline:=0 to mat.linescount-1 do
  begin
       if (nline=0) or ( mat.lines[nline].sy_id<>mat.lines[nline-1].sy_id) then
       begin
                  if mat.lines[nline].sy_id>0 then
                  begin
                      rect.bottom:=rect.top + hline*j;
                      s:= mat.libs[mat.lines[nline].index].code+' '+mat.libs[mat.lines[nline].index].caption;
                      cache.RectangleAntialias(rect.left,rect.top+2,rect.right,rect.bottom-2,BGRABlack,1,BGRAWhite);
                      textrect:=rect;
                      mat.lines[nline].bounds:=rect;
                      if mat.lines[nline].selected then
                      begin
                           textrect.Inflate(0,0,-13,0);
                           cache.RectangleAntialias(textrect.left,textrect.Top,textrect.Right,textrect.Bottom,BGRA($21,$73,$46),3);
                      end;
                      textrect:=rect;
                      textrect.Inflate(-5,-5,-10,-5);
                      cache.TextRect(textrect, s,taLeftJustify,tlTop,BGRABlack);

                      textrect:=rect;
                      textrect.Inflate(-(rect.width - 10),-2,0,-2);
                      cache.RectangleAntialias(textrect.left,textrect.Top,textrect.Right,textrect.Bottom,mat.libs[mat.lines[nline].index].color,1,mat.libs[mat.lines[nline].index].color);

                  end;
                 rect.top:=rect.Top+hline*j;
             end;
       end;
end;

procedure TGPlanning.prepare_graphics();

var x : integer;
    i,j,lineheight, carwidth : integer;
    s : string;
    col : tbgrapixel;
    nline, ncol : integer;
    inter : TIntervention;
    h1,h2 : real;
    nb_dest: integer;
    rect : trect;
    TS: TTextStyle;

begin
      i:=hline * 25;
     if i<h then i:=h+hline;
     if not assigned(cache) then
     begin
          cache:=TBGRABitmap.Create(w,i, BGRAWhite);
     end else
     begin
       cache.SetSize(w,i);
       cache.Fill(BGRAWhite);
     end;

     cache.FontHeight:=14;
     cache.fontname:='Helvetica';
     cache.FontStyle:=[];
     cache.FontQuality:=fqFineClearTypeRGB;


     lineheight:=cache.FontPixelMetric.Lineheight;
     lineheight:=lineheight div 2;
     carwidth:=-1;
     TS.Clipping:=true;

     x:=margin;
     cache.DrawLineAntialias(margin,0,margin,cache.height,BGRABlack,2);
     cache.DrawLineAntialias(w - 1,0,w - 1,cache.height,BGRABlack,2);
     for i:=1 to FColNumber - 1 do
     begin
          x:=x+colWidth;
          cache.DrawLineAntialias(x,0,x,cache.height,BGRABlack,1);
     end;

     x:=hline div 4;
     col:=Bgra($e6,$e6,$e6);
     col.alpha:=64;
     for i:=0 to 23 do
     begin
       if i>0 then
       begin
            cache.DrawLineAntialias(margin-10,i*hline,w-2,i*hline,BGRABlack,1);
            s:=format('%0.2d',[i,0]);
            if carwidth<=0 then
            begin
                 carwidth:=cache.TextSize(s).Width;
            end;
            cache.TextOut(margin-carwidth - 10 ,i*hline - lineheight,s,BGRABlack,false);
       end;
       if x>5 then
        begin
             for j:=1 to 3 do
             begin
                  cache.DrawLineAntialias(margin-2,i*hline+(x*j),w-2,i*hline+(x*j),col,1);
             end;
        end;
     end;

     cache.FontHeight:=13;
     if colwidth<120 then cache.FontHeight:=12;
     if colwidth<100 then cache.FontHeight:=11;
     if colwidth<80 then cache.FontHeight:=10;
     if colwidth<60 then cache.FontHeight:=9;

     lineheight:=cache.FontPixelMetric.Lineheight;
     nb_dest:=0;

     if assigned(mat) then
     begin
       for nline:=0 to mat.linescount-1 do
       begin
            if (nline=0) or ( mat.lines[nline].sy_id<>mat.lines[nline-1].sy_id) then
            begin
                 if mat.lines[nline].sy_id>0 then inc(nb_dest);
            end;
            for ncol:=0 to mat.colscount-1 do
            begin
                 if assigned(mat.lines[nline].colums[ncol]) then
                 begin
                      inter:=mat.lines[nline].colums[ncol];
                      h1:=inter.getDecimalHstart;
                      h2:=inter.getDecimalHEnd;

                      rect.left:=margin+(ncol*colwidth);
                      rect.right:=rect.left+colwidth+1;
                      rect.top:= round(h1* hline);
                      rect.bottom:=round(h2* hline)+1;
                      mat.setBounds(nline,ncol,rect);
                      if (inter.width>0) or ( inter.selected) then
                      begin
                        rect.right:=rect.left+colwidth*inter.width+1;
                        col:=mat.libs[mat.lines[nline].index].color;


                        cache.Rectangle(rect,BGRABlack,BGRAWhite,dmset);
                        cache.Rectangle(rect,vgablack,col,dmset,32000);

                        cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,vgablack,2);
                        if  inter.selected  then
                        begin
                             col.Lightness:=round(col.lightness*0.7) ;
                             rect.right:=rect.left+colwidth+1;
                             cache.Rectangle(rect,vgablack,col,dmset,32000);
                             cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                        end;
                        s:= mat.libs[mat.lines[nline].index].code+' '+mat.libs[mat.lines[nline].index].caption;
                        rect.Inflate(-1,-1,-1,-1);
                        if (rect.Height>lineheight) and (inter.width>0) then
                        begin
                          if (col.Lightness<32000) then
                          begin
                             cache.TextRect(rect,rect.left,rect.top,s,ts,BGRAWhite);
                          end else
                          begin
                             cache.TextRect(rect,rect.left,rect.top,s,ts,BGRABlack);
                          end;
                        end;
                      end;
                 end;
            end;
       end;
   end;
end;


procedure TGPlanning.draw_graphics(bmp : TBGRABitmap);

var rect, rect1  : Trect;
    i,lh : integer;

begin
     assert(pl_graphic in Fkind ,'Not in graphic mode');
     assert(assigned(bmp),'Bitmap not assigned');
     if not assigned(cache) then exit;
     if not assigned(bmp) then exit;

     rect.Left:=1;rect.Right:=w-1;
     lh := h - header;
     i:=round((SB_planning.position / SB_planning.max)*(cache.height - lh));

     rect.Top :=i ;

     rect.Bottom:=rect.top+lh;

     rect1:=rect;
     rect1.Right := margin - 25;

     assert(not rect.isEmpty,'Destination rectangle is empty');
     { Redessine les destinataires du planning }
     redraw_dest(cache,rect1);

     bmp.PutImagePart(1,header+1,cache,rect,dmSet);
end;

procedure TGPlanning.draw_header(bmp : TBGRABitmap);

var i,x : integer;
    ts : TTextStyle;
    r : trect;
    s : string;


begin
     bmp.RectangleAntialias(0,0,w-1,header,BGRABlack,1,Bgra($e6,$e6,$e6));
     bmp.DrawLineAntialias(margin,0,margin,h,BGRABlack,2);
     x:=margin;
     ts.Clipping:=true;
     ts.Alignment:=taLeftJustify;

     FColNumber:=7;
     if pl_month in FKind then
     begin
       if assigned(mat) then FColNumber:=DaysInAMonth(YearOf(mat.start_date),MonthOf(mat.start_date))
       else FColNumber:=31;
     end else
     if pl_week in FKind then FColNumber:=7 else
     if pl_2weeks in FKind then FcolNumber:=14;
     colwidth:=(PB_planning.Width - margin) div FColNumber;

     for i:=1 to FColNumber - 1 do
     begin
          x:=x+colWidth;
          bmp.DrawLineAntialias(x,0,x,header,BGRABlack,2);
          bmp.DrawLineAntialias(x,header+1,x,h,BGRABlack,1);
     end;

     if assigned(mat) and not (pl_edit in FKind) then
     begin
       r.left:=5;r.right:=margin - 5;
       r.top:=5;r.bottom:=20;
       bmp.FontHeight:=12;
       bmp.FontName:='Arial';
       bmp.FontQuality:=fqFineAntialiasing;
       bmp.FontStyle:=[fsBold];
       s:=format(rs_period,[datetostr(mat.start_date),datetostr(mat.end_date)]);
       if pl_week in FKind then s:=s+' ('+rs_week+' '+inttostr(weekof(mat.start_date))+')';
       if pl_month in Fkind then s:=s+' ('+rs_month[monthOf(mat.start_date)]+')';
       bmp.TextRect(r,r.left,r.top,s,ts,VGABlue);
     end;
     if pl_week in FKind then draw_header_week(bmp) else
     if pl_2weeks in FKind then draw_header_2weeks(bmp) else
     if pl_month in FKind then  draw_header_month(bmp);
end;

procedure TGPlanning.draw_header_2weeks(bmp : TBGRABitmap);

var d : tdatetime;
    c : integer;
    ts : TTextStyle;
    s : string;
    r : trect;
    lineheight : integer;

begin
     assert(pl_2weeks in FKind,'pl_2weeks not in FKind');
     if assigned(mat) then assert(YearOf(mat.start_date)>1900,'Invalid date');
     bmp.FontHeight:=12;
     bmp.FontName:='Arial';
     bmp.FontQuality:=fqFineAntialiasing;
     bmp.FontStyle:=[fsBold];
     lineheight:=bmp.FontPixelMetric.Lineheight;
     ts.Clipping:=true;
     ts.Alignment:=taCenter;
     if assigned(mat) then
     begin
       d:=mat.start_date;
       for c:=0 to 1 do
       begin
            r.left:=margin+1+c*colwidth*7;r.right:=r.left-1+colwidth*7;
            if (c=1) then r.right:=w - 1;
            r.top:=1;
            r.bottom:=(header div 2);
            bmp.RectangleAntialias(r.left,r.Top,r.right,r.bottom,BGRABlack,2,Bgra($e6,$e6,$e6));
            s:=Format('%.2d',[WeekOfTheYear(d)]);
            bmp.TextRect(r,r.left,r.top,s,ts,VGABlue);
            d:=incday(d,7);
       end;
       r.left:=margin;
       d:=mat.start_date;
       for c:=0 to 14 do
       begin
         r.right:=r.left+colwidth;
         s:=cdays[DayOfTheWeek(d)];
         (*r.top:=0;r.bottom:=lineheight;
         if c=7 then bmp.TextRect(r,r.left,r.top,s,ts,VGABlue)
         else bmp.TextRect(r,r.left,r.top,s,ts,VGARed);*)
         s:=s[1]+' '+FormatDateTime(rs_daymonth,d);
         r.Bottom:=header;
         r.top:=R.bottom-lineheight;
         if (c=6) or (c=13) then bmp.TextRect(r,r.left,r.top,s,ts,VGARed)
         else bmp.TextRect(r,r.left,r.top,s,ts,VGABlue);
         r.Left:=r.right;
         d:=incday(d,1);
       end;
     end;
end;

procedure TGPlanning.draw_header_month(bmp : TBGRABitmap);

var d : tdatetime;
    dow : integer;
    c,n : integer;
    ts : TTextStyle;
    s : string;
    r : trect;
    lineheight : integer;

begin
    assert(pl_month in FKind,'pl_mobth not in FKind');
    if assigned(mat) then assert(YearOf(mat.start_date)>1900,'Invalid date');
    bmp.FontHeight:=10;
    bmp.FontName:='Arial';
    bmp.FontQuality:=fqFineAntialiasing;
    bmp.FontStyle:=[fsBold];
    lineheight:=bmp.FontPixelMetric.Lineheight;
    ts.Clipping:=true;
    ts.Alignment:=taCenter;
    if assigned(mat) then
    begin
      d:=mat.start_date;
    end else
    begin
      d:=today();
    end;

    dow:=dayOfTheWeek(d);
    c:=1;
    r.left:=margin;
    r.top:=1;
    r.bottom:=r.top+lineheight;
    while (c<=FColNumber) do
    begin
         n:=8 - dow;
         r.right:=r.left + colwidth*n;
         if c>=FcolNumber then
         begin
           r.right:=PB_planning.Width;
         end;
         bmp.RectangleAntialias(r.left,r.Top,r.right,r.bottom,BGRABlack,2,Bgra($e6,$e6,$e6));
         if n>1 then
         begin
              s:=Format('%.2d',[WeekOfTheYear(d)]);
              bmp.TextRect(r,r.left,r.top,s,ts,VGABlue);
         end;
         c:=c+n;
         d:=incday(d,n);
         dow:=1;
         r.left:=r.right;
    end;


    r.left:=margin;
    d:=mat.start_date;
    dow:=dayOfTheWeek(d);
    for c:=1 to FColNumber do
    begin
      r.right:=r.left+colwidth;
      (*r.top:=0;r.bottom:=lineheight;
      if c=7 then bmp.TextRect(r,r.left,r.top,s,ts,VGABlue)
      else bmp.TextRect(r,r.left,r.top,s,ts,VGARed);*)
      s:=inttostr(c);
      r.Bottom:=header;
      r.top:=R.bottom-lineheight;
      if (dow=7) then bmp.TextRect(r,r.left,r.top,s,ts,VGARed)   else
      bmp.TextRect(r,r.left,r.top,s,ts,VGABlue);
      inc(dow);
      if dow>7 then dow:=1;
      r.Left:=r.right;
  end;
end;

procedure TGPlanning.draw_header_week(bmp : TBGRABitmap);

var d : tdatetime;
    c : integer;
    ts : TTextStyle;
    s : string;
    r : trect;
    lineheight : integer;

begin
     bmp.FontHeight:=12;
     bmp.FontName:='Arial';
     bmp.FontQuality:=fqFineAntialiasing;
     bmp.FontStyle:=[fsBold];
     lineheight:=bmp.FontPixelMetric.Lineheight;
     ts.Clipping:=true;
     ts.Alignment:=taCenter;
     if assigned(mat) then
       begin
       d:=mat.start_date;
       r.left:=margin;

       for c:=0 to 6 do
       begin
         r.right:=r.left+colwidth;
         s:=cdays[c+1];
         r.top:=0;r.bottom:=lineheight;
         if c<6 then bmp.TextRect(r,r.left,r.top,s,ts,VGABlue)
         else bmp.TextRect(r,r.left,r.top,s,ts,VGARed);
         if not (pl_edit in FKind) then
         begin
              s:=datetostr(d);
              r.Bottom:=header;
              r.top:=R.bottom-lineheight;
              bmp.TextRect(r,r.left,r.top,s,ts,BGRABlack);
         end;
         r.Left:=r.right;
         d:=incday(d,1);
       end;
     end;
end;

procedure TGPlanning.prepare_text();

var nb,x,i : integer;
    linenum : integer;
    rect,r : trect;
    TS: TTextStyle;
    c : integer;
    s : string;
    selrect : Trect;
    bkcolor : TBGRAPixel;
    fontheight : integer;
    marginfontheight : integer;

begin
     if assigned(mat) then nb:=mat.linescount + 5 else nb:=10;
     if nb<10 then nb:=20;
     nb:=hline * nb;
     if nb<h then nb:=h+hline;
     if not assigned(cache) then
     begin
          cache:=TBGRABitmap.Create(w,nb, BGRAWhite);
     end else
     begin
       cache.SetSize(w,nb);
       cache.Fill(BGRAWhite);
     end;

     fontheight:=14;
     marginfontheight:=14;

     cache.FontHeight:=14;
     cache.fontname:='Helvetica';
     cache.FontStyle:=[];
     cache.FontQuality:=fqFineClearTypeRGB;
     if colwidth<120 then FontHeight:=12;
     if colwidth<100 then FontHeight:=11;
     if colwidth<80 then FontHeight:=10;
     if colwidth<60 then FontHeight:=9;

     if margin<220 then  marginfontheight:=13;
     if margin<200 then  marginfontheight:=12;
     if margin<180 then  marginfontheight:=11;


     ts.RightToLeft:=false;
     ts.Clipping:=true;
     cache.FontHeight:=FontHeight;

     x:=margin;
     cache.DrawLineAntialias(margin,0,margin,cache.height,BGRABlack,2);
     cache.DrawLineAntialias(w - 1,0,w - 1,cache.height,BGRABlack,2);
     for i:=1 to FColNumber - 1 do
     begin
          x:=x+colWidth;
          cache.DrawLineAntialias(x,0,x,cache.height,BGRABlack,1);
     end;

     rect.top:=0;
     rect.bottom:=rect.top+hline;
     linenum:=0;
     while (rect.bottom<=h) do
     begin
          rect.bottom:=rect.top+hline;
          if assigned(mat) and (linenum<mat.linescount ) and (mat.lines[linenum].sy_id>0) then
          begin
               bkcolor:=mat.getColor(linenum);
               if ( linenum=mat.linescount-1) or ((linenum<mat.linescount-1) and (mat.lines[linenum].sy_id<>mat.lines[linenum+1].sy_id)) then
               begin
                    cache.DrawLineAntialias(1,rect.bottom,w,rect.bottom,BGRABlack,1);
               end else
               begin
                    cache.DrawLineAntialias(margin+1,rect.bottom,w,rect.bottom,BGRA($d4,$d4,$d4),1);
               end;
               rect.left:=5;rect.right:=margin;

               mat.lines[linenum].bounds:=rect;
               if (linenum=0) or (mat.lines[linenum].sy_id<>mat.lines[linenum-1].sy_id) then
               begin
                    ts.Alignment:=taLeftJustify;
                    c:=mat.lines[linenum].index;
                    s:=mat.libs[c].code+' '+mat.libs[c].caption;
                    cache.fontHeight:=MarginFontHeight;
                    cache.TextRect(rect,rect.left+5,rect.top+5,s,ts,BGRABlack);
               end;

               ts.Alignment:=taCenter;
               cache.fontHeight:=FontHeight;
               for c:=0 to mat.colscount-1 do
               begin
                    rect.Left:=margin + c*colwidth;
                    rect.Width:=colwidth;

                    if assigned(mat.lines[linenum].colums[c ]) then
                    begin
                         s:=mat.lines[linenum].colums[c ].gethstart+' - '+mat.lines[linenum].colums[c].gethend;
                         r:=rect;
                         inflaterect(r,-1,-1);
                         mat.setBounds(linenum,c,rect);
                         cache.fillrect(r,bkcolor,dmset,32000);
                         cache.TextRect(rect,rect.left+5,rect.top+4,s,ts,BGRABlack);
                         if  mat.lines[linenum].colums[c ].selected then
                         begin
                            cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                         end;
                    end;
                    if (linenum=selection.Y -1) and (c=selection.x - 1) then
                    begin
                         selrect:=rect;
                         //cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                    end;
               end;
               if (linenum=selection.Y -1) and (selection.x =0 ) then
               begin
                   rect.Left:=1;
                   rect.right:=margin;
                   selrect:=rect;
                   //cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
               end;

          end else
          begin
            cache.DrawLineAntialias(1,rect.bottom,w,rect.bottom,BGRA($d4,$d4,$d4),1);
            if (linenum=selection.Y - 1) then
            begin
                 if (selection.x>0) then
                 begin
                   rect.Left:=margin + (selection.x - 1)*colwidth;
                   rect.Width:=colwidth;
                   selrect:=rect;
                   //cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                 end else
                 if (selection.x=0) then
                 begin
                   rect.Left:=1;
                   rect.right:=margin;
                   selrect:=rect;
                   //cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                 end;
            end;
          end;

          inc(linenum);
          rect.top := rect.bottom;
     end;
     if (selection.x>=0) and (selection.y>=0) then
     begin
          if (selection.x=0) and assigned(mat) and (selection.y>=0) then
          begin
               i:=selection.y-1;
               while (i<length(mat.lines)-1) and (mat.lines[i].sy_id=mat.lines[i+1].sy_id) do
               begin
                    inc(i);
                    selrect:=mat.lines[i].bounds;
               end;
               while (i>0) and (i<length(mat.lines)-1) and (mat.lines[i].sy_id=mat.lines[i-1].sy_id) do
               begin
                    dec(i);
                    selrect.top:=mat.lines[i].bounds.top;
               end;
          end;
          cache.RectangleAntialias(selrect.Left,selrect.Top,selrect.Right,selrect.bottom,BGRA($21,$73,$46),3);
     end;

end;

procedure TGPlanning.draw_text(bmp : TBGRABitmap);

var rect  : Trect;
    i,lh : integer;

begin
     assert(pl_text in Fkind ,'Not in text mode');
     assert(assigned(bmp),'Bitmap not assigned');
     if not assigned(cache) then exit;
     if not assigned(bmp) then exit;

     rect.Left:=1;rect.Right:=w-1;
     lh := h - header;
     i:=round((SB_planning.position / SB_planning.max)*(cache.height - lh));
     rect.Top :=i;
     rect.Bottom:=rect.top+lh;

     assert(not rect.isEmpty,'Source rectangle is empty');
     bmp.PutImagePart(1,header+1,cache,rect,dmSet);
end;

procedure TGPlanning.FrameResize(Sender: TObject);

begin
     Assert(FColNumber>0,'Colnumber = 0');
     SB_planning.Top:=PToolbar.Height + 1;
     SB_planning.Left:=self.Width - SB_planning.Width - 1;
     SB_planning.height:=Self.Height -  SB_planning.Top - 1;



     PB_planning.Top:=PToolbar.Height + 1;  ;
     PB_planning.left:=0;
     PB_planning.Height:=self.height -  SB_planning.Top - 5 - SB_planning_time.Height;
     PB_planning.Width:=SB_planning.Left - 10;

     SB_planning_time.Left:=3;
     SB_planning_time.Width:=SB_planning.Left - 10;
     SB_planning_time.top:= PB_planning.Top + PB_planning.Height;


     PToolbar.width:=SB_planning.Left;
     margin:=PB_planning.Width div 4;
     w:=PB_planning.Width;
     h:=PB_planning.Height;
     colwidth:=(w - margin) div FColNumber;
     if pl_graphic in Fkind then
     begin
          Sb_planning.min:=0;
          Sb_planning.max:=24;
          Sb_planning.Position:=12;
          margin:=PB_planning.Width div 4;
          prepare_graphics;
     end else
     if pl_text in FKind then
     begin
          prepare_text;
     end;
     if pl_edit in Fkind then
     begin
       TB_date.enabled:=false;
       TB_prev.enabled:=false;
       TB_next.enabled:=false;
       start_planning.visible:=true;
       start_planning.left:=margin - start_planning.width - 5 ;
       start_planning.top:=PB_planning.Top + 2;
       end_planning.visible:=true;
       end_planning.left:=start_planning.left;end_planning.top:=start_planning.top+start_planning.height+1;
       Label_start.visible:=true;
       Label_start.Left:=start_planning.left-50;
       label_end.visible:=true;
       Label_end.left:=label_start.left;
       Label_start.top:=start_planning.top;
       Label_start.BringToFront;
       label_end.Top:=end_planning.top;
       Label_end.BringToFront;
       header:=start_planning.height*2+5;
     end else
     begin
       start_planning.visible:=false;
       end_planning.visible:=false;
       Label_start.visible:=false;
       label_end.visible:=false;
       TB_date.enabled:=true;
       TB_prev.enabled:=true;
       TB_next.enabled:=true;
     end;
     if assigned(EnterPlanning) then
     begin
        EnterPlanning.left:=0;
        EnterPlanning.top:=0;
        EnterPlanning.visible:=false;
     end;
     PB_planning.Refresh;
end;

function TGPlanning.getSelInter() : Tintervention;

var l,c : integer;

begin
     if (not assigned(mat)) then exit;
     result:=nil;
     for l:=0 to mat.linescount -1 do
     begin
         for c:=0 to mat.colscount-1 do
         begin
              if assigned(mat.lines[l].colums[c]) then
              begin
                  if (mat.lines[l].colums[c].selected) then
                  begin
                      result:=mat.lines[l].colums[c];
                      exit;
                  end;
              end;
         end;
     end;
end;

procedure TGPlanning.load(lid : longint; startdate : tdatetime; m : char = '_'; period : char = '_'; display : char='_');

var endDate : tdatetime;
    k : TPlanning_kind;


begin
     id:=lid;
     self.start:=startdate;
     if assigned(colplan) then freeAndNil(colplan);
     endDate:=start;

     k:=[pl_consult];
     if m='_' then
     begin
          if pl_customer in Fkind then k:=k+[pl_customer] else
          k:=k+[pl_worker];
     end else if m='C' then k:=k+[pl_customer] else k:=k+[pl_worker];

     if period='_' then
     begin
          if pl_month in Fkind then k:=k+[pl_month] else
          if pl_2weeks in Fkind then k:=k+[pl_2weeks] else
          k:=k+[pl_week];
     end else if period='2' then k:=k+[pl_2weeks] else
     if period='M' then k:=k+[pl_month] else k:=k+[pl_week];

     if display='_' then
     begin
          if pl_graphic in Fkind then k:=k+[pl_graphic] else
          k:=k+[pl_text];
     end else if display='G' then k:=k+[pl_graphic] else k:=k+[pl_text];

     setKind(k);


     if pl_week in Fkind then
     begin
          assert(not (pl_2weeks in Fkind),'Error type planning');
          assert(not (pl_month in Fkind),'Error type planning');
          start:=StartOfTheWeek(start);
          enddate:=EndOfTheWeek(start);
     end else
     if pl_2weeks in Fkind then
     begin
          assert(not (pl_week  in Fkind),'Error type planning');
          assert(not (pl_month in Fkind),'Error type planning');
          start:=StartOfTheWeek(start);
          enddate:=incday(start,10);
          enddate:=EndOfTheWeek(enddate);
     end;
     if pl_month in Fkind then
     begin
          assert(not (pl_week in Fkind),'Error type planning');
          assert(not (pl_2weeks in Fkind),'Error type planning');
          start:=StartOfTheMonth(start);
          enddate:=EndOfTheMonth(start);
     end;
     if (pl_customer in FKind) then colplan:=Planning.loadC(id,start, enddate)
     else colplan:=Planning.loadW(id,start, enddate);

     load(colplan,start,endDate);
     mat.setModified(false);
end;

procedure TGPlanning.load(col :  TInterventions;startdate,enddate : tdatetime);

begin
     assert((pl_graphic in Fkind) or (pl_text in Fkind),'Not graphic neither text');
     if assigned(mat) then freeandnil(mat);
     selection.x:=-1;
     selection.y:=-1;
     mat:=TLPlanning.create(startdate,enddate);
     assert(assigned(mat),'Mat not assigned');
     if pl_customer in Fkind then mat.setMode('C');
     mat.load(col);
     TB_date.Date:=startdate;
     if pl_graphic in Fkind then prepare_graphics else
     if pl_text in FKind then prepare_text;
     PB_planning.Refresh;
     mat.setModified(false);
end;

procedure TGPlanning.load(planning_def : string;wid,pid : longint;s,e : tdatetime);

begin
     if assigned(mat) then freeandnil(mat);
     selection.x:=-1;
     selection.y:=-1;
     mat:=TLPlanning.create();
     assert(assigned(mat),'Mat not assigned');
     mat.load(planning_def,wid,pid);
     Start_planning.clear;
     Start_planning.Date:=s;
     if yearof(e)<2499 then End_planning.Date:=e else End_planning.Clear;
     if pl_graphic in Fkind then prepare_graphics else
     if pl_text in FKind then prepare_text;
     PB_planning.Refresh;
     mat.setModified(false);
end;


procedure TGPlanning.load(pl_id : longint);

var R : TDataSet;
    wid : longint;
    sql,s : string;
    st,en : tdatetime;

begin
     assert(pl_id>0,'Invalid plannind ID');
     R:=nil;
     if assigned(mat) then freeandnil(mat);
     mat:=TLPlanning.create();
     assert(assigned(mat),'Mat not assigned');
     sql:=MainData.getQuery('QPL03','SELECT  SY_WID, C_ID, SY_START, SY_END, SY_DETAIL FROM PLANNING P INNER JOIN DPLANNING D ON P.SY_ID = D.PL_ID WHERE P.SY_ID=%id');
     assert(length(sql)>1,'Invalid SQL ');
     sql:=sql.Replace('%id',inttostr(pl_id));
     Maindata.readDataSet(R,sql,true);
     IF R.RecordCount>0 then
     begin
       wid:=R.fields[0].asInteger;
       s:=R.Fields[2].AsString;
       st:=IsoStrToDate(s);
       s:=R.Fields[3].AsString;
       en:=IsoStrToDate(s);

       old_start_date:=st;
       old_end_date:=en;

       WHILE NOT R.EOF DO
       BEGIN
            s:=R.Fields[4].AsString;
            mat.load(s,wid,pl_id);
            mat.start_date:=st;
            mat.end_date:=en;
            R.next;
       END;
       Start_planning.clear;
       Start_planning.Date:=st;
       if yearof(en)<2499 then End_planning.Date:=en else End_planning.Clear;
       if pl_graphic in Fkind then prepare_graphics else
       if pl_text in FKind then prepare_text;
     end;
     s:=mat.CreateJson;
     old_crc:=crc32(0,s+DateToStr(old_start_date)+DateToStr(old_end_date));

     PB_planning.Refresh;
     R.close;
     mat.setModified(false);
end;

procedure TGPlanning.TimeScroll(var Msg: TLMessage);


var d : tdatetime;
    p : integer;

begin
     update_scrollbar:=false;
     sb_planning_time.Enabled:=false;
     p:=Round(Msg.wParam.ToSingle);
     d:=dateref;
     if pl_week in Fkind  then
     begin
          d:=incweek(d,p);
          d:=StartOfTheWeek(d);
          if compareDate(d,TB_date.Date)<>0 then
          begin
                 load(id,d);
           end;
     end else
     if pl_2weeks in Fkind then
     begin
       d:=incweek(d,p * 2);
       d:=StartOfTheWeek(d);
       if compareDate(d,TB_date.Date)<>0 then
       begin
            load(id,d);
       end;
     end else
     if pl_month in Fkind then
     begin
       d:=incmonth(d,p);
       d:=StartOfTheMonth(d);
       if compareDate(d,TB_date.Date)<>0 then
       begin
            load(id,d);
       end;
     end;
     sb_planning_time.Enabled:=true;
     update_scrollbar:=true;
end;

procedure TGPlanning.PB_planningPaint(Sender: TObject);

var bmp: TBGRABitmap;

begin
   try
      bmp := TBGRABitmap.Create(w,h, BGRAWhite);
      draw_frame(bmp);
      draw_header(bmp);
      if pl_graphic in Fkind then
      begin
          draw_graphics(bmp);
      end;
      if pl_text in Fkind then
      begin
          draw_text(bmp);
      end;
      bmp.Draw(PB_planning.Canvas, 0, 0, True);
   finally
     bmp.free;
   end;
end;

procedure TGPlanning.modify(num : longint; days : shortstring; hs,he : word; inter : Tintervention);

var i : integer;
    col,line : integer;
    oldinter,newinter : Tintervention;

begin
     assert(length(days)=7,'Invalid parameters : days = '+days);
     assert(num>0,'Invalid parameters : num='+inttostr(num));
     assert(he>hs,'Invalid parameters hs='+inttostr(hs)+' he='+inttostr(he));
     assert(assigned(mat),'Mat not assigned');

     if assigned(inter) then
     begin
       for line:=0 to mat.linescount-1 do
       begin
         for col:=0 to mat.colscount-1 do
         begin
              if assigned(mat.lines[line].colums) then
              begin
                  oldinter:=mat.lines[line].colums[col];
                  if oldinter=inter then
                  begin
                       freeAndNil(mat.lines[line].colums[col]);
                  end;
              end;
         end;
       end;
     end;

     for i:=1 to 7 do
     begin
          if days[i]<>'_' then
          begin
               newinter:=TIntervention.create(i,hs,he,-1,-1,num);
               mat.add_inter(newinter);
          end;
     end;
     mat.setModified(true);
     mat.normalize;
     refresh;
end;

procedure TGPlanning.reload;

begin
     load(id,start);
     mat.setModified(false);
end;

procedure TGPlanning.refresh;

begin
     if pl_graphic in Fkind then
     begin
         prepare_graphics;
     end;
     if pl_text in Fkind then
     begin
         prepare_text;
     end;
    PB_planning.Refresh;
end;

procedure TGPlanning.refreshPlanningEnter;

begin
   if (assigned(mat) and  assigned(enterplanning)) then
   begin
       enterplanning.refresh(mat.libs);
   end;
end;


function TGPlanning.save : boolean;

begin
   mat.start_date:=Start_planning.Date;
   mat.end_date:=End_planning.Date;
   result:=Planning.write(mat,old_start_date, old_end_date, old_crc);
end;

procedure TGPlanning.setEditMode;

begin
   setKind([pl_edit, pl_week, pl_text,pl_worker]);
   if not assigned(EnterPlanning) then
   begin
        EnterPlanning:= TFPlanning_enter.Create(self);
        EnterPlanning.parent:=self;
        EnterPlanning.init(self);
   end;
   if assigned(EnterPlanning) then
   begin
      EnterPlanning.left:=0;
      EnterPlanning.top:=0;
      EnterPlanning.visible:=false;
   end;
end;

procedure TGPlanning.setDateref(d : tdatetime);

begin
   dateref:=d;
   SB_Planning_Time.Position:=0;
end;

procedure TGPlanning.SetKind(k : TPlanning_kind);

begin
   Fkind:=k;
   header:=40;
   if assigned(EnterPlanning) then
   begin
      EnterPlanning.left:=0;
      EnterPlanning.top:=0;
      EnterPlanning.visible:=false;
   end;
   PB_planning.PopupMenu := PopM_planning;
   if  not (pl_customer in FKind) then FKind:=Fkind+[pl_worker];
   if (pl_edit in Fkind) then
   begin
      TB_date.visible:=false;
      TB_prev.visible:=false;
      TB_next.Visible:=false;
      TB_refresh.visible:=false;
      start_planning.visible:=true;
      start_planning.left:=margin - start_planning.width - 5 ;
      start_planning.top:=PB_planning.Top + 2;
      end_planning.visible:=true;
      end_planning.left:=start_planning.left;end_planning.top:=start_planning.top+start_planning.height+1;
      label_start.Top:=start_planning.top;
      Label_start.BringToFront;
      label_end.Top:=end_planning.top;
      Label_end.BringToFront;
      header:=start_planning.height*2+5;
      Mchange.visible:=true;
      Mdel.visible:=true;
      MInsert.visible:=true;
      MCopy.visible:=true;
      MPaste.visible:=true;
      MExcept.visible:=false;
      MCustomer.visible:=false;
      MWorker.visible:=false;
   end else
   begin
        start_planning.visible:=false;
        end_planning.visible:=false;
        TB_refresh.visible:=true;
        Mchange.visible:=false;
        Mdel.visible:=false;
        MInsert.visible:=false;
        MCopy.visible:=false;
        MPaste.visible:=false;
        MExcept.visible:=true;
        MCustomer.visible:=true;
        MWorker.visible:=true;
   end;
   if (pl_consult in FKind) then
   begin
        TB_date.visible:=true;
        TB_prev.visible:=true;
        TB_next.Visible:=true;
   end;
   if pl_graphic in Fkind then
   begin
        Sb_planning.Max:=24;
        Sb_planning.Position:=12;
        TB_graph.Down:=true;
   end else
   begin
     Sb_planning.min:=0;
     Sb_planning.Max:=10;
     Sb_planning.Position:=0;
     TB_graph.Down:=false;
   end;
   FColNumber:=7;
   if pl_week in Fkind then begin
      MWeek.checked:=true;
      FColNumber:=7;
   end else MWeek.checked:=false;
   if pl_2weeks in Fkind then
   begin
        M2weeks.checked:=true;
        FColNumber:=14;
   end
   else M2weeks.checked:=false;
   if pl_month in Fkind then
   begin
        MMonth.checked:=true;
        FColNumber:=31;
   end
   else MMonth.checked:=false;
   FrameResize(self);
end;

destructor TGPlanning.destroy;

begin
   if assigned(EnterPlanning) then FreeAndNil(EnterPlanning);
   if assigned(mat) then freeAndNil(mat);
   if assigned(cache) then freeAndNil(cache);
   if assigned(colplan) then freeAndNil(colplan);
   inherited destroy;
end;

end.


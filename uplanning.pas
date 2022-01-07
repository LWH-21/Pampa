unit UPlanning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls,LMessages, StdCtrls, EditBtn,  Dialogs,
  dateutils, Clipbrd,
  DB,DataAccess,
  DPlanning,UPlanning_enter,RessourcesStrings,
  Graphics, ComCtrls, Menus,BGRABitmap, BGRABitmapTypes, Types;

type

  TLWPaintBox = class(TPaintBox)

    protected

    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;

  end;

  { TGPlanning }

  Planning_kind=(pl_week,pl_2weeks, pl_month, pl_graphic, pl_text, pl_edit, pl_consult);
  TPlanning_kind= set of Planning_kind;

  TGPlanning = class(TFrame)
      Label_start: TLabel;
      Label_end: TLabel;
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
      PopM_upd: TPopupMenu;
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
      procedure M2weeksClick(Sender: TObject);
      procedure MchangeClick(Sender: TObject);
      procedure MexcelClick(Sender: TObject);
      procedure MtexteClick(Sender: TObject);
      procedure MWeekClick(Sender: TObject);
      procedure MMonthClick(Sender: TObject);
      procedure PB_planningMouseDown(Sender: TObject; Button: TMouseButton;
        Shift: TShiftState; X, Y: Integer);
      procedure PB_planningMouseWheel(Sender: TObject; Shift: TShiftState;
        WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
      procedure SB_planningChange(Sender: TObject);
      procedure Start_planningChange(Sender: TObject);
      procedure TB_dateChange(Sender: TObject);
      procedure TB_exportClick(Sender: TObject);
      procedure TB_graphClick(Sender: TObject);
      procedure TB_nextClick(Sender: TObject);
      procedure TB_prevClick(Sender: TObject);
      procedure TB_refreshClick(Sender: TObject);
      procedure TB_zoomChange(Sender: TObject);

    private
    id : longint;
    colplan : TInterventions;
    start : tdatetime;
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
    procedure draw_text(bmp : TBGRABitmap);
    function getSelInter() : Tintervention;
    procedure prepare_graphics();
    procedure prepare_text();
    procedure draw_graphics(bmp : TBGRABitmap);


  published
    SB_planning: TScrollBar;
    procedure SetKind(k : TPlanning_kind);
    property Mode : TPlanning_kind READ FKind WRITE SetKind;
    procedure FrameResize(Sender: TObject);
    procedure PB_planningPaint(Sender: TObject);


  public
    constructor create(aowner: TComponent);override;
    function getHint(pt : Tpoint) : string;
    procedure load(lid : longint; startdate : tdatetime);
    procedure load(col :  TInterventions;startdate,enddate : tdatetime);
    procedure load(planning_def : string;wid,pid : longint; s,e : tdatetime);
    procedure load(pl_id : longint);
    procedure modify(num : longint; days : shortstring; hs,he : word; inter : Tintervention);
    procedure reload;
    procedure refresh;
    procedure refreshPlanningEnter;
    function save() : boolean;
    procedure setEditMode;
    destructor destroy; override;
  end;

implementation

uses Main, PL_export;

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
   FKind:=[pl_week, pl_text, pl_consult];
   start:=StartOfTheWeek(Today());
   TB_date.Date:=start;
   margin:=SB_planning.Width div 4;
   header:=40;
   hline:=30;
   selection.x:=-1;
   selection.y:=-1;
   start_planning.visible:=false;
   end_planning.visible:=false;
   Label_start.visible:=false;
   label_end.visible:=false;
   setKind(Fkind);
end;


function TGPlanning.getHint(pt : Tpoint) : string;

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
   if (selection.Y<0) and (pl_text in FKind) and (x>margin) and (y>0) then
   begin
     lh := h - header;
     l:=round((SB_planning.position / SB_planning.max)*(cache.height - lh));
     ox:=(x-margin) div colwidth + 1 ;
     oy:=(y - header + l) div self.hline + 1;
     selection.x:=ox;
     selection.y:=oy;
     if (ox<>selection.x) or (oy<>selection.y) then selchanged:=true;
     s:='Line '+inttostr(ox)+' column '+inttostr(oy);
   end;


   if assigned(mat) then
   begin
     if (x>margin) and (y>0) and (assigned(cache)) then
     begin
          lh := h - header;
          ny:=round((SB_planning.position / SB_planning.max)*(cache.height - lh));
          ny:=ny+y-header;
          if ((ny>0) and (ny<cache.height)) then
          begin
               assert(ny <= cache.height,'Error calculing coordinates y: '+inttostr(y));
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

procedure TGPlanning.MchangeClick(Sender: TObject);

var inter : TIntervention;
    r : Trect;

begin
   if not assigned(mat) then exit;
   inter:=getSelInter();
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

procedure TGPlanning.SB_planningChange(Sender: TObject);
begin
   PB_planning.Refresh;
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

procedure TGPlanning.prepare_graphics();

var x : integer;
    i,j,lineheight, carwidth : integer;
    s : string;
    col : tbgrapixel;
    nline, ncol : integer;
    inter : TIntervention;
    h1,h2 : real;
    nb_dest: integer;
    rect, textrect : trect;
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
            s:=format('%0.2d:%1.2d',[i,0]);
            if carwidth<=0 then
            begin
                 carwidth:=cache.TextSize(s).Width+10;
            end;
            cache.TextOut(margin-carwidth,i*hline - lineheight,s,BGRABlack,false);
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
                      col:=mat.libs[mat.lines[nline].index].color;
                      cache.Rectangle(rect,BGRABlack,BGRAWhite,dmset);
                      cache.Rectangle(rect,vgablack,col,dmset,32000);
                      if  inter.selected then
                      begin
                            cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                      end;
                      s:= mat.libs[mat.lines[nline].index].code+' '+mat.libs[mat.lines[nline].index].caption;
                      rect.Inflate(-1,-1,-1,-1);
                      if rect.Height>lineheight then
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

       cache.FontHeight:=14;
       rect.top:=0;
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
end;


procedure TGPlanning.draw_graphics(bmp : TBGRABitmap);

var rect  : Trect;
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

     assert(not rect.isEmpty,'Destination rectangle is empty');
     bmp.PutImagePart(1,header+1,cache,rect,dmSet);
end;

procedure TGPlanning.draw_header(bmp : TBGRABitmap);

var i,x : integer;


begin
     bmp.RectangleAntialias(0,0,w-1,header,BGRABlack,1,Bgra($e6,$e6,$e6));
     bmp.DrawLineAntialias(margin,0,margin,h,BGRABlack,2);
     x:=margin;
     for i:=1 to FColNumber - 1 do
     begin
          x:=x+colWidth;
          bmp.DrawLineAntialias(x,0,x,header,BGRABlack,2);
          bmp.DrawLineAntialias(x,header+1,x,h,BGRABlack,1);
     end;
     if pl_week in FKind then draw_header_week(bmp) else
     if pl_2weeks in FKind then draw_header_2weeks(bmp);
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
            bmp.RectangleAntialias(r.left,r.Top,r.right,r.bottom,BGRABlack,1,Bgra($e6,$e6,$e6));
            s:=inttostr(WeekOfTheYear(d));
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
    bkcolor : TBGRAPixel;

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
     cache.FontHeight:=14;
     cache.fontname:='Helvetica';
     cache.FontStyle:=[];
     cache.FontQuality:=fqFineClearTypeRGB;
     if colwidth<120 then cache.FontHeight:=12;
     if colwidth<100 then cache.FontHeight:=11;
     if colwidth<80 then cache.FontHeight:=10;
     if colwidth<60 then cache.FontHeight:=9;
     ts.RightToLeft:=false;
     ts.Clipping:=true;

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

               if (linenum=0) or (mat.lines[linenum].sy_id<>mat.lines[linenum-1].sy_id) then
               begin
                    ts.Alignment:=taLeftJustify;
                    c:=mat.lines[linenum].index;
                    s:=mat.libs[c].code+' '+mat.libs[c].caption;
                    cache.TextRect(rect,rect.left+5,rect.top+5,s,ts,BGRABlack);
               end;

               ts.Alignment:=taCenter;
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
                         cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                    end;
               end;
               if (linenum=selection.Y -1) and (selection.x =0 ) then
               begin
                   rect.Left:=1;
                   rect.right:=margin;
                   cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
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
                   cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                 end else
                 if (selection.x=0) then
                 begin
                   rect.Left:=1;
                   rect.right:=margin;
                   cache.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                 end;
            end;
          end;

          inc(linenum);
          rect.top := rect.bottom;
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

var n : integer;

begin
     Assert(FColNumber>0,'Colnumber = 0');
     SB_planning.Top:=PToolbar.Height + 1;
     SB_planning.Left:=self.Width - SB_planning.Width - 1;
     SB_planning.height:=Self.Height -  SB_planning.Top - 1;
     PB_planning.Top:=PToolbar.Height + 1;  ;
     PB_planning.left:=0;
     PB_planning.Height:=self.height -  SB_planning.Top - 1;
     PB_planning.Width:=SB_planning.Left - 10;
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

procedure TGPlanning.load(lid : longint; startdate : tdatetime);

var endDate : tdatetime;

begin
     id:=lid;
     self.start:=startdate;
     if assigned(colplan) then freeAndNil(colplan);
     endDate:=start;
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
     colplan:=Planning.loadW(id,start, enddate);
     load(colplan,start,endDate);
end;

procedure TGPlanning.load(col :  TInterventions;startdate,enddate : tdatetime);

begin
     assert((pl_graphic in Fkind) or (pl_text in Fkind),'Not graphic neither text');
     if assigned(mat) then freeandnil(mat);
     selection.x:=-1;
     selection.y:=-1;
     mat:=TLPlanning.create(startdate,enddate);
     assert(assigned(mat),'Mat not assigned');
     mat.load(col);
     TB_date.Date:=startdate;
     if pl_graphic in Fkind then prepare_graphics else
     if pl_text in FKind then prepare_text;
     PB_planning.Refresh;
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
     PB_planning.Refresh;
     R.close;
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
     mat.normalize;
     refresh;
end;

procedure TGPlanning.reload;

begin
     load(id,start);
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
   result:=Planning.write(mat);
end;

procedure TGPlanning.setEditMode;

begin
   setKind([pl_edit, pl_week, pl_text]);
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
   if (pl_edit in Fkind) then
   begin
      TB_date.visible:=false;
      TB_prev.visible:=false;
      TB_next.Visible:=false;
      PB_planning.PopupMenu := PopM_upd;
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
   end else
   begin
        start_planning.visible:=false;
        end_planning.visible:=false;
   end;
   if (pl_consult in FKind) then
   begin
        TB_date.visible:=true;
        TB_prev.visible:=true;
        TB_next.Visible:=true;
        PB_planning.PopupMenu := nil;
   end;
   if pl_graphic in Fkind then
   begin
        Sb_planning.Max:=24;
        Sb_planning.Position:=12;
   end else
   begin
     Sb_planning.min:=0;
     Sb_planning.Max:=10;
     Sb_planning.Position:=0;
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


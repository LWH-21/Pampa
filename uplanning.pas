unit UPlanning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, EditBtn, Buttons,  Dialogs,
  dateutils,
  DPlanning,RessourcesStrings,
  Graphics, ComCtrls, Menus,BGRABitmap, BGRABitmapTypes, Types;

type

  { TGPlanning }

  Planning_kind=(pl_week,pl_2weeks, pl_month, pl_graphic, pl_text, pl_edit, pl_consult);
  TPlanning_kind= set of Planning_kind;

  TGPlanning = class(TFrame)
      M2weeks: TMenuItem;
      MMonth: TMenuItem;
      MWeek: TMenuItem;
      Mtexte: TMenuItem;
      MPdf: TMenuItem;
      Mexcel: TMenuItem;
      PopM_export: TPopupMenu;
      PopM_freq: TPopupMenu;
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
      procedure M2weeksClick(Sender: TObject);
      procedure MexcelClick(Sender: TObject);
      procedure MWeekClick(Sender: TObject);
      procedure MMonthClick(Sender: TObject);
      procedure PB_planningMouseDown(Sender: TObject; Button: TMouseButton;
        Shift: TShiftState; X, Y: Integer);
      procedure PB_planningMouseMove(Sender: TObject; Shift: TShiftState; X,
        Y: Integer);
      procedure PB_planningMouseWheel(Sender: TObject; Shift: TShiftState;
        WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
      procedure SB_planningChange(Sender: TObject);
      procedure TB_dateChange(Sender: TObject);
      procedure TB_graphClick(Sender: TObject);
      procedure TB_nextClick(Sender: TObject);
      procedure TB_prevClick(Sender: TObject);
      procedure TB_refreshClick(Sender: TObject);

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

    procedure draw_frame(bmp : TBGRABitmap);
    procedure draw_header(bmp : TBGRABitmap);
    procedure draw_header_week(bmp : TBGRABitmap);
    procedure draw_header_2weeks(bmp : TBGRABitmap);
    procedure draw_text(bmp : TBGRABitmap);

    procedure prepare_graphics();
    procedure prepare_text();
    procedure draw_graphics(bmp : TBGRABitmap);


  published
    PB_planning: TPaintBox;
    SB_planning: TScrollBar;
    procedure SetKind(k : TPlanning_kind);
    property Mode : TPlanning_kind READ FKind WRITE SetKind;
    procedure FrameResize(Sender: TObject);
    procedure PB_planningPaint(Sender: TObject);


  public
    constructor create(aowner: TComponent);override;
    procedure load(lid : longint; startdate : tdatetime);
    procedure load(col :  TInterventions;startdate,enddate : tdatetime);
    procedure reload;
    procedure refresh;
    destructor destroy; override;
  end;

implementation

{$R *.lfm}

{ TGPlanning }




constructor TGPlanning.create(aowner: TComponent);

begin
   inherited create(aOwner);
   FKind:=[pl_week, pl_text, pl_consult];
   start:=StartOfTheWeek(Today());
   TB_date.Date:=start;
   margin:=SB_planning.Width div 4;
   header:=40;
   hline:=30;
   selection.x:=-1;
   selection.y:=-1;
   setKind(Fkind);
end;

procedure TGPlanning.PB_planningMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

var c, l  : integer;

begin
  // margin, hline, header, colwidth

   assert(colwidth>0,'Col width equals to 0');
   assert(hline>0,'Line height equals to 0');

   if x<margin then
   begin
       c:=0;
   end else
   begin
     c:= x - margin;
     c:= (c div colwidth) + 1;
   end;
   if y<header then
   begin
       l:=0;
   end else
   begin
     l:= y - header;
     l:=(l div hline) + 1;
   end;
   l:=l+SB_planning.Position;
   selection.x:=c;
   selection.Y:=l;
   PB_planning.Refresh;
end;

procedure TGPlanning.MexcelClick(Sender: TObject);
begin

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

procedure TGPlanning.PB_planningMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);

var ny, lh : integer;
    inter : Tintervention;

begin
     PB_planning.hint:='';PB_planning.showhint:=false;
     if assigned(mat) then
     begin
         if (pl_graphic in Fkind) and (x>margin) and (y>0) and (assigned(cache)) then
         begin
              lh := h - header;
              ny:=round((SB_planning.position / SB_planning.max)*(cache.height - lh));
              ny:=ny+y-header;
              assert(ny <= cache.height,'Error calculing coordinates y: '+inttostr(y));
              inter:=mat.getInterAt(x,ny);
              if assigned(inter) then
              begin
                   PB_planning.hint:=inter.getHint;
                   PB_planning.showhint:=true;
                   exit;
              end;
         end;
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

procedure TGPlanning.SB_planningChange(Sender: TObject);
begin
   PB_planning.Refresh;
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

begin
     if not assigned(cache) then
     begin
          cache:=TBGRABitmap.Create(w,24 * hline, BGRAWhite);
     end else
     begin
       cache.SetSize(w,24*hline);
       cache.Fill(BGRAWhite);
     end;
     cache.FontHeight:=14;
     cache.fontname:='Helvetica';
     cache.FontStyle:=[];
     cache.FontQuality:=fqFineClearTypeRGB;


     lineheight:=cache.FontPixelMetric.Lineheight;
     lineheight:=lineheight div 2;
     carwidth:=-1;

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
                      rect.right:=rect.left+colwidth;
                      rect.top:= round(h1* hline);
                      rect.bottom:=round(h2* hline);
                      mat.setBounds(nline,ncol,rect);
                      col:=mat.libs[mat.lines[nline].index].color;
                      cache.RectangleAntialias(rect.left,rect.top,rect.right,rect.bottom,BGRABlack,1,col);
                      s:= mat.libs[mat.lines[nline].index].code+' '+mat.libs[mat.lines[nline].index].caption;
                      rect.Inflate(-1,-1,-1,-1);
                      if rect.Height>lineheight then
                      begin
                        col.Lightness:=65535 - col.Lightness;
                        cache.TextRect(rect, s,taLeftJustify,tlTop,col);
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
         s:=cdays[DayOfTheWeek(d)];
         r.top:=0;r.bottom:=lineheight;
         if c<6 then bmp.TextRect(r,r.left,r.top,s,ts,VGABlue)
         else bmp.TextRect(r,r.left,r.top,s,ts,VGARed);
         s:=datetostr(d);
         r.Bottom:=header;
         r.top:=R.bottom-lineheight;
         bmp.TextRect(r,r.left,r.top,s,ts,BGRABlack);
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
                         cache.fillrect(r,bkcolor,dmset,32000);
                         cache.TextRect(rect,rect.left+5,rect.top+4,s,ts,BGRABlack);
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
     rect.left:=0;rect.right:=w;
     assert(not rect.isEmpty,'Source rectangle is empty');
     bmp.PutImagePart(1,header+1,cache,rect,dmSet);
end;

procedure TGPlanning.FrameResize(Sender: TObject);

var n : integer;

begin
     SB_planning.Top:=PToolbar.Height + 1;
     SB_planning.Left:=self.Width - SB_planning.Width - 1;
     SB_planning.height:=Self.Height -  SB_planning.Top - 1;
     PB_planning.Top:=PToolbar.Height + 1;  ;
     PB_planning.left:=0;
     PB_planning.Height:=self.height -  SB_planning.Top - 1;
     PB_planning.Width:=SB_planning.Left - 10;
     PToolbar.width:=SB_planning.Left;
     margin:=PB_planning.Width div 4;
     hline:=30;

     if pl_graphic in Fkind then
     begin
          hline:=50;
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
     end else
     begin
       TB_date.enabled:=true;
       TB_prev.enabled:=true;
       TB_next.enabled:=true;
     end;

     colwidth:=(PB_planning.Width - margin) div FColNumber;
     PB_planning.Refresh;
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

procedure TGPlanning.PB_planningPaint(Sender: TObject);

var bmp: TBGRABitmap;

begin
   w:=PB_planning.Width;
   h:=PB_planning.Height;
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

procedure TGPlanning.reload;

begin
     load(id,start);
end;

procedure TGPlanning.refresh;

begin
   FrameResize(self);
end;

procedure TGPlanning.SetKind(k : TPlanning_kind);

begin
   Fkind:=k;
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
   if assigned(mat) then freeAndNil(mat);
   if assigned(cache) then freeAndNil(cache);
   if assigned(colplan) then freeAndNil(colplan);
   inherited destroy;
end;

end.


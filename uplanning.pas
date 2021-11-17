unit UPlanning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, EditBtn, Buttons,  Dialogs,
  dateutils,
  DPlanning,RessourcesStrings,
  Graphics,BGRABitmap, BGRABitmapTypes;

type

  { TGPlanning }

  Planning_kind=(pl_week, pl_month, pl_graphic, pl_text, pl_edit, pl_consult);
  TPlanning_kind= set of Planning_kind;

  TGPlanning = class(TFrame)
      procedure PB_planningMouseDown(Sender: TObject; Button: TMouseButton;
        Shift: TShiftState; X, Y: Integer);
      procedure SB_planningChange(Sender: TObject);

    private
    FKind: TPlanning_kind;
    FColNumber : integer;
    w, h : integer;
    mat : TLPlanning;
    selection : tpoint;
    margin, hline, header, colwidth : integer;
    procedure draw_frame(bmp : TBGRABitmap);
    procedure draw_header(bmp : TBGRABitmap);
    procedure draw_header_week(bmp : TBGRABitmap);
    procedure draw_week(bmp : TBGRABitmap);

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
    procedure load(col :  TInterventions;startdate,enddate : tdatetime);
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
   margin:=SB_planning.Width div 4;
   header:=40;
   hline:=30;
   FColNumber:=7;
   selection.x:=-1;
   selection.y:=-1;
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

procedure TGPlanning.SB_planningChange(Sender: TObject);
begin
   PB_planning.Refresh;
end;

procedure TGPlanning.draw_frame(bmp : TBGRABitmap);

begin
   bmp.RectangleAntialias(0,0,w-1,h,BGRABlack,1,BGRAWhite);
end;

procedure TGPlanning.draw_graphics(bmp : TBGRABitmap);

var decal : integer;
    hstart,hend : integer;
    rect : trect;
    s : string;
    ts : ttextstyle;
    nline, ncol : integer;
    inter : TIntervention;
    ref_h   : real;
    ref_pos : integer;
    h1,h2 : real;
    lineheight : integer;

begin
     bmp.FontHeight:=14;
     bmp.fontname:='Helvetica';
     bmp.FontStyle:=[];
     bmp.FontQuality:=fqFineClearTypeRGB; ;

     lineheight:=bmp.FontPixelMetric.Lineheight;
     lineheight:=lineheight div 2;

     ts.RightToLeft:=false;
     ts.SingleLine:=false;
     ts.Clipping:=true;

     decal:=SB_planning.Position;
     hstart:=decal - (trunc((h - header) / hline) div 2);
     decal:=hline div 4;
     hend:=hstart+trunc((h - header) / hline);

     rect.top:=header;rect.bottom:=h;
     rect.left:=1;rect.right:=w;
     bmp.ClipRect:=rect;

     rect.top:=header;rect.left:=margin-20;rect.height:=hline;
     rect.right:=margin;

     ref_h:=-1;
     ref_pos:=-1;

     while rect.bottom<h do
     begin

          if rect.bottom>decal*2 then bmp.DrawLineAntialias(margin-5,rect.bottom-(decal*2),w-2,rect.bottom-(decal*2),Bgra($e6,$e6,$e6),1);
          if rect.bottom>decal then bmp.DrawLineAntialias(margin-5,rect.bottom-decal,w-2,rect.bottom-decal,Bgra($e6,$e6,$e6),1);
          bmp.DrawLineAntialias(margin-10,rect.bottom,w-2,rect.bottom,BGRABlack,1);
          if rect.bottom+decal<h then bmp.DrawLineAntialias(margin-5,rect.bottom+decal,w-2,rect.bottom+decal,Bgra($e6,$e6,$e6),1);

          if (hstart>0) and (hstart<25) then
          begin
               if (ref_h<0) then
               begin
                   ref_h:=hstart;
                   ref_pos:=rect.bottom;
               end;
               s:=inttostr(hstart);
               bmp.TextOut(margin-30,rect.bottom-lineheight,s,BGRABlack,false);
          end;
          rect.bottom:=rect.bottom+hline;
          rect.top:=rect.top+hline;

          inc(hstart);
     end;

     bmp.FontHeight:=12;
     lineheight:=bmp.FontPixelMetric.Lineheight;
     if assigned(mat) then
     begin
       for nline:=0 to mat.linescount-1 do
       begin
            for ncol:=0 to mat.colscount-1 do
            begin
                 if assigned(mat.lines[nline].colums[ncol]) then
                 begin
                      inter:=mat.lines[nline].colums[ncol];
                      h1:=inter.getDecimalHstart;
                      h2:=inter.getDecimalHEnd;

                      rect.left:=margin+(ncol*colwidth);
                      rect.right:=rect.left+colwidth;
                      rect.top:= round(ref_pos+(h1 - ref_h) * hline);
                      rect.bottom:=rect.top+round((h2 - h1) * hline);
                      bmp.RectangleAntialias(rect.left,rect.top,rect.right,rect.bottom,BGRABlack,1,VGAColors.ByIndex[mat.lines[nline].index+5]);
                      s:= mat.libs[mat.lines[nline].index].code+' '+mat.libs[mat.lines[nline].index].caption;

                      if rect.Height>lineheight then bmp.TextRect(rect, s,taLeftJustify,tlCenter,BGRABlack);
                 end;
            end;
       end;
     end;

     rect.top:=0;rect.bottom:=h;
     rect.left:=0;rect.right:=w;
     bmp.ClipRect:=rect;

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
     if pl_week in FKind then draw_header_week(bmp);
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

procedure TGPlanning.draw_week(bmp : TBGRABitmap);

var linenum : integer;
    rect : trect;
    TS: TTextStyle;
    c : integer;
    s : string;
    decal : integer;

begin
     bmp.FontHeight:=14;
     bmp.fontname:='Helvetica';
     bmp.FontStyle:=[];
     bmp.FontQuality:=fqFineClearTypeRGB;
     ts.RightToLeft:=false;
     ts.Clipping:=true;
     decal:=SB_planning.Position;
     rect.top:=header;
     rect.bottom:=rect.top+hline;
     linenum:=decal;
     while (rect.bottom<=h) do
     begin
          rect.bottom:=rect.top+hline;
          if assigned(mat) and (linenum<mat.linescount ) and (mat.lines[linenum].sy_id>0) then
          begin
               if ( linenum=mat.linescount-1) or ((linenum<mat.linescount-1) and (mat.lines[linenum].sy_id<>mat.lines[linenum+1].sy_id)) then
               begin
                    bmp.DrawLineAntialias(1,rect.bottom,w,rect.bottom,BGRABlack,1);
               end else
               begin
                    bmp.DrawLineAntialias(margin+1,rect.bottom,w,rect.bottom,BGRA($d4,$d4,$d4),1);
               end;
               rect.left:=5;rect.right:=margin;


               if (linenum=0) or (mat.lines[linenum].sy_id<>mat.lines[linenum-1].sy_id) then
               begin
                    ts.Alignment:=taLeftJustify;
                    c:=mat.lines[linenum].index;
                    s:=mat.libs[c].code+' '+mat.libs[c].caption;
                    bmp.TextRect(rect,rect.left+5,rect.top+5,s,ts,BGRABlack);
               end;

               ts.Alignment:=taCenter;
               for c:=0 to 6 do
               begin
                    rect.Left:=margin + c*colwidth;
                    rect.Width:=colwidth;
                    if assigned(mat.lines[linenum].colums[c ]) then
                    begin
                         s:=mat.lines[linenum].colums[c ].gethstart+' - '+mat.lines[linenum].colums[c].gethend;
                         bmp.TextRect(rect,rect.left+5,rect.top+4,s,ts,BGRABlack);
                    end;
                    if (linenum=selection.Y -1) and (c=selection.x - 1) then
                    begin
                         bmp.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                    end;
               end;
               if (linenum=selection.Y -1) and (selection.x =0 ) then
               begin
                   rect.Left:=1;
                   rect.right:=margin;
                   bmp.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
               end;

          end else
          begin
            bmp.DrawLineAntialias(1,rect.bottom,w,rect.bottom,BGRA($d4,$d4,$d4),1);
            if (linenum=selection.Y - 1) then
            begin
                 if (selection.x>0) then
                 begin
                   rect.Left:=margin + (selection.x - 1)*colwidth;
                   rect.Width:=colwidth;
                   bmp.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                 end else
                 if (selection.x=0) then
                 begin
                   rect.Left:=1;
                   rect.right:=margin;
                   bmp.RectangleAntialias(rect.Left,rect.Top,rect.Right,rect.bottom,BGRA($21,$73,$46),3);
                 end;
            end;
          end;

          inc(linenum);
          rect.top := rect.bottom;
     end;
end;

procedure TGPlanning.FrameResize(Sender: TObject);

var n : integer;

begin
     SB_planning.Top:=0;
     SB_planning.Left:=self.Width - SB_planning.Width - 1;
     SB_planning.height:=Self.Height - 1;
     PB_planning.Top:=0;
     PB_planning.left:=0;
     PB_planning.Height:=self.height -  1;
     PB_planning.Width:=SB_planning.Left - 10;
     margin:=PB_planning.Width div 4;
     hline:=30;

     if pl_graphic in Fkind then
     begin
          hline:=50;
          n:=trunc((self.Height / hline)/ 2);
          Sb_planning.min:=n - 1;
          Sb_planning.max:=24 - n;
          Sb_planning.Position:=12;
          margin:=PB_planning.Width div 4;
     end;

     colwidth:=(PB_planning.Width - margin) div FColNumber;
     PB_planning.Refresh;
end;

procedure TGPlanning.load(col :  TInterventions;startdate,enddate : tdatetime);

begin
     if assigned(mat) then freeandnil(mat);
     selection.x:=-1;
     selection.y:=-1;
     mat:=TLPlanning.create(startdate,enddate);
     mat.load(col);
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
      if pl_week in FKind then
      begin
           if pl_graphic in Fkind then
           begin
               draw_graphics(bmp);
           end;
           if pl_text in Fkind then
           begin
               draw_week(bmp);
           end;
      end;
      bmp.Draw(PB_planning.Canvas, 0, 0, True);
   finally
     bmp.free;
   end;
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
   FrameResize(self);
end;

destructor TGPlanning.destroy;

begin
   if assigned(mat) then freeAndNil(mat);
   inherited destroy;
end;

end.


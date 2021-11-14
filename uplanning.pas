unit UPlanning;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, EditBtn, Buttons,
  dateutils,
  DPlanning,RessourcesStrings,
  Graphics,BGRABitmap, BGRABitmapTypes;

type

  { TGPlanning }

  TGPlanning = class(TFrame)
      procedure SB_planningChange(Sender: TObject);

    private
    FeditMode : boolean;
    FColNumber : integer;
    w, h : integer;
    mat : TLPlanning;
    margin, hline, header, colwidth : integer;
    procedure draw_frame(bmp : TBGRABitmap);
    procedure draw_header(bmp : TBGRABitmap);
    procedure draw_header_week(bmp : TBGRABitmap);
    procedure draw_week(bmp : TBGRABitmap);



  published
    PB_planning: TPaintBox;
    SB_planning: TScrollBar;
    property EditMode : boolean READ FEditMode WRITE FeditMode;
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
   FeditMode:=false;
   margin:=SB_planning.Width div 4;
   header:=40;
   hline:=30;
   FColNumber:=7;
end;

procedure TGPlanning.SB_planningChange(Sender: TObject);
begin
   PB_planning.Refresh;
end;

procedure TGPlanning.draw_frame(bmp : TBGRABitmap);

begin
   bmp.RectangleAntialias(0,0,w-1,h,BGRABlack,1,BGRAWhite);
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
     draw_header_week(bmp);
end;

procedure TGPlanning.draw_header_week(bmp : TBGRABitmap);

var d : tdatetime;
    c : integer;
    ts : TTextStyle;
    s : string;
    r : trect;

begin
     bmp.FontHeight:=12;
     bmp.FontName:='Arial';
     bmp.FontQuality:=fqFineAntialiasing;
     bmp.FontStyle:=[fsBold];
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
         r.top:=2;r.bottom:=15;
         if c<6 then bmp.TextRect(r,r.left,r.top,s,ts,VGABlue)
         else bmp.TextRect(r,r.left,r.top,s,ts,VGARed);
         s:=datetostr(d);
         r.top:=16;r.bottom:=header;
         bmp.TextRect(r,r.left+5,r.top+15,s,ts,BGRABlack);
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
     bmp.fontname:='Arial';
     bmp.FontStyle:=[fsBold];
     bmp.FontQuality:=fqFineAntialiasing;
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
                    if assigned(mat.lines[linenum].colums[c ]) then
                    begin
                         s:=mat.lines[linenum].colums[c ].gethstart+' - '+mat.lines[linenum].colums[c].gethend;
                         rect.Left:=margin + c*colwidth;
                         rect.Width:=colwidth;
                         bmp.TextRect(rect,rect.left+5,rect.top+4,s,ts,BGRABlack);
                    end;
               end;

               inc(linenum);

          end else
          begin
            bmp.DrawLineAntialias(1,rect.bottom,w,rect.bottom,BGRA($d4,$d4,$d4),1);
          end;

          rect.top := rect.bottom;
     end;


  {   if assigned(mat) then
     begin
           linenum:=0;
           y:=header;
           decal:=0;
           while (linenum<mat.linescount ) and (mat.lines[linenum].sy_id>0) do
           begin
             y:=y + hline;
             if ( linenum=mat.linescount-1) or ((linenum<mat.linescount-1) and (mat.lines[linenum].sy_id<>mat.lines[linenum+1].sy_id)) then
             begin
                  bmp.DrawLineAntialias(1,y,w,y,BGRABlack,1);
                  //plan_pb.canvas.Line(0,header+hline*(linenum+1),w,header+hline*(linenum+1));
             end else
             begin
                  bmp.DrawLineAntialias(margin+1,y,w,y,BGRA($d4,$d4,$d4),1);
             end;



             inc(linenum);
           end;
     end else
     begin
       y:=header;
       while (y<h) do
       begin
         y:=y+hline;
         bmp.DrawLineAntialias(1,y,w,y,BGRA($d4,$d4,$d4),1);
       end;
     end;   }
end;

procedure TGPlanning.FrameResize(Sender: TObject);
begin
     SB_planning.Top:=0;
     SB_planning.Left:=self.Width - SB_planning.Width - 1;
     SB_planning.height:=Self.Height - 1;
     PB_planning.Top:=0;
     PB_planning.left:=0;
     PB_planning.Height:=self.height -  1;
     PB_planning.Width:=SB_planning.Left - 10;
     margin:=PB_planning.Width div 4;

     colwidth:=(PB_planning.Width - margin) div FColNumber;
     PB_planning.Refresh;
end;

procedure TGPlanning.load(col :  TInterventions;startdate,enddate : tdatetime);

begin
     if assigned(mat) then freeandnil(mat);
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
      draw_week(bmp);
      bmp.Draw(PB_planning.Canvas, 0, 0, True);
   finally
     bmp.free;
   end;
end;

procedure TGPlanning.refresh;

begin
   FrameResize(self);
end;

destructor TGPlanning.destroy;

begin
   if assigned(mat) then freeAndNil(mat);
   inherited destroy;
end;

end.


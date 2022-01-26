unit LWTabPage;

{$mode objfpc}{$H+}

interface

  uses
    Classes, SysUtils, Forms, Controls, Dialogs, ExtCtrls, ComCtrls,
    StdCtrls,LCLIntf,LMessages,ressourcesstrings,
    Graphics,BGRABitmap, BGRABitmapTypes;

  type

    { TForm1 }

    TLWPage = record
                    frame : TFrame;
                    bounds : TRect;
                    caption : shortstring;
              end;

    { TLWPageControl }

    TLWPageControl = class(TCustomControl)

       private
            FActivePage : TFrame;
            FActivePageIndex : integer;
            FHeadColor : Tcolor;
            FOnPageChanged : TNotifyEvent;
            pages : array of TLWPage;
            FPageCount: integer;
            serial : integer;
            tabsize : integer;
            procedure SetActivePageIndex(p : integer);
            procedure SetActivePage(f : Tframe);
       published
       property ActivePageIndex : integer READ FActivePageIndex WRITE SetActivePageIndex;
       property HeadColor : TColor READ FHeadColor WRITE FHeadColor;
       property OnChange : TNotifyEvent read FOnPageChanged write FOnPageChanged;
       property PageCount : integer READ FPageCount;
       property ActivePage : TFrame READ FActivePage WRITE SetActivePage ;
       procedure Captionchange(var Msg: TLMessage); message LM_CAPTION_CHANGE;
       constructor create(Aowner : TComponent); override;


      public
      procedure AddTabSheet(F : TFrame);
      procedure CloseTab(index : integer);
      procedure CloseTab(frame : Tframe);
      function GetPage ( index : integer) : TFrame;
      procedure KeyDown(var Key: Word;Shift: TShiftState);override;
      procedure KeyPress(var Key: Char); override;
      procedure MouseDown( Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer); override;
      procedure Paint;override;
      procedure Resize; override;
      destructor destroy;override;
    end;

implementation

uses dw_f;

function Darker(MyColor:TColor; Percent : byte) : Tcolor;
var r,g,b:Byte;
begin
  MyColor:=ColorToRGB(MyColor);
  r:=GetRValue(MyColor);
  g:=GetGValue(MyColor);
  b:=GetBValue(MyColor);
  r:=r-trunc(r*Percent/100);  //Percent% closer to black
  g:=g-trunc(g*Percent/100);
  b:=b-trunc(b*Percent/100);
  result:=RGB(r,g,b);
end;
function Lighter(MyColor:TColor; Percent : integer) : Tcolor;
var r,g,b:Byte;
begin
  MyColor:=ColorToRGB(MyColor);
  r:=GetRValue(MyColor);
  g:=GetGValue(MyColor);
  b:=GetBValue(MyColor);
  r:=r+trunc((255-r)*Percent/100); //Percent% closer to white
  g:=g+trunc((255-g)*Percent/100);
  b:=b+trunc((255-b)*Percent/100);
  result:=RGB(r,g,b);
end;

constructor TLWPageControl.create(Aowner : TComponent);

begin
 inherited create(Aowner);
 FHeadColor:=$dee1e6;
 FPageCount:=0;
 FActivePageIndex:=0;
 serial:=0;
 BorderStyle:=bsSingle;
 //AddHandlerOnKeyDown(@keyDown,false);
 tabsize:=200;
 self.TabStop:=true;
 self.TabOrder:=5;

end;

procedure TLWPageControl.AddTabSheet(F : TFrame);

begin
     if assigned(F) then
     begin
       inc(FPageCount);
       inc(serial);
       setLength(pages,FPageCount);
       pages[FPageCount - 1].frame:=f;
       pages[FPageCount - 1].caption:=f.Caption;
       f.name:=self.name+'_'+inttostr(serial);
       f.align:=alnone;
       f.parent:=self;
       f.Left:=1;f.top:=50;
       f.Width:=self.Width-2;
       f.height:=self.Height - 51;
       SetActivePageIndex(FPageCount);
       refresh;
     end;
end;

procedure TLWPageControl.Captionchange(var Msg: TLMessage);

var i : integer;

begin
 i:=FActivePageIndex - 1;
 Pages[i].caption:=Pages[i].frame.Caption;
 refresh;
end;

procedure TLWPageControl.CloseTab(index : integer);

var i : integer;

begin
     if (index>0) and (index<=FPageCount) then
     begin
          i:=index - 1;
          pages[i].frame.Visible:=false;
          while (i<(FPageCount - 1)) do
          begin
            pages[i]:=Pages[i+1];
            inc(i);
          end;
          FPageCount:=FPageCount - 1;
          setLength(pages,PageCount);
          if FActivePageIndex>FPageCount then ActivePageIndex:=FPageCount;
          setActivePageIndex(FActivePageIndex);
          refresh;
     end;
end;

procedure TLWPageControl.CloseTab(frame : TFrame);

var i : integer;

begin
     assert(assigned(frame),'Frame not assigned');
     for i:=0 to FPageCount-1 do
     begin
       if pages[i].frame=frame then
       begin
            break;
       end;
     end;
     assert((i>=0) and (i<FPageCount),'Page not found');
     CloseTab(i+1);
end;

function TLWPageControl.GetPage ( index : integer) : TFrame;

begin
     assert((index<=length(pages)) and (index>0),'Incorrect index');
     if (index<=Pagecount) and (index>0) then
     begin
          result:=pages[index - 1].frame;
     end;
end;

procedure TLWPageControl.KeyDown(var Key: Word;Shift: TShiftState);

begin
//   Jump to the next open tab	Ctrl + Tab or Ctrl + PgDn
// Jump to the previous open tab	Ctrl + Shift + Tab or Ctrl + PgUp
 // Jump to a specific tab Ctrl + 1 through Ctrl + 8

 // Ctrl + 9 Jump to the rightmost tab
 if (Key=105) then
 begin
      if (ssCtrl in Shift) then
       begin
         setActivePageIndex(FPageCount);
       end;
 end;
// showmessage(inttostr(key));
end;

procedure TLWPageControl.KeyPress(var Key: Char);

begin
 //showmessage('keypress');
end;

procedure TLWPageControl.MouseDown( Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);

var i : integer;


begin
     if (Y>1) and (y<34) then
     begin
          i:=(x div tabsize) + 1;
          if (i>0) and (i<=FPageCount) then
          begin
               SetActivePageIndex(i);
          end;
     end;
end;

procedure TLWPageControl.Paint;

var bmp: TBGRABitmap;
    col : TBGRAPixel;
    TS: TTextStyle;
    r : trect;
    i : integer;
  {c : TCanvas;
  colbase : Tcolor;
  col : Tcolor;
  textstyle : TTextStyle;
  i, j : integer;
  r : trect;
  pts : array[0..6] of Tpoint;


  procedure fillpts(x,y : integer);

  begin
       pts[0].x:=x;pts[0].y:=y;
       pts[1].x:=x - 2;pts[1].y:=y-5;  // Control Point
       pts[2].x:=x  -2;pts[2].y:=y-15 ;  // Control Point
       pts[3].x:=x ;pts[3].y:=y - 30;
       pts[4].x:=x -5; pts[4].y:=y - 35;  // Control Point
       pts[5].x:=x - 5 +tabsize ;pts[5].y:=y - 35;  // Control Point
       pts[6].x:=x + tabsize; pts[6].Y:=y - 30 ;
       {pts[7].x:=x - 15;pts[7].y:=y-15;  // Control Point
       pts[8].x:=x + tabsize;pts[8].Y:=y;
       pts[9].x:=x - 15;pts[9].y:=y - 10;  // Control Point
       pts[10].x:=x + tabsize + 2;pts[10].y:=y; }
  end;                        }

begin

  bmp := TBGRABitmap.Create(width,60, BGRAWhite);
  bmp.FontAntialias:=true;
  bmp.FontName:='Arial';
  bmp.FontHeight:=11;
  col:=bgra($de,$e1,$e6);

  bmp.fillrect(0,0,width,60,col,dmset);
  col.lightness:=60000 ;
  bmp.FillRect(0,35,width,60,bgra($f1,$f3,$f4),dmset);

  ts.RightToLeft:=false;

  for i:=0 to FPageCount-1 do
  begin
    if (i=FActivePageIndex - 1) then
    begin
         bmp.RoundRectAntialias(2+i*tabsize,4,-2+(i+1)*tabsize,33,10,10,bgra(0,0,0),1,bgra($f1,$f3,$f4));
         r.left:=5+i*tabsize;r.top:=3;
         r.right:=r.left+tabsize-10;r.bottom:=30;
         bmp.TextRect(r,10+i*tabsize,10,pages[i].caption,ts,bgra(0,0,0));
    end else
    begin
      r.left:=5+i*tabsize;r.top:=3;
      r.right:=r.left+tabsize-10;r.bottom:=30;
      bmp.TextRect(r,10+i*tabsize,10,pages[i].caption,ts,bgra(128,128,128));
    end;
  end;


  canvas.Brush.Color:=clwhite;
  canvas.FillRect(0,0,width,height);
  bmp.Draw(Canvas, 0, 0, True);
  bmp.free;

{  colbase:=FHeadColor;
  canvas.brush.Color:=colbase;
  canvas.FillRect(0,0,width,60);
  col:=Lighter(colbase, 50);
  canvas.brush.Color:=col;
  canvas.FillRect(0,35,width,60);
  col:=Darker(colbase, 10);
  Canvas.pen.color:=col;
  Canvas.Line(0,35,width,35);
  Canvas.Line(0,59,width,59);
  canvas.AntialiasingMode:=amOn;

  textstyle.Alignment:=taLeftJustify;
  textstyle.Clipping:=true;
  textstyle.SingleLine:=true;
  textstyle.Opaque:=true;

  for i:=0 to FPageCount-1 do
  begin
    if (i=FActivePageIndex - 1) then
    begin
        canvas.Brush.Color:=clwhite;
    end else
    begin
        canvas.brush.Color:=colbase;
    end;

    //canvas.RoundRect(1+i*tabsize,2,-1+(i+1)*tabsize,35,10,10);

    r.Left:=2+i*tabsize;
    r.top:=3;
    r.right:=-1+(i+1)*tabsize;
    r.bottom:=32;
    if (i=FActivePageIndex - 1) then
    begin
        canvas.Pen.color:=clblack;
        canvas.Pen.Width:=1;
        canvas.Rectangle(1+i*tabsize,2,-1+(i+1)*tabsize,35);
        canvas.Font.Color:=clBlack;
        canvas.Font.Bold:=true;
        fillpts(500,32);
        canvas.Pen.color:=clred;
        canvas.Pen.Width:=3;
        //canvas.Polyline(pts);
        canvas.PolyBezier(pts,false,false);
    end else
    begin
        canvas.Line(1+i*tabsize,5,1+i*tabsize,30);
        canvas.Font.Color:=clDkGray;
        canvas.Font.Bold:=false;
    end;
    canvas.TextRect(r,r.left,r.top,pages[i].caption,textstyle);
  end;
  {if FActivePageIndex>0 then
  begin
       canvas.Brush.Color:=clwhite;
       i:=FActivePageIndex - 1;
       canvas.Rectangle(1+i*tabsize,2,-1+(i+1)*tabsize,35);
       canvas.Font.Color:=clred;
       r.Left:=2+i*tabsize;
       r.top:=3;
       r.right:=-1+(i+1)*tabsize;
       r.bottom:=32;
       canvas.TextRect(r,r.left,r.top,pages[i].caption);
  end;    }
  canvas.Brush.Color:=clwhite;
  canvas.FillRect(0,32,width,35); }
end;

procedure TLWPageControl.SetActivePage(f : Tframe);

var i : integer;

begin
     assert(assigned(f),'Frame not assigned');
     for i:=0 to FPageCount-1 do
     begin
          if pages[i].frame=f then
          begin
              setActivePageIndex(i + 1);
              break;
          end;
     end;
     assert((i>=0) and (i<FPageCount),'Frame not found');
end;

procedure TLWPageControl.SetActivePageIndex(p: integer);

var i : integer;

begin
   if (p>0) and (p<=FPageCount) then
   begin
      FActivePageIndex:=p;
      for i:=0 to FPageCount - 1 do
      begin
        if (i<>p - 1) then
        begin
             pages[i].frame.Visible:=false;
        end else
        begin
             pages[i].frame.Visible:=true;
             if FActivePage <>  pages[i].frame then
             begin
                  FActivePage:=pages[i].frame;
                  if assigned(FOnPageChanged) then FOnPageChanged(self);
             end;
        end;
      end;
   end;
   refresh;
end;

procedure TLWPageControl.Resize;

var i : integer;

begin
     for i:=0 to FPageCount-1 do
     begin
          if assigned(pages[i].frame) then
          begin
               pages[i].frame.Left:=1;pages[i].frame.top:=50;
               pages[i].frame.Width:=self.Width - 2;
               pages[i].frame.height:=self.Height - 51;
          end;
     end;
end;

destructor TLWPageControl.destroy;

var i : integer;

begin
     for i:=0 to FPageCount-1 do
     begin
          if assigned(pages[i].frame) then
          begin
             //  freeAndNil(pages[i].frame);
          end;
     end;
     FPageCount:=0;
     setLength(pages,0);
     inherited;
end;

end.



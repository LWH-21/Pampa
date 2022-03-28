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
            gap : integer;
            procedure SetActivePageIndex(p : integer);
            procedure SetActivePage(f : Tframe);
            function getIndexAt(x,y : integer) : integer;
            function getrect(i : integer; var r : trect) : boolean;
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


uses main;

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
 gap:=0;
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

function TLWPageControl.getIndexAt(x,y : integer) : integer;

var i : integer;

begin
     result:=-1;
     if (y>=3) and (y<=34) then
     begin
        result:=(x div tabsize) + 1+gap;
     end;
end;

function TLWPageControl.getrect(i : integer; var r : trect) : boolean;

begin
     result:=true;
     i:=i-1-gap;
     r.left:=2+i*tabsize;
     r.top:=4;
     r.right:=r.left - 2 + tabsize;
     r.bottom:=33;
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
end;

procedure TLWPageControl.KeyPress(var Key: Char);

begin

end;

procedure TLWPageControl.MouseDown( Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);

var i : integer;
    r : trect;
    pt : tpoint;


begin
     if (Y>1) and (y<34) then
     begin
          i:=getIndexAt(x,y);
          if (i>0) and (i<=FPageCount) then
          begin
               if self.ActivePageIndex<>i then
               begin
                    SetActivePageIndex(i);
               end else
               begin
                 if getrect(i,r) then
                 begin
                   pt.x:=X;pt.y:=Y;
                   r.left:=r.right-17;r.right:=r.left+9;
                   r.Top:=r.top+10;r.bottom:=r.Top+9;
                   if r.Contains(pt) then
                   begin
                        parent.Perform(LM_CLOSE_TAB, 0,0 );
                   end;
                 end;
               end;
          end;
     end;

     if (y>20) and (y<55) then
     begin
       if (x>=5) and (x<=20) and (gap>0) then
       begin
         dec(gap);
         refresh;
       end else
       begin
         if (x>=width-20) and (x<= width - 5) then
         begin
           if (width div tabsize) <= (FPageCount- gap) then
           begin
             inc(gap);
             Refresh;
           end;
         end;
       end;
     end;
end;

procedure TLWPageControl.Paint;

var bmp: TBGRABitmap;
    col : TBGRAPixel;
    TS: TTextStyle;
    r : trect;
    i : integer;

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
    if getRect(i+1,r) then
    begin
      if (i=FActivePageIndex - 1) then
      begin
         bmp.RoundRectAntialias(r.left,r.top,r.right,r.bottom,10,10,bgra(0,0,0),1,bgra($f1,$f3,$f4));
         bmp.TextRect(r,r.left+5,10,pages[i].caption,ts,bgra(0,0,0));
         bmp.drawlineantialias(r.right - 10,r.top+12,r.Right-15,r.top+17,bgra(255,0,0),2);
         bmp.drawlineantialias(r.right - 15,r.top+12,r.Right-10,r.top+17,bgra(255,0,0),2);
      end else
      begin
        getRect(i+1,r);
        bmp.TextRect(r,r.Left+5,10,pages[i].caption,ts,bgra(128,128,128));
      end;
    end;
  end;

  // Défilement des onglets
  if gap>0 then bmp.FillRect(5,40,20,55,bgra($00,$00,$77),dmset);
  if (width div tabsize) <= (FPageCount- gap) then
  bmp.FillRect(width-20,40,width - 5,55,bgra($00,$00,$77),dmset);

  canvas.Brush.Color:=clwhite;
  canvas.FillRect(0,0,width,height);
  bmp.Draw(Canvas, 0, 0, True);
  bmp.free;


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
     // todo : erreur ici (fermer planning puis essayer réouvrir)
     assert((i>=0) and (i<=FPageCount),'Frame not found i='+inttostr(i)+' Fpagecount='+inttostr(FpageCount));
end;

procedure TLWPageControl.SetActivePageIndex(p: integer);

var i : integer;
    m : integer;

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
   if (FActivePageIndex>1) then
   begin
        m:=self.width div tabsize;
        if ((FActivePageIndex-gap)>m) then
        begin
           gap := FActivePageIndex - m;
           if FActivePageIndex<FPageCount then gap:=gap + 1;
           if gap<0 then gap:=0;
        end;
   end else gap:=0;
   refresh;
   assert(gap>=0,'Gap < 0');
   assert(gap<=FpageCount,'Gap >= FPageCount('+inttostr(FPageCount)+')');
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
     i:=self.width div tabsize;
     if (FPageCount-gap)>i then
     begin
              gap := FPageCount - i;
              if gap<0 then gap:=0;
      end else gap:=0;
      refresh;
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



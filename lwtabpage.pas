unit LWTabPage;

{$mode objfpc}{$H+}

interface

  uses
    Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
    StdCtrls,LCLIntf;

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
            FOnPageChanged : TNotifyEvent;
            pages : array of TLWPage;
            FPageCount: integer;
            serial : integer;
            tabsize : integer;
            procedure SetActivePageIndex(p : integer);
            procedure SetActivePage(f : Tframe);
       published
       property ActivePageIndex : integer READ FActivePageIndex WRITE SetActivePageIndex;
       property OnChange : TNotifyEvent read FOnPageChanged write FOnPageChanged;
       property PageCount : integer READ FPageCount;
       property ActivePage : TFrame READ FActivePage WRITE SetActivePage ;
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
       f.Left:=0;f.top:=50;
       f.Width:=self.Width;
       f.height:=self.Height - 50;
       SetActivePageIndex(FPageCount);
       refresh;
     end;
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
          setActivePageIndex(ActivePageIndex);
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
     assert((index<length(pages)) and (index>0),'Incorrect index');
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

var c : TCanvas;
  colbase : Tcolor;
  col : Tcolor;
  textstyle : TTextStyle;
  i, j : integer;
  r : trect;

begin
  canvas.Brush.Color:=clwhite;
  canvas.FillRect(0,0,width,height);
  colbase:=$e5edf4;
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
    canvas.Rectangle(1+i*tabsize,2,-1+(i+1)*tabsize,35);
    r.Left:=2+i*tabsize;
    r.top:=3;
    r.right:=-1+(i+1)*tabsize;
    r.bottom:=32;
    if (i=FActivePageIndex - 1) then
    begin
        canvas.Font.Color:=clBlack;
        canvas.Font.Bold:=true;
    end else
    begin
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
  canvas.FillRect(0,32,width,35);
end;

procedure TLWPageControl.SetActivePage(f : Tframe);

var i : integer;

begin
     for i:=0 to FPageCount-1 do
     begin
          if pages[i].frame=f then
          begin
              setActivePageIndex(i + 1);
              break;
          end;
     end;
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
               pages[i].frame.Left:=0;pages[i].frame.top:=50;
               pages[i].frame.Width:=self.Width;
               pages[i].frame.height:=self.Height - 50;
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



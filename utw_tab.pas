unit UTW_Tab;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Buttons,W_A,dw_f,
  LMessages, RessourcesStrings;

type

  { TW_Tab }

  TW_Tab = class(TW_A)
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    TB_return: TToolButton;
    TB_Close: TToolButton;
    TB_stayontop: TToolButton;
    procedure Captionchange(var Msg: TLMessage); message LM_CAPTION_CHANGE;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure TB_CloseClick(Sender: TObject);
    procedure TB_returnClick(Sender: TObject);
    procedure TB_stayontopClick(Sender: TObject);
  private
    var frame : TW_F;
  public

    procedure addFrame(f : TW_F);

  end;

var
  W_Tab: TW_Tab;

implementation

{$R *.lfm}

uses Main;

procedure TW_Tab.TB_returnClick(Sender: TObject);

begin
   if origine = 'O' then
   begin
     if Assigned(Frame) then
     begin
       Frame.align:=alclient;
       MainForm.OpenFrame(Frame,'R');
     end;
   end;
   close;
end;

procedure TW_Tab.TB_stayontopClick(Sender: TObject);
begin
  if self.FormStyle=fsSystemStayOnTop then
  begin
     self.FormStyle:=fsNormal;
     TB_stayontop.Down:=false;
  end else
  begin
    self.FormStyle:=fsSystemStayOnTop;
    TB_stayontop.Down:=true;
  end;
end;

procedure TW_Tab.TB_CloseClick(Sender: TObject);
begin
  close;
end;

procedure TW_Tab.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose:=true;
  if Assigned(Frame) then CanClose:=frame.CanClose;
  if CanClose then
  begin
      //MainForm.notify(Frame,[Main.no_close]);
  end;
end;

procedure TW_Tab.Captionchange(var Msg: TLMessage);

begin
  if assigned(frame) then caption:=frame.caption;
end;

procedure TW_Tab.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;

procedure TW_tab.addFrame(f : TW_F);

begin
     f.SetParent(self);
     f.align:=alclient;
     f.visible:=true;
     self.caption:=f.caption;
     if (f is TW_F) then
     begin
       frame:=f;
     end;
end;


end.


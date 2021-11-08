unit UPlanning_enter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, EditBtn, ExtCtrls, Buttons;

type

  { TFPlanning_enter }

  TFPlanning_enter = class(TFrame)
    Btn_apply: TBitBtn;
    Panel1: TPanel;
    TimeEdit1: TTimeEdit;
    TimeEdit2: TTimeEdit;
    procedure Btn_applyClick(Sender: TObject);
    procedure FrameExit(Sender: TObject);
  private

  public

  end;

implementation

{$R *.lfm}

{ TFPlanning_enter }

procedure TFPlanning_enter.FrameExit(Sender: TObject);
begin
  visible:=false;
end;

procedure TFPlanning_enter.Btn_applyClick(Sender: TObject);
begin
  self.visible:=false;
end;

end.


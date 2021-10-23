unit W_A;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs;

type

  { TW_A ANCETRE DE TOUTES LES FENETRES }

  TW_A = class(TForm)
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);virtual;
    procedure FormCreate(Sender: TObject);
  private

  public
    origine: char;
    constructor Create(AOwner: TComponent);virtual;

  end;

implementation

uses Main;

{$R *.lfm}

{ TW_A }

constructor TW_A.Create(AOwner: TComponent);

begin
  inherited;
  self.OnClose := @FormClose;
end;

procedure TW_A.FormActivate(Sender: TObject);
begin
  MainForm.updatePanel(self);
end;

procedure TW_A.FormCreate(Sender: TObject);

begin

  //if not (fsmodal in self.FormState) then showmessage('formcreate');
end;

procedure TW_A.FormClose(Sender: TObject; var CloseAction: TCloseAction);

begin
     inherited;
     CloseAction:=Cafree;
end;


end.

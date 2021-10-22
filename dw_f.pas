unit dw_f;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,ExtCtrls,StdCtrls, ComCtrls;

type
  TW_F = class(TFrame)
  private

  public
    id : longint;

    procedure init(Data: PtrInt); virtual;
    function CanClose : boolean;virtual;
    procedure close;virtual;
    function getcode : shortstring;virtual;
    function IsModified : boolean; virtual;
    procedure open;virtual; abstract;
    procedure save(Data: PtrInt);virtual;
    procedure delete(Data: PtrInt);virtual;
    procedure SetParent(aparent : TWinControl); override;
  end;

implementation

{$R *.lfm}

uses Main;

procedure TW_F.init(Data: PtrInt);

begin
     assert(false,'Init : This should not be executed');
end;

function TW_F.CanClose : boolean;

begin
     assert(false,'Canclose : This should not be executed');
     result:=false;
end;

procedure TW_F.close;

begin
     if assigned(parent) then
     begin
          MainForm.notify(self,[no_close]);
          if parent is TForm then
          begin
               TForm(parent).Close;
          end;
          if parent is TTabSheet then
          begin
             parent.Visible:=false;
          end;
     end;
end;

function TW_F.IsModified : boolean;

begin
     assert(false,'IsModified : This should not be executed');
     result:=false;
end;

function TW_F.getcode : shortstring;

begin
     result:=self.className();
end;

procedure TW_F.save(Data: PtrInt);

begin
     assert(false,'Save : This should not be executed');
end;

procedure TW_F.Delete(Data: PtrInt);

begin
     assert(false,'Delete : This should not be executed');
end;

procedure TW_F.SetParent(aparent : TWinControl);

var notifs : TNotifySet;

begin
     notifs:=[];
     if not assigned(parent) then
     begin
        notifs:=notifs + [no_open];
     end else
     begin
          if aparent is Tform then notifs:=notifs+[no_inwindow];
          if aparent is TTabSheet then notifs:=notifs+[no_intab];
     end;
     inherited SetParent(aparent);
     MainForm.notify(self,notifs);
end;

end.


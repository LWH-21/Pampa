unit UFr_histo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, Dialogs, Menus, ExtCtrls,
  Buttons, StdCtrls, UHistoManager, RegExpr;

type

  { TFr_Histo }

  TFr_Histo = class(TFrame)
    Label1: TLabel;
    Mouvrir: TMenuItem;
    PMenu: TPopupMenu;
    RG: TRadioGroup;
    SP_close: TSpeedButton;
    TV_ind: TTreeView;

    procedure FrameResize(Sender: TObject);
    procedure MouvrirClick(Sender: TObject);
    procedure OngletChange(Sender: TObject);
    procedure RGClick(Sender: TObject);
    procedure SP_closeClick(Sender: TObject);
    procedure TV_indDblClick(Sender: TObject);
    procedure TV_indDeletion(Sender: TObject; Node: TTreeNode);
    procedure TV_indExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: boolean);
  private

  public
    procedure Show(v: boolean);
  end;

implementation

uses Main;

{$R *.lfm}

{ TFr_Histo }

procedure TFr_Histo.FrameResize(Sender: TObject);
begin
  TV_ind.Left := 0;
  TV_ind.top := 80;
  TV_ind.Width := self.Width;
  TV_ind.Height := self.Height - TV_ind.top;
  Rg.Left := 5;
  SP_close.Left := Self.Width - SP_close.Width - 5;
  RG.Width := sp_close.left + sp_close.Width - RG.left;
  sp_close.BringToFront;
end;


procedure TFr_Histo.MouvrirClick(Sender: TObject);

var
  n: TTreeNode;
  h: thisto;
  i: integer;

begin
  n := TV_ind.selected;
  if assigned(n) then
  begin
    if n.HasChildren then
    begin
      n.Expand(False);
    end
    else
    begin
      if assigned(N.Data) then
      begin
        h := Thisto(N.Data);
        if (h.code[1] = 'F') and (h.code[5] = '|') and (length(h.code) >= 9) then
          MainForm.OpenWindow(h.code);
      end;
    end;
  end;
end;

procedure TFr_Histo.OngletChange(Sender: TObject);
begin

end;

procedure TFr_Histo.RGClick(Sender: TObject);
begin
  TV_ind.Items.Clear;
  if RG.ItemIndex = 0 then
  begin
    MainForm.HistoManager.LoadHisto(TV_ind, nil, MainForm.username);
  end
  else
  begin
    MainForm.HistoManager.LoadHisto(TV_ind, nil, '');
  end;
end;

procedure TFr_Histo.SP_closeClick(Sender: TObject);
begin
  MainForm.Act_affhistoExecute(nil);
end;


procedure TFr_Histo.TV_indDblClick(Sender: TObject);

var
  n: TTreeNode;
  h: thisto;
begin
  if Sender is TTreeView then
  begin
    n := TV_ind.selected;
    if assigned(n) then
    begin
      if assigned(N.Data) then
      begin
        h := Thisto(N.Data);
        MainForm.OpenWindow(h.code);
      end;
    end;
  end;
end;

procedure TFr_Histo.TV_indDeletion(Sender: TObject; Node: TTreeNode);

begin
  if assigned(Node.Data) then
  begin
    Thisto(Node.Data).Free;
    Node.Data := nil;
  end;
end;

procedure TFr_Histo.TV_indExpanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: boolean);
begin
  AllowExpansion := True;
  if Assigned(Node.Data) then
  begin
    if RG.ItemIndex = 0 then
    begin
      MainForm.HistoManager.LoadHisto(TV_ind, Node, MainForm.username);
    end
    else
    begin
      MainForm.HistoManager.LoadHisto(TV_ind, Node, '');
    end;
  end;
end;

procedure Tfr_histo.Show(v: boolean);

begin
  self.Visible := v;
  if v then
  begin
    if RG.ItemIndex = 0 then
    begin
      MainForm.HistoManager.LoadHisto(TV_ind, nil, MainForm.username);
    end
    else
    begin
      MainForm.HistoManager.LoadHisto(TV_ind, nil, '');
    end;
    FrameResize(nil);
  end
  else
  begin
    TV_ind.Items.Clear;
  end;
end;

end.

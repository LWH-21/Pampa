unit UFlogin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BufDataset, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, W_A;

type

  { TFLogin }

  TFLogin = class(TW_A)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    Cb_pwd: TCheckBox;
    CB_cnx: TComboBox;
    Ed_user: TEdit;
    Ed_pwd: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    MDetail: TMemo;
    Sp_defaut: TSpeedButton;
    procedure CB_cnxChange(Sender: TObject);
    procedure Cb_pwdChange(Sender: TObject);
    procedure Ed_pwdChange(Sender: TObject);
    procedure Ed_userChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction); override;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Sp_defautClick(Sender: TObject);
  private
  public
    login, password,profil, defprofil : string;
    procedure Load;
  end;


implementation

uses DataAccess,UException;

{$R *.lfm}

{ TFLogin }

procedure TFLogin.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  inherited;
  CloseAction:=caHide;
end;

procedure TFLogin.CB_cnxChange(Sender: TObject);

var ts : TStringList;
    i : integer;
    s : string;

begin
   try
     ts:=TStringList.Create;
     profil:= Cb_cnx.Text;
     Ed_user.Text:='';
     Ed_pwd.text:='';
     Mdetail.Clear;
     Maindata.ini.ReadSection(profil,ts);
     Ed_user.SetFocus;
     for i:=0 to ts.Count - 1 do
     begin
          s:=ts.Strings[i];
          if s='USERNAME' then
          begin
               login:=MainData.ini.ReadString(profil,s,'');
               Ed_user.Text:=Login;
          end;
          if s='PASSWORD' then
          begin
               password:=MainData.ini.ReadString(profil,s,'');
               Ed_pwd.Text:=password;
          end;
          s:=s+'='+MainData.ini.ReadString(profil,s,'');
          Mdetail.Lines.Add(s);
     end;
     Mdetail.CaretPos.SetLocation(0,0);
     MDetail.VertScrollBar.Position:=0;
     if profil<>defprofil then  Sp_defaut.enabled:=true else
     Sp_defaut.Enabled:=false;
   finally
     freeAndNil(ts);
   end;
end;

procedure TFLogin.Cb_pwdChange(Sender: TObject);
begin
  if CB_pwd.Checked then
  begin
       ed_pwd.echomode:= emNormal;
  end else
  begin
       ed_pwd.EchoMode:=emPassword;
  end;
end;

procedure TFLogin.Ed_pwdChange(Sender: TObject);
begin
  password:=Ed_pwd.text;
end;

procedure TFLogin.Ed_userChange(Sender: TObject);
begin
  login:=Ed_user.Text;
end;

procedure TFLogin.FormCreate(Sender: TObject);
begin
     login:='';
     password:='';
     profil:='';
     defprofil:='';
end;

procedure TFLogin.FormShow(Sender: TObject);
begin
  load;
end;

procedure TFLogin.Sp_defautClick(Sender: TObject);
begin
  if defprofil=profil then exit;
  if Maindata.IsNullOrEmpty(profil) then exit;
  try
     MainData.ini.WriteString('DEFAULT','CNX',profil);
     defprofil:=profil;
     Sp_defaut.Enabled:=false
  except
  end;
end;

procedure TFLogin.Load;

var s: String;
    ts : TStringList;

begin
     try
       try
       CB_cnx.Clear;
       ts:=TStringList.Create;
       Maindata.ini.ReadSections(ts);
       for s in ts do
       begin
            if s<>'DEFAULT' then
            begin
                 CB_cnx.AddItem(s,nil);
            end;
        end;
        defprofil:=Maindata.ini.ReadString('DEFAULT','CNX','???');
        CB_cnx.Text:=defprofil;
        Sp_defaut.Enabled:=false;
        CB_cnxChange(self);
        except
          on e : Exception do Error (e, dber_system,'TFLogin.Load');
        end;
     finally
       freeAndNil(ts);
     end;
end;

end.


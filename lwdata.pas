{ Stockage de la description des colonnes de la base de données }
unit LWData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

TStyle = (sty_unknow,sty_key,sty_code, sty_name, sty_alphanum, sty_alphanumu, sty_alphanuml, sty_crc, sty_phone, sty_date, sty_time, sty_social);

TCrcException = class(Exception);

{Description d'une colonne : nom, type de données, longueur, précision...}
TColumnDesc = class(TCollectionItem)
 private
 public
   table_name : shortString;   //< Nom de la table dans la base de données
   col_name : shortString;     //< Nom de la colonne dans la base de données
   external_name : shortString; //< Nom de la colonne tel que présenté à l'utilisateur
   syscol : char;              //Yes No
   col_type : shortString;    //< DataType : CHAR, DATE, NUM, BOOL
   col_lenght : integer;      //< Longuer pour les types CHAR et DECIMAL
   col_prec : integer;        //< Précision pour les types DECIMAL
   mask : shortstring;
   charcase : char;         //Upper Lower FirstUpper, Any
   defval : shortstring;
   ctrl : shortstring;
   json : string;

   constructor Create(ACollection: TCollection); override;
   procedure copy(dest : TColumnDesc);
   procedure setStyle(s : shortString);

 published

 end;

  TTableDesc = Class(TCollection )
  private
    function GetItems(Index: integer): TColumnDesc;
    procedure SetItems(Index: integer; AValue: TColumnDesc);
  public
    constructor Create;
  public
    function Add: TColumnDesc;
    function Find (table : string; col : string) : TColumnDesc;
    property Items[Index: integer]: TColumnDesc read GetItems write SetItems; default;
  end;

implementation

{ TColumnDesc}

constructor TColumnDesc.Create(ACollection: TCollection );(* **************** *)

begin
  if Assigned(ACollection) and (ACollection is TTableDesc) then
  inherited Create(ACollection);
end;


procedure  TColumnDesc.copy(dest : TColumnDesc);

begin
    if assigned(dest) then
    begin
        dest.table_name:=table_name;
        dest.col_name:=col_name;
        dest.external_name:=external_name;
        dest.syscol:=syscol;
        dest.col_lenght:=col_lenght;
        dest.col_prec:=col_prec;
        dest.mask:=mask;
        dest.charcase:=charcase;
        dest.defval:=defval;
        dest.ctrl:=ctrl;
        dest.json:=json;
    end;
end;

procedure TColumnDesc.setStyle(s : shortString);

begin

end;

function TTableDesc.GetItems(Index: integer): TColumnDesc;(* **************** *)
begin
  Result := TColumnDesc(inherited Items[Index]);
end;

procedure TTableDesc.SetItems(Index: integer; AValue: TColumnDesc);(* ******* *)
begin
  Items[Index].Assign(AValue);
end;

constructor TTableDesc.Create;
begin
  inherited Create(TColumnDesc);
end;

function TTableDesc.Add: TColumnDesc;
begin
  Result := TColumnDesc(inherited Add);
end;

function TTableDesc.Find (table : string; col : string) : TColumnDesc;

var i : integer;
    trouve : boolean;
    cd : TColumnDesc;

begin
     i:=0;
     trouve:=false;
     while (i<Count) and (not trouve) do
     begin
         cd := Items[i];
         if (cd.table_name=table) and (cd.col_name=col) then
         begin
           trouve:=true;
           Find:=Items[i];
         end else inc(i);
     end;
     if not trouve then Find:=nil;
end;

end.


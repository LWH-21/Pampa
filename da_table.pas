unit DA_table;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, strutils, DateUtils, DB, SQLDB, DataAccess, Variants, Dialogs, Forms, Controls, lwdata,
  LConvEncoding,LazUTF8,ZDataset, ZSqlUpdate,
  Math,fpexprpars,RegExpr,
  UException;

type

  Tupdate_mode = (um_create, um_read, um_update, um_delete);

  { TDA_table }
  TDA_table = class(TDataModule)
  private
  protected

  public
    table: string;
    cle: string;
    checkcrc: boolean;






    procedure apply_style(R : TDataSet; st : TUpdateStatus); virtual;
    function codeCalc(R : TDataSet) : shortstring;
    function ConcurrencyControl(R : TDataSet) : boolean;
    function Delete(R: TDataSet; var id: longint): TDbErrcode;
    function getcrc(R: TDataSet): longint;
    function getCurrentId  : longint;
    function getNextId : longint;
    procedure init(D: TMainData);
    function Insert(var R: TDataSet): TDbErrcode;
    function Modified(R : TDataSet) : boolean;
    function normalize ( s : string) : string;
    procedure Read(var R: TDataSet; id: longint);
    procedure search(crit : string; R : TDataset);virtual ; abstract;
    procedure setCrc(R : TDataSet); virtual;
    function setDefault(R : TDataSet) : boolean; virtual;
    function setID(R : TDataSet) : boolean; virtual;
    function Test(R: TDataset; action: char; var nbwarnings, nberr: integer; var msg: string): boolean;
    function Write(R: TDataSet; var id: longint; mode : Tupdate_mode = um_read): TDbErrcode;








  end;

function crc32(crc: cardinal; buf: string): longint;

implementation

{$R *.lfm}

uses Main, RessourcesStrings;

const
  crc32_table: array[byte] of cardinal = (
    $00000000, $77073096, $ee0e612c, $990951ba, $076dc419,
    $706af48f, $e963a535, $9e6495a3, $0edb8832, $79dcb8a4,
    $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07,
    $90bf1d91, $1db71064, $6ab020f2, $f3b97148, $84be41de,
    $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7, $136c9856,
    $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9,
    $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4,
    $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b,
    $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3,
    $45df5c75, $dcd60dcf, $abd13d59, $26d930ac, $51de003a,
    $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599,
    $b8bda50f, $2802b89e, $5f058808, $c60cd9b2, $b10be924,
    $2f6f7c87, $58684c11, $c1611dab, $b6662d3d, $76dc4190,
    $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f,
    $9fbfe4a5, $e8b8d433, $7807c9a2, $0f00f934, $9609a88e,
    $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
    $6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed,
    $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950,
    $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3,
    $fbd44c65, $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2,
    $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb, $4369e96a,
    $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5,
    $aa0a4c5f, $dd0d7cc9, $5005713c, $270241aa, $be0b1010,
    $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
    $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17,
    $2eb40d81, $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6,
    $03b6e20c, $74b1d29a, $ead54739, $9dd277af, $04db2615,
    $73dc1683, $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8,
    $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1, $f00f9344,
    $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb,
    $196c3671, $6e6b06e7, $fed41b76, $89d32be0, $10da7a5a,
    $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5,
    $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1,
    $a6bc5767, $3fb506dd, $48b2364b, $d80d2bda, $af0a1b4c,
    $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef,
    $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236,
    $cc0c7795, $bb0b4703, $220216b9, $5505262f, $c5ba3bbe,
    $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31,
    $2cd99e8b, $5bdeae1d, $9b64c2b0, $ec63f226, $756aa39c,
    $026d930a, $9c0906a9, $eb0e363f, $72076785, $05005713,
    $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b,
    $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
    $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1,
    $18b74777, $88085ae6, $ff0f6a70, $66063bca, $11010b5c,
    $8f659eff, $f862ae69, $616bffd3, $166ccf45, $a00ae278,
    $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7,
    $4969474d, $3e6e77db, $aed16a4a, $d9d65adc, $40df0b66,
    $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
    $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605,
    $cdd70693, $54de5729, $23d967bf, $b3667a2e, $c4614ab8,
    $5d681b02, $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b,
    $2d02ef8d);

function crc32(crc: cardinal; buf: String): longint;

var
  r: cardinal;
  len : integer;
  i : cardinal;


begin
  buf:=Trim(buf);
  len:=length(buf);
  try
  crc := crc xor $FFFFFFFF;

  while (len > 0) do
  begin
    i:=ord(buf[len]);
    i:=crc xor i;
    i:=i and $FF;
    crc := crc32_table[i] xor (crc shr 8);
    Dec(len);
  end;
  r := crc xor $FFFFFFFF;
  if r > 2147483647 then
    r := r - 2147483647;
  Result := r;
  except
     on E: Exception do Error(E, dber_system, 'crc32 ');
  end;
end;

procedure TDA_table.apply_style(R : TDataSet; st : TUpdateStatus);

var i : integer;
    nom : string;
    n,n1 : string;
    cd: TColumnDesc;

begin
  //if (st<>usmodified) and (st<>usInserted) then exit;
  assert(assigned(R), 'Query not assigned');
  assert(R.RecordCount <= 1, 'Just one update allowed');
  try
    for i := 0 to R.FieldCount - 1 do
    begin
      nom := (R.fields[i].FieldName).ToUpper;
      if nom > '' then
      begin
        cd := Maindata.tablesdesc.Find(table, nom);
        assert(assigned(cd), 'Description du champ ' + nom + ' non trouvée');
        assert(cd.col_name = nom, 'Description du champ ' + nom + ' non trouvée');
        n := R.fields[i].asString;
        n1:=n;
        if (cd.col_type='CHAR') then
        begin
              n1:=trim(n);
              n1:=leftstr(n1,cd.col_lenght);
              //if cd.style='NAME' then n1:=AnsiProperCase(n1,StdWordDelims+['-']);
        end;
        if n<>n1 then
        begin
             R.fields[i].Value:=n1;
        end;
      end;
    end;
  except
     on E: Exception do Error(E, dber_sql, 'TDA_table.apply_style '+table);
  end;
end;


function TDA_table.getcrc(R: TDataSet): longint; (* ************************* *)

var
  i: integer;
  c: longint;
  nom, ret: string;
  cd: TColumnDesc;
  n: string;

begin
  assert(assigned(R), 'Dataset not assigned');
  assert(table > '', 'Table name not assigned');
  ret := '';
  try
    try
      c:=random(2147483647);
      for i := 0 to R.FieldCount - 1 do
      begin
        nom := (R.fields[i].FieldName).ToUpper;
        if (nom > '') and (nom <> 'CRC') then
        begin
          cd := Maindata.tablesdesc.Find(table, nom);
          assert(assigned(cd), 'Description du champ ' + nom + ' non trouvée');
          if (cd.col_name<>'SY_ID') and (cd.col_name<>'SY_CRC') and (cd.col_name<>'SY_ROWVERSION') and (cd.col_name<>'SY_LASTUSER') then
          begin
            n := VartoStr(R.fields[i].AsString);
            ret := ret + trimRight(n);
          end;
        end;
      end;
      ret := ret + '     ';
      c := crc32(0, ret);
    except
      on E: Exception do Error(E, dber_sql, 'TDA_table.getcrc '+table);
    end;
  finally
     Result := c;
  end;
end;

procedure TDA_table.init(D: TMainData);(* ************************************ *)
begin

//  RechQuery.Transaction := Data.Transaction;
end;

procedure TDA_table.Read(var R: Tdataset; id: longint);(* ********************** *)

var
  sselect: string;
  sinsert : string;
  svalues : string;
  supdate: string;
  sdelete: string;
  swhere: string;
  scrc : string;
  nbupd, nbselect: integer;
  i: integer;
  cd: TColumnDesc;
  castmemo,s : shortstring;
  upd : TZUpdateSQL;

begin
  if not assigned(R) then R:=MainData.getDataSet(R,false);
  assert(assigned(R), 'Requête non assignée');
  assert(table > '', 'Table non renseignée');
  if not MainData.isConnected then exit;
  Screen.Cursor := crHourGlass;
  MainForm.setMicroHelp(rs_read+' ['+table+'] : '+inttostr(id));
  if not assigned(R) then
  begin
    Maindata.readDataSet(R,'',false);
  end;
  R.Close;
  castmemo:=Maindata.getSyntax('CASTMEMO','TRIM(%s)');
 { if R is TSqlQuery then
  begin
    TSqlQuery(R).database := MainData.Database;
    TSqlQuery(R).UsePrimaryKeyAsKey := False;
  end else
  if R is TZQuery then
  begin
       TZquery(R).Connection:=MainData.ZConnection;
  end; }
  if MainData.isConnected then
  begin

    sselect := 'SELECT ';
    supdate := 'UPDATE ' + table + ' SET ';
    sdelete := 'DELETE FROM ' + table;
    sinsert := 'INSERT INTO '+table+' (';
    scrc:='';
    svalues:='';

    nbupd := 0;
    nbselect := 0;

    swhere := ' WHERE ' + cle + ' = ' + IntToStr(id);

    i := 0;
    while i < Maindata.tablesdesc.Count do
    begin
      cd := Maindata.tablesdesc[i];
      if cd.table_name = table then
      begin
        Inc(nbselect);
        if nbselect > 1 then
        begin
          sselect := sselect + ', ';
        end;
        if (cd.col_type='CHAR')  then
        begin
            s:=StringReplace(castmemo,'%s',cd.col_name,[rfReplaceAll]);
            sselect := sselect + ' '+s+' as ' + cd.col_name;
        end else
        begin
             sselect := sselect + cd.col_name;
        end;
        if cd.col_name<>'SY_ID' then
        begin
          if nbupd > 0 then
            supdate := supdate + ', ';
          supdate := supdate + cd.col_name + '=:' + cd.col_name;
          Inc(nbupd);
        end;
        if cd.col_name='SY_CRC' then
        begin
          scrc:=scrc+' AND SY_CRC = :OLD_SY_CRC';
        end;
        // todo : lwj-A revoir : le test ne marche pas
        if cd.col_name='SY_ROWVERSION' then
        begin
          //scrc:=scrc+' AND SY_ROWVERSION = :OLD_SY_ROWVERSION';
        end;
        if nbselect>1 then sinsert:=sinsert+', ';
        sinsert:=sinsert+cd.col_name;
        if nbselect>1 then svalues:=svalues+', ';
        svalues:=svalues+':'+cd.col_name;
      end;
      Inc(i);
    end;
    sselect := sselect + ' FROM ' + table + ' ' + swhere;
    supdate := supdate + swhere+' '+scrc;
    sdelete := sdelete + ' ' + swhere+scrc;
    sinsert:=sinsert+') VALUES ('+svalues+')';
  end;

  MainData.readDataSet(R,sselect,false,sinsert,sdelete,supdate);

  (*try
    if R is TSqlQuery then
    begin
      TSqlQuery(R).sql.text:=sselect;
      TSqlQuery(R).UpdateSql.text:=supdate;
      TSqlQuery(R).DeleteSQL.text:=sdelete;
      TSqlQuery(R).InsertSQL.text:=sinsert;
      TSqlQuery(R).prepare;
    end else
    if R is TZQuery then
    begin
         TZquery(R).sql.text:=sselect;
         upd:=TZquery(R).UpdateObject;
         if not assigned(upd) then
         begin
             upd:=TZUpdateSQL.Create(R);
         end;
         upd.DeleteSQL.Text:=sdelete;
         upd.ModifySQL.Text:=supdate;
         upd.InsertSQL.Text:=sinsert;
         TZquery(R).UpdateObject:=upd;
         TZquery(R).prepare;
         TZquery(R).ReadOnly:=false;
    end;
  except
    on E: Exception do Error(E, dber_sql, sselect);
  end;    *)

  try
    R.Open;
  except
    on E: Exception do
      Error(E, dber_sql, sselect);
  end;
  for i:=0 to R.Fields.Count - 1 do
  begin
       if (R.Fields[i].Name<>'SY_ID') and (R.Fields[i].Name<>'SY_CRC') and (R.Fields[i].Name<>'SY_LASTUSER') and (R.Fields[i].Name<>'SY_ROWVERSION') then
       R.Fields[i].ReadOnly:=false;
  end;
  if R is TSqlQuery then TSqlTransaction(TSQLquery(R).Transaction).CommitRetaining ;
  MainForm.setMicroHelp(rs_ready,0);
  Screen.Cursor := crDefault;
end;

function TDA_table.Delete(R: TDataSet; var id: longint): TDbErrcode;

begin
  assert(assigned(R), 'Query not assigned');
  assert(R.RecordCount <= 1, 'Just one update allowed');
  //assert(assigned(R.Transaction), 'Transaction not assigned');
  //assert(R.Transaction is TSQLTransaction, 'Transaction is not TSQLTransation');
 { Result := cber_nothing;
  if not MainData.isConnected then exit;
  R.Delete;
  Result := dber_none;}
end;

function TDA_table.getCurrentId  : longint;

var queryid : TDataSet;
    SQueryId : String;
    l1,l2 : longint;

begin
   QueryId:=nil;
   result:=1;
   SqueryId:=Maindata.getQuery('SP001','');
   try
     try
       if SqueryId>' ' then
       begin
          SqueryId:=SqueryId.Replace('%t',table);
          SqueryId:=SqueryId.Replace('%set','N');
          MainData.readDataSet(QueryId,SQueryID,true);
          if queryid.RecordCount=1 then
          begin
                result:=queryid.fields[0].AsInteger;
          end;
       end else
       begin
         SqueryId:=Maindata.getQuery('QID01','SELECT I.ID, MAX(T.SY_ID) FROM LWH_ID I CROSS JOIN %t T WHERE ENTITY =''%t''');
         SqueryId:=SqueryId.Replace('%t',table);
         MainData.readDataSet(QueryId,SQueryID,true);
         if queryid.RecordCount=1 then
         begin
             l1:=queryid.fields[0].AsInteger;
             l2:=queryid.fields[1].AsInteger;
             result:=max(l1,l2);
             inc(result);
         end;
       end;
     except
       on E: Exception do Error(e, dber_sql, 'TDA_table.GetCurrentId('+table+')');
     end;
   finally
      if assigned(QueryID) then
      begin
           queryid.close;
           queryid.free;
      end;
   end;
end;

function TDA_table.getNextId : longint;

var queryid : TDataSet;
    SQueryId : String;
    l1,l2 : longint;

begin
    QueryId:=nil;
    try
      try
        SqueryId:=Maindata.getQuery('SP001','');
        if SqueryId>' ' then
        begin
          SqueryId:=SqueryId.Replace('%t',table);
          SqueryId:=SqueryId.Replace('%set','Y');
          MainData.readDataSet(QueryId,SQueryID,true);
          if queryid.RecordCount=1 then
          begin
               result:=queryid.fields[0].AsInteger;
          end;
        end else
        begin
          SqueryId:=Maindata.getQuery('QID01','SELECT I.ID, MAX(T.SY_ID) FROM LWH_ID I CROSS JOIN %t T WHERE ENTITY =''%t''');
          SqueryId:=SqueryId.Replace('%t',table);
          MainData.readDataSet(QueryId,SQueryID,true);
          if queryid.RecordCount=1 then
          begin
             l1:=queryid.fields[0].AsInteger;
             l2:=queryid.fields[1].AsInteger;
             result:=max(l1,l2);
             inc(result);
             SqueryId:=Maindata.getQuery('QID02','UPDATE LWH_ID SET ID=%r WHERE ENTITY =''%t'';');
             SqueryId:=SqueryId.Replace('%t',table);
             SqueryId:=SqueryId.Replace('%r',inttostr(result));
             MainData.DoScript(SQueryId);
          end else
          begin
            result:=1;
            SqueryId:=Maindata.getQuery('QID03','INSERT INTO LWH_ID (ENTITY, ID) VALUES (''%t'', %r);');
            SqueryId:=SqueryId.Replace('%t',table);
            SqueryId:=SqueryId.Replace('%r',inttostr(result));
            MainData.DoScript(SQueryId);
          end;
        end;
      except
        on E: Exception do Error(e, dber_sql, 'TDA_table.GetNextId('+table+')');
      end;
    finally
      if assigned(queryid) then
      begin
        queryid.close;
        queryid.free;
      end;
    end;
end;

function TDA_table.Modified(R : TDataSet) : boolean;

var F : Tfield;
    c_old, c_new : variant;

begin
  result:=true;
  c_old:=-1;c_new:=1;
  if R.RecordCount<1 then exit;
  try
    F:=R.Fields.FindField('SY_CRC');
    IF assigned(F) then
    begin
        try
           c_old:=F.OldValue;
        except
          exit;
        end;
        try
           c_new:=F.AsInteger;
        except
          exit;
        end;
        if c_old=c_new then result:=false;
    end;
  except
    on E: Exception do Error(e, dber_sql, 'TDA_table.Modified');
  end;
end;

function TDA_table.codeCalc(R : TDataSet) : shortstring;

var QueryCode: TDataset;
    sql : string;
    base, fname,lname : shortstring;
    n : longint;
    F : Tfield;

begin
     assert(assigned(R),'Dataset not assigned');
     assert(assigned(R.Fields.FindField('SY_CODE')),'No SY_CODE field in dataset');
     QueryCode:=nil;
     result:='0000000';

     F:=R.Fields.FindField('SY_CODE');
     IF assigned(F) then
     begin
       base:=F.AsString;
       result:=normalize(base);
       result:=uppercase(result);
       result:=trim(ReplaceStr(result,' ',''));
       if R.RecordCount>0 then  // RecordCount=0 => Insert
       begin
         if (F.OldValue=F.AsString) then
         begin
              if (result=base) and (length(result)=7) and (copy(result,1,4)<>'????') then
              begin
                   exit;
              end;
         end else
         if (length(result)=7) and (copy(result,1,4)<>'????') then
         begin
           sql:=Maindata.getQuery('QID04','SELECT SY_CODE from %t where SY_CODE=''%code'' ');
           sql:=sql.Replace('%t',table);
           sql:=sql.Replace('%code',result);
           MainData.readDataSet(QueryCode,sql,true);
           if querycode.RecordCount=0 then
           begin
                querycode.close;
                querycode.free;
                exit;
           end;
         end;
       end;
       lname:='';fname:='';
       F:=R.Fields.FindField('SY_FIRSTNAME');
       if assigned(F) then
       begin
         fname:=F.AsString;
       end;
       F:=R.Fields.FindField('SY_LASTNAME');
       if assigned(F) then
       begin
         lname:=F.AsString;
       end;
       base:=trim(lname)+trim(fname);
       base:=AnsiUpperCase(base);
       base:=normalize(base);
       base:=ReplaceStr(base,' ','');
       base:=leftstr(base,4);
       base:=trim(base);
       if base<=' ' then base:='????';
       while length(base)<6 do base:=base+'0';
       base:=leftstr(base,6)+'1';

       sql:=Maindata.getQuery('QID04','SELECT SY_CODE from %t where SY_CODE=''%code'' ');
       sql:=sql.Replace('%t',table);
       sql:=sql.Replace('%code',base);
       MainData.readDataSet(QueryCode,sql,true);
       if querycode.RecordCount=0 then
       begin
         result:=trim(base);
         querycode.close;
         querycode.free;
         exit;
       end;
       querycode.close;
       sql:=MainData.getQuery('QID05','SELECT MAX(SY_CODE) from %t where SY_CODE LIKE ''%code%'' ');
       sql:=sql.Replace('%t',table);
       sql:=sql.Replace('%code',leftstr(base,4));
       MainData.readDataSet(QueryCode,sql,true);
       sql := querycode.fields[0].asString;
       sql:=sql.substring(4,10);
       if trystrtoint(sql,n) then
       begin
         inc(n);
         result:=leftstr(base,4);
         base:=inttostr(n);
         while length(base)<3 do base:='0'+base;
         result:=trim(result+base);
       end;
     end;
end;

function TDA_table.ConcurrencyControl(R : TDataSet) : boolean;

var squerycrc : string;
    datacrc : Tdataset;
    F : TField;
    s_id : longint;
    old_crc, new_crc : longint;
    v : variant;

begin
  assert(assigned(R),'Dataset not assigned');
  assert(assigned(R.Fields.FindField('SY_ID')),'No key field');
  assert(assigned(R.Fields.FindField('SY_CRC')),'No CRC field');
  assert(assigned(R.Fields.FindField('SY_ROWVERSION')),'No RowVersion field');
  assert(assigned(R.Fields.FindField('SY_LASTUSER')),'No Last User field');
  assert(table>' ','Not table specified');
  result:=true;
  F:=R.Fields.FindField('SY_ID');
  IF assigned(F) then
  begin
       s_id:=F.AsLongint;
       // Todo MainData.getquery
       squerycrc := 'SELECT SY_CRC, SY_ROWVERSION, SY_LASTUSER FROM %t WHERE SY_ID=%id';
       squerycrc:=squerycrc.Replace('%t',table);
       squerycrc:=squerycrc.Replace('%id',inttostr(s_id));
       MainData.readDataSet(datacrc,squerycrc,true);
       if datacrc.RecordCount>0 then
       begin
            new_crc:=datacrc.FieldByName('SY_CRC').AsInteger;
            old_crc:=new_crc;
            try
              if not VarIsNull(R.FieldByName('SY_CRC').OldValue) then old_crc:=R.FieldByName('SY_CRC').OldValue;
            except
              old_crc:=new_crc;
            end;
            if new_crc<>old_crc then result:=false;
       end else
       begin
         result:=false;
       end;
       datacrc.Close;
       datacrc.Free;
  end;
end;

function TDA_table.Insert(var R: TDataSet): TDbErrcode;

var
  cd: TColumnDesc;
  fname : string;
  i: integer;
  l: longint;
  f: real;

begin
  if not assigned(R) then R:=MainData.getDataSet(R,false);
  assert(assigned(R), 'Query not assigned');
  assert((R is TSQLQuery) or (R is TZQuery),'Invalid data set type');
 // assert(assigned(R.Transaction), 'Transaction not assigned');
//  assert(R.Transaction is TSQLTransaction, 'Transaction is not TSQLTransation');
  MainForm.setMicroHelp(rs_insert+' ['+table+']');
  Result := cber_nothing;
  if not MainData.isConnected then exit;

  Screen.Cursor := crHourGlass;

  if R.FieldCount = 0 then
  begin
    Read(R, -1);
  end;

  try
    R.Append;
    for i := 0 to R.FieldCount - 1 do
    begin
      fname := R.fields[i].FieldName;
      fname := fname.ToUpper;
      if fname > '' then
      begin
        cd := Maindata.tablesdesc.Find(table, fname);
        assert(assigned(cd), 'Field description ' + fname + ' not found');
        assert(cd.col_name = fname, 'Field description ' + fname + ' not found');
        if fname='SY_ID' then
        begin
                R.fields[i].asInteger := getCurrentId;
        end;
        if fname='SY_CODE' then
        begin
             R.fields[i].asString := '';
        end;
        if fname='SY_CRC' then
        begin
             R.fields[i].asInteger:=random(2147483647);
        end;
        if fname='SY_LASTUSER' then
        begin
             R.fields[i].asString := Mainform.username;
        end;
        if fname='SY_ROWVERSION'  then
        begin
             R.fields[i].asDatetime:=now;
        end;
        if fname <> cle then
        begin
          if cd.defval > ' ' then
          begin
            if (cd.col_type = 'CHAR') or (cd.col_type = 'VARCHAR') then
              R.fields[i].asString := cd.defval;
            if (cd.col_type = 'INT') then
              if TryStrToInt(cd.defval, l) then
                R.fields[i].asInteger := l;
            if (cd.col_type = 'DECIMAL') then
              if TryStrTofloat(cd.defval, f) then
                R.fields[i].AsFloat := f;
          end;
        end;
      end;
    end;
    Result := dber_none;
  except
    on E: Exception do
    begin
      Error(e, dber_sql, '');
      Result := dber_sql;
    end;
  end;
  MainForm.setMicroHelp(rs_ready,0);
  Screen.Cursor := crDefault;
end;

procedure TDA_table.setCrc(R : TDataSet);

var c : longint;
    F : tfield;

begin
     if R.RecordCount>0 then
     begin
         try
           try
             F:=R.Fields.FindField('SY_CRC');
             if assigned(F) then
             begin
               c:=getCrc(R);
               F.AsInteger:=c;
             end;
             F:=R.Fields.FindField('SY_LASTUSER');
             if assigned(F) then
             begin
               F.AsString:=MainForm.username;
             end;
             F:=R.Fields.FindField('SY_ROWVERSION');
             if assigned(F) then
             begin
               F.AsDateTime:=now;
             end;
           except
             on E: Exception do Error(e, dber_sql, 'TDA_table.setCrc');
           end;
         finally

         end;
     end;
end;

function TDA_table.setDefault(R : TDataset) : boolean;

var i : integer;
     s,fname : shortstring;
     cd: TColumnDesc;

begin
   assert(assigned(R), 'Query not assigned');
   assert(R.RecordCount <= 1, 'Just one update allowed');
   result:=true;
   try
     for i := 0 to R.FieldCount - 1 do
     begin
       fname := R.fields[i].FieldName.ToUpper;
       if fname > '' then
       begin
         cd:=nil;
         cd := Maindata.tablesdesc.Find(table, fname);
         assert(assigned(cd), 'Field description ' + fname + ' not found. cd not assigned.');
         assert(cd.col_name = fname, 'Field description ' + fname + ' not found.');
         if cd.col_name='SY_CODE' then
         begin
                s:=codeCalc(R);
                if R.Fields[i].AsString <> s then
                begin
                  if not R.canModify then R.Edit;
                  R.fields[i].asString:=s;
                end;
         end;
       end;
     end;
   except
     on E: Exception do
     begin
       Error(e, dber_sql, 'TDA_table.setDefault '+table);
     end;
   end;
end;

function TDA_table.setID(R : TDataSet) : boolean;

var l_id : longint;
    F : Tfield;

begin
  assert(assigned(R),'Dataset not assigned');
  assert(assigned(R.Fields.FindField('SY_ID')),'No SY_ID field');
  result:=false;
  try
    F:=R.Fields.FindField('SY_ID');
    F.AsLongint:=1;
    if assigned(F) then
    begin
         l_id:=getNextId();
         if l_id>0 then
         begin
              F.AsLongint:=l_id;
              result:=true;
         end;
    end;
  except
    on E: Exception do Error(e, dber_sql, 'TDA_table.setID '+table);
  end;
end;

function TDA_table.normalize ( s : string) : string;

var i : integer;
    c : String;

begin
  result:='';
  for i := 1 to UTF8Length(s) do
  begin
     c := UTF8copy(s,i,1);
     if c > 'z' then
     begin
       if (c='À') or (c='Á') or (c='Â') or (c='Ã') or (c='Ä') or (c='Å') or (c='Æ') then c:='A' else
       if (c='à') or (c='á') or (c='â') or (c='ã') or (c='ä') or (c='å') or (c='æ') then c:='a' else
       if (c='ß') then c:='B' else
       if (c='Ç') then c:='C' else
       if (c='ç') then c:='c' else
       if (c='Ð') then c:='D' else
       if (c='ð') then c:='d' else
       if (c='È') or (c='É') or (c='Ê') or (c='Ë') then c:='E' else
       if (c='è') or (c='é') or (c='ê') or (c='ë') then c:='e' else
       if (c='Ì') or (c='Í') or (c='Î') or (c='Ï') then c:='I' else
       if (c='ì') or (c='í') or (c='î') or (c='ï') then c:='i' else
       if (c='Ñ') then c:='N' else
       if (c='ñ') then c:='n' else
       if (c='Ò') or (c='Ó') or (c='Ô') or (c='Õ') or (c='Ö') or (c='Œ') or (c='Ø') then c:='O' else
       if (c='ò') or (c='ó') or (c='ô') or (c='õ') or (c='ö') or (c='œ') or (c='ø') then c:='o' else
       if (c='Ù') or (c='Ú') or (c='Û') or (c='Ü') then c:='U' else
       if (c='ù') or (c='ú') or (c='û') or (c='ü') then c:='u' else
       if (c='Ý') or (c='Ÿ') then c:='Y' else
       if (c='ý') or (c='ÿ') then c:='y' else
       c:=' ';
     end;
     if c<'0' then c:=' ';
     result:=result+c;
  end;
end;

// https://wiki.freepascal.org/Databases
function TDA_table.Write(R: TDataSet; var id: longint; mode : Tupdate_mode = um_read): TDbErrcode;

var
  ncrc: longint;
  testcrc: longint;
  oldcrc: longint;
  testrowversion : tdatetime;
  oldrowversion : tdatetime;
  testolduser : shortstring;
  olduser : shortstring;
  i, nbwherecrc: integer;
  squerycrc: string;
  reselect: string;
  nbreselect: integer;
  cd: TColumnDesc;
  nom, o, n: string;
  Querycrc: TDataSet;
  st: TUpdateStatus;

begin
  assert(assigned(R), 'Query not assigned');
  assert((R is TSqlQuery) or (R is TZquery),'Invalid dataset type');
  assert(R.RecordCount <= 1, 'Just one update allowed');
  MainForm.setMicroHelp(rs_write+' ['+table+'] : '+inttostr(id));
  Result := cber_nothing;
  if not MainData.isConnected then exit;
  if not R.Active then  exit;
  if R.FieldCount = 0 then exit;
  Screen.Cursor := crHourGlass;

  id:=R.FieldByName('SY_ID').AsInteger;
  R.Edit;
  if not setDefault(R) then
  begin
       Screen.Cursor := crDefault;
       exit;
  end;
  apply_style(R, st);
  setCrc(R);
  ncrc := getcrc(R);
  if not Modified(R) then
  begin
       Screen.Cursor := crDefault;
       R.Cancel;
       R.Refresh;
       exit;
  end;
  if (mode<>um_create) and (not ConcurrencyControl(R)) then
  begin
    R.Close;
    R.open;
    raise TCrcException.Create(table + ' ' + IntToStr(id)+' User : '+testolduser+' Date :'+dateTostr(testrowversion));
    exit;
  end;
  IF mode=um_create then
  begin
    if not setID(R) then
    begin
      Screen.Cursor := crDefault;
      exit;
    end;
  end;

  try
    Result := dber_sql;
    if MainData.WriteDataSet(R,'TDA_table.Write '+table) then
    begin
         Result := dber_none;
    end else
    begin
      exit;
    end;
  except
    on E: Exception do
    begin
      Error(e, dber_sql, '');
      Result := dber_sql;
      exit;
    end;
  end;

  // todo : en cas d'insertion, récupérer la clé SY_ID

  if not (st in [usDeleted]) then Read(R,id);

  Result := dber_none;
  MainForm.setMicroHelp(rs_ready,0);
  Screen.Cursor := crDefault;
end;


function TDA_table.Test(R: TDataSet; action: char; var nbwarnings, nberr: integer;
  var msg: string): boolean;

var
  i: integer;
  nom: string;
  ret: boolean;
  cd: TColumnDesc;

begin
  assert(assigned(R), 'Requête non assignée');
  assert(table > '', 'Table non renseignée');
  ret := True;
  if R.modified then
  begin
    for i := 0 to R.FieldCount - 1 do
    begin
      nom := R.fields[i].FieldName;
      if nom > '' then
      begin
        cd := Maindata.tablesdesc.Find(table, nom);
        assert(assigned(cd), 'Description du champ ' + nom + ' non trouvée');
        assert(cd.col_name = nom, 'Description du champ ' + nom + ' non trouvée');


        if nom = 'SY_CRC' then
        begin
          R.fields[i].newvalue := getcrc(R);
        end;
        {if o <> n then
        begin
          if (n = '') and (not cd.nullable) then
          begin
            msg := msg + 'Le champ "' + cd.nom_externe +
              '" doit être renseigné.' + sLineBreak;
            ret := False;
          end;
        end;  }
      end;
    end;
  end;
  Test := ret;
end;

end.

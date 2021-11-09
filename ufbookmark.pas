unit UFbookmark;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  Buttons, EditBtn, ActnList,
  Grids,  VirtualTrees, DB,
  SQLDB, DataAccess, Types;

type


  TBM = class
        code : integer;
        parent : integer;
        libelle : shortstring;

        constructor create(c,p : integer; l : shortstring);

  end;

  { TFBookmark }

  TFBookmark = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Btn_new: TButton;
    Button2: TButton;
    Button4: TButton;
    CB_gridshape: TComboBox;
    CB_gridcolor: TComboBox;
    DrawGrid3: TDrawGrid;
    Edit1: TEdit;
    GroupBox1: TGroupBox;
    Lb_name: TLabel;
    PC_tab: TPageControl;
    TS_labels: TTabSheet;
    TS_stickers: TTabSheet;
    Ts_bookmark: TTabSheet;
    TreeView1: TTreeView;
    procedure Btn_newClick(Sender: TObject);
    procedure CB_gridcolorDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);

    procedure CB_gridshapeDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure ComboBoxEx2Change(Sender: TObject);
    procedure DrawGrid3SelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure GroupBox1Click(Sender: TObject);
    procedure Lb_nameClick(Sender: TObject);
    procedure TreeView1DblClick(Sender: TObject);
    procedure TreeView1Deletion(Sender: TObject; Node: TTreeNode);
    procedure TreeView1EditingEnd(Sender: TObject; Node: TTreeNode;
      Cancel: Boolean);
    procedure TreeView1Expanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure TS_stickersContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
  private
         load : boolean;
         procedure LoadBMDir(Node: TTreeNode);
  public

  end;

implementation

uses Main,LWData,UException,RessourcesStrings;

{$R *.lfm}

{
0, "Aucune", 255, 255, 255,
1, "Rose", 255, 192, 203,
2, "Rose clair", 255, 182, 193,
3, "Rose Passion", 255, 105, 180,
4, "Rose profond", 255, 20, 147,
5, "Violet pâle", 219, 112, 147,
6, "Fushia (Magenta)", 255, 0, 255,
7, "Violet moyen", 199, 21, 133,
8, "Violet chardon", 216, 191, 216,
9, "Prune", 221, 160, 221,
10, "Violet", 238, 130, 238,
11, "Violet orchidée", 218, 112, 214,
12, "Violet orchidée moyen", 186, 85, 211,
13, "Violet orchidée foncé", 153, 50, 204,
14, "Violet foncé", 148, 0, 211,
15, "Bleu violet", 138, 43, 226,
16, "Indigo", 75, 0, 130,
17, "Bleu ardoise moyen", 123, 104, 238,
18, "Bleu ardoise", 106, 90, 205,
19, "Bleu ardoise foncé", 72, 61, 139,
20, "Pourpre moyen", 147, 112, 219,
21, "Magenta foncé", 139, 0, 139,
22, "Pourpre", 128, 0, 128,
23, "Brun rosé", 188, 143, 143,
24, "Corail clair", 240, 128, 128,
25, "Corail", 255, 127, 80,
26, "Tomate", 255, 99, 71,
27, "Orangé", 255, 69, 0,
28, "Rouge", 255, 0, 0,
29, "Rouge cramoisi", 220, 20, 60,
30, "Saumon clair", 255, 160, 122,
31, "Saumon Foncé", 233, 150, 122,
32, "Saumon", 250, 128, 114,
33, "Rouge Indien", 205, 92, 92,
34, "Rouge brique", 178, 34, 34,
35, "Brun", 165, 42, 42,
36, "Rouge foncé", 139, 0, 0,
37, "Bordeaux", 128, 0, 0,
38, "Beige", 245, 245, 220,
39, "Beige antique", 250, 235, 215,
40, "Beige papaye", 255, 239, 213,
41, "Amande", 255, 235, 205,
42, "Bisque", 255, 228, 196,
43, "Beige pêche", 255, 218, 185,
44, "Beige mocassin", 255, 228, 181,
45, "Jaune blanc navaro", 255, 222, 173,
46, "Jaune blé", 245, 222, 179,
47, "Brun bois rustique", 222, 184, 135,
48, "Brun roux", 210, 180, 140,
49, "Brun sable", 244, 164, 96,
50, "Orange", 255, 165, 0,
51, "Orange foncé", 255, 140, 0,
52, "Chocolat", 210, 105, 30,
53, "Brun pérou", 205, 133, 63,
54, "Terre de Sienne", 160, 82, 45,
55, "Brun cuir", 139, 69, 19,
56, "Jaune clair", 255, 255, 224,
57, "Jaune maïs doux", 255, 248, 220,
58, "Jaune doré clair", 250, 250, 210,
59, "Beige citron soie", 255, 250, 205,
60, "Jaune doré pâle", 238, 232, 170,
61, "Brun kaki", 240, 230, 140,
62, "Jaune", 255, 255, 0,
63, "Or", 255, 215, 0,
64, "Jaune doré", 218, 165, 32,
65, "Jaune doré foncé", 184, 134, 11,
66, "Brun kaki foncé", 189, 183, 107,
67, "Jaune vert", 154, 205, 50,
68, "Kaki", 107, 142, 35,
69, "Olive", 128, 128, 0,
70, "Vert olive foncé", 85, 107, 47,
71, "Vert jaune", 173, 255, 47,
72, "Chartreuse", 127, 255, 0,
73, "Vert prairie", 124, 252, 0,
74, "Citron vert", 0, 255, 0,
75, "Citron vert foncé", 50, 205, 50,
76, "Blanc menthe", 245, 255, 250,
77, "Miellat", 240, 255, 240,
78, "Vert pâle", 152, 251, 152,
79, "Vert clair", 144, 238, 144,
80, "Vert printemps", 0, 255, 127,
81, "Vert printemps moyen", 0, 250, 154,
82, "Vert forêt", 34, 139, 34,
83, "Vert", 0, 128, 0,
84, "Vert foncé", 0, 100, 0,
85, "Vert océan foncé", 143, 188, 143,
86, "Vert océan moyen", 60, 179, 113,
87, "Vert océan", 46, 139, 87,
88, "Gris ardoise clair", 119, 136, 153,
89, "Gris ardoise", 112, 128, 144,
90, "Gris ardoise foncé", 47, 79, 79,
91, "Bleu alice", 240, 248, 255,
92, "Bleu azur", 240, 255, 255,
93, "Cyan clair", 224, 255, 255,
94, "Azurin", 175, 238, 238,
95, "Aigue-marine", 127, 255, 212,
96, "Aigue-marine moyen", 102, 205, 170,
97, "Cyan", 0, 255, 255,
98, "Turquoise", 64, 224, 208,
99, "Turquoise moyen", 72, 209, 204,
100, "Turquoise foncé", 0, 206, 209,
101, "Vert marin clair", 32, 178, 170,
102, "Cyan foncé", 0, 139, 139,
103, "Vert sarcelle", 0, 128, 128,
104, "Bleu pétrole", 95, 158, 160,
105, "Bleu poudre", 176, 224, 230,
106, "Bleu clair", 173, 216, 230,
107, "Bleu azur clair", 135, 206, 250,
108, "Bleu azur", 135, 206, 235,
109, "Bleu azur profond", 0, 191, 255,
110, "Bleu toile", 30, 144, 255,
111, "Bleu lavande", 230, 230, 250,
112, "Bleu acier clair", 176, 196, 222,
113, "Bleuet", 100, 149, 237,
114, "Bleu acier", 70, 130, 180,
115, "Bleu royal", 65, 105, 225,
116, "Bleu", 0, 0, 255,
117, "Bleu moyen", 0, 0, 205,
118, "Bleu foncé", 0, 0, 139,
119, "Bleu marin", 0, 0, 128,
120, "Bleu de minuit", 25, 25, 112, )
}

{
Blanc
Silver  gris argent	    #C0C0C0 	rgb(192, 192, 192)
Gray 	gris        #808080 	rgb(128, 128, 128)
Black 	noir        #000000 	rgb(0, 0, 0)
Red 	rouge       #FF0000 	rgb(255, 0, 0)
Pink    rose        #FFC0CB     rgb(255,192,203)
Orange  Orange      #FFA500     rgb(255,165,0)
Maroon 	Bordeaux      #800000 	rgb(128, 0, 0)
Yellow 	jaune       #FFFF00 	rgb(255, 255, 0)
Olive 	olive       #808000 	rgb(128, 128, 0)
Lime 	citron vert #00FF00 	rgb(0, 255, 0)
Green 	vert        #008000 	rgb(0, 128, 0)
Aqua 	bleu vert   #00FFFF 	rgb(0, 255, 255)
Teal 	vert pétrole #008080 	rgb(0, 128, 128)
Blue 	bleu          #0000FF 	rgb(0, 0, 255)
Navy 	bleu marin   #000080 	rgb(0, 0, 128)
Fuchsia fuchsia       #FF00FF 	rgb(255, 0, 255)
Purple 	violet        #800080 	rgb(128, 0, 128)
}

constructor TBM.create(c,p : integer; l : shortstring);

begin
     code:=c;
     parent:=p;
     libelle:=l;
end;

{ TFBookmark }

procedure TFBookmark.Btn_newClick(Sender: TObject);

var anode,new : TTreeNode;
    h, p : TBM;

begin
     anode:=TreeView1.Selected;
     if assigned(anode) then
     begin
         p:=TBM(anode.data);
         h:=TBM.create(-1,p.code,rs_new);
         load:=false;
         anode.Expand(false);
         new:=TreeView1.Items.AddChildObject(anode,rs_new,h);
         treeview1.Selected:=new;
         new.Focused:=true;
         new.EditText;
         load:=true;
     end;
end;

procedure TFBookmark.CB_gridcolorDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);

var r : Trect;

begin
   with Control as Tcombobox do
   begin
           Canvas.Font.Color := clBlack;
           Canvas.Brush.Color := clWhite ;
           Canvas.FillRect(aRect);
           Canvas.Brush.Color := clBlack ;
           Canvas.AntialiasingMode:=amOn;

           case index of
                0 : Canvas.Brush.Color:=clWhite;                // White
                1 : Canvas.Brush.Color:=rgbTocolor(192,192,192);// Silver
                2 : Canvas.Brush.Color:=rgbTocolor(128,128,128);// Gray
                3 : Canvas.Brush.Color:=rgbTocolor(0,0,0);      // Black
                4 : Canvas.Brush.Color:=rgbTocolor(255,0,0);    // Red
                5 : Canvas.Brush.Color:=rgbTocolor(255,192,203);// Pink
                6 : Canvas.Brush.Color:=rgbTocolor(255,165,0);  // Orange
                7 : Canvas.Brush.Color:=rgbTocolor(128,0,0);    // Maroon
                8 : Canvas.Brush.Color:=rgbTocolor(255,255,0);  // Yellow
                9 : Canvas.Brush.Color:=rgbTocolor(128,128,0);  // Olive
               10 : Canvas.Brush.Color:=rgbTocolor(0,255,0);    // Lime
               11 : Canvas.Brush.Color:=rgbTocolor(0,128,0);    // Green
               12 : Canvas.Brush.Color:=rgbTocolor(0,255,255);  // Aqua
               13 : Canvas.Brush.Color:=rgbTocolor(0,128,128);  // Teal
               14 : Canvas.Brush.Color:=rgbTocolor(0,0,255);    // Blue
               15 : Canvas.Brush.Color:=rgbTocolor(0,0,128);    // Navy
               16 : Canvas.Brush.Color:=rgbTocolor(255,0,255);  // Fuchsia
               17 : Canvas.Brush.Color:=rgbTocolor(238,130,238);// Purple

           end;
           r:=arect;
           r.Width:=40;
           Canvas.FillRect(r);

           Canvas.Brush.Color := clWhite ;
           Canvas.TextOut(aRect.Left+50, aRect.Top, Items[Index])
   end;
end;


procedure TFBookmark.CB_gridshapeDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);

begin
     with Control as Tcombobox do
     begin
        Canvas.Font.Color := clBlack;
        Canvas.Brush.Color := clWhite ;
        Canvas.FillRect(aRect);
        Canvas.Brush.Color := clBlack ;
        Canvas.AntialiasingMode:=amOn;

        if index=0 then Canvas.Ellipse(arect.left+2,arect.top+1,arect.left+14,arect.top+13);
        if index=1 then Canvas.FillRect(arect.left+2,arect.top+1,arect.left+14,arect.top+13);

        Canvas.Brush.Color := clWhite ;
        Canvas.TextOut(aRect.Left+50, aRect.Top, Items[Index])
    end;
end;

procedure TFBookmark.ComboBoxEx2Change(Sender: TObject);
begin

end;


procedure TFBookmark.DrawGrid3SelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);

var crect: TRect;

begin
    if acol<=2 then
    begin
        crect := DrawGrid3.CellRect(ACol, ARow);
        if acol=1 then
        begin
            CB_GridColor.visible:=false;
            CB_GridShape.visible:=true;
            CB_GridShape.top:=DrawGrid3.top + crect.top + 2;
            CB_GridShape.left:=DrawGrid3.left + crect.left + 2;
            CB_GridShape.width:=crect.Right - crect.left;
            CB_GridShape.height:=crect.bottom - crect.top;
        end else
        begin
             CB_GridShape.visible:=false;
             CB_GridColor.visible:=true;
             CB_GridColor.top:=DrawGrid3.top + crect.top + 2;
             CB_GridColor.left:=DrawGrid3.left + crect.left + 2;
             CB_GridColor.width:=crect.Right - crect.left;
             CB_GridColor.height:=crect.bottom - crect.top;
        end;
       { GridCombo.Top := ProjGrid.Top + crect.Top + 2;
        GridCombo.Left := ProjGrid.Left + crect.Left + 2;
        GridCombo.Width := crect.Right - crect.Left;
        GridCombo.ItemIndex := GridCombo.Items.IndexOf(ProjGrid.Cells[ACol,
        ARow]);
        GridCombo.Visible := True;
        end
        else
        GridCombo.Visible := False;}
    end else
    begin
         Canselect:=false;
         CB_GridShape.visible:=false;
         CB_GridColor.Visible:=false;
    end;
end;

procedure TFBookmark.FormCreate(Sender: TObject);
begin
     load:=true;
     PC_tab.ActivePageIndex:=0;
     LoadBMDir(nil);
end;

procedure TFBookmark.GroupBox1Click(Sender: TObject);
begin

end;

procedure TFBookmark.Lb_nameClick(Sender: TObject);
begin

end;

procedure TFBookmark.TreeView1DblClick(Sender: TObject);

var anode : TTreeNode;
    p : TBM;

begin
     anode:=TreeView1.Selected;
     if assigned(anode) then
     begin
          p:=TBM(anode.data);
          if p.parent>0 then
          begin
               anode.EditText;
          end;
     end;
end;

procedure TFBookmark.TreeView1Deletion(Sender: TObject; Node: TTreeNode);
begin
  if assigned(Node.Data) then
  begin
      try
        try
           TBM(Node.Data).Free;
        except
           on E: Exception do
              Error(E, dber_none, 'TFBookmark.TreeView1Deletion(Sender, Node)');
        end;
      finally
        Node.Data := nil;
      end;
  end;
end;

procedure TFBookmark.TreeView1EditingEnd(Sender: TObject; Node: TTreeNode; Cancel: Boolean);

var p : TBM;
    Q : Tsqlquery;
    id : longint;
    sql : string;
    t : shortstring;

begin
     if assigned(node) then
     begin
          p:=TBM(node.data);
          id:=p.code;
          t:=node.Text;
          if t<='' then t:=rs_new;
          if p.parent>0 then
          begin
               Q:=TSQLQuery.create(Mainform);
               Q.DataBase:=MainData.Database;
               Q.transaction:=MainData.tran;
               if p.code<=0 then
               begin
                    sql:=Maindata.getQuery('Q0002','SELECT MAX(ID) FROM LWH_BKDIR');
                    Q.SQL.Text:=sql;
                    Q.open;
                    if Q.RecordCount>0 then
                    BEGIN
                         if q.fields[0].IsNull then
                         begin
                             id:=1;
                         end else id:=Q.fields[0].AsInteger;
                         inc(id);
                    END;
                    if id<2 then id:=2;
                    Q.Close;
                    sql:=Maindata.getQuery('Q0003','INSERT INTO LWH_BKDIR(ID,PARENTBM,CAPTION,LASTUSER, ROWVERSION) VALUES (%id, %p, ''%c'', ''%u'',''%ts'')');
                    sql:=sql.replace('%id%',inttostr(id));
                    sql:=sql.replace('%p',inttostr(p.parent));
                    sql:=sql.replace('%c',t);
                    sql:=sql.replace('%u',Mainform.username);
                    sql:=sql.replace('%ts',Maindata.getTimestamp);


                    Q.SQL.text:=sql;
                    Q.ExecSQL;
                    TSqlTransaction(Q.transaction).Commit;
                    Q.close;
               end else
               begin
                    id:=p.code;
                    sql:=Maindata.getQuery('Q0007','UPDATE LWH_BKDIR SET CAPTION=''%c'', LASTUSER=''%u'', ROWVERSION=''%ts'' WHERE ID=%id)');
                    sql:=sql.replace('%id',inttostr(id));
                    sql:=sql.replace('%ts',Maindata.getTimestamp);
                    sql:=sql.replace('%c',t);
                    sql:=sql.replace('%u',Mainform.username);


                    Q.SQL.text:=sql;
                    Q.ExecSQL;
                    TSqlTransaction(Q.transaction).Commit;
                    Q.close;
               end;
               p.code:=id;
               p.libelle:=t;
               Q.Free;
          end;
     end;
end;

procedure TFBookmark.TreeView1Expanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
begin
     AllowExpansion := True;
     if not load then exit;
     if Assigned(Node.Data) then
     begin
          LoadBMDir(Node);
     end;
end;

procedure TFBookmark.TS_stickersContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin

end;

procedure TFBookmark.LoadBMDir(Node: TTreeNode);

var
  root,anode: TTreeNode;
  Q : TDataSet;
  sql : string;
  h : TBM;
  id : longint;

begin
     Q:=nil;
     try
       try
         Screen.Cursor := crHourGlass;
         if assigned(node) then
         begin
              node.DeleteChildren;
              if assigned(node.Data) then
              begin
                  h:= TBM(Node.Data);
                  sql:=Maindata.getQuery('Q0005','SELECT ID,PARENTBM,CAPTION, LASTUSER, ROWVERSION FROM LWH_BKDIR WHERE PARENTBM = %p ORDER BY ID ASC');
                  sql:=sql.Replace('%p',inttostr(h.code));
                  MainData.readDataSet(Q,sql,true);
                  if Q.RecordCount>0 then
                  BEGIN
                      Q.First;
                      WHILE (NOT Q.EOF) DO
                      BEGIN
                           h:=TBM.create(Q.Fields[0].AsInteger, Q.Fields[1].AsInteger,Q.fields[2].AsString);
                           Anode:=TreeView1.Items.AddChildObject(Node,Q.fields[2].AsString,h);
                           Anode.HasChildren:=true;
                           Q.Next;
                      END;
                  END ELSE
                  BEGIN
                       node.HasChildren:=false;
                  END;
                  Q.close;
              end;
         end else
         begin
              // If there is no root folder, it must be created. ID = 0, parent=null
              sql:=Maindata.getQuery('Q0011','INSERT OR REPLACE INTO LWH_BKDIR(ID,PARENTBM,CAPTION,LASTUSER, ROWVERSION) VALUES (%id, %p, ''%c'', ''%u'',''%ts'');');
              sql:=sql.Replace('%id','0');
              sql:=sql.Replace('%p','null');
              sql:=sql.Replace('%c','.');
              sql:=sql.replace('%u',Mainform.username);
              sql:=sql.replace('%ts',Maindata.getTimestamp);
              MainData.doScript(sql);


              // Global bookmark. ID = 1, parent=0
              sql:=Maindata.getQuery('Q0011','INSERT OR REPLACE INTO LWH_BKDIR(ID,PARENTBM,CAPTION,LASTUSER, ROWVERSION) VALUES (%id, %p, ''.'', ''%u'',''%ts'');');
              sql:=sql.Replace('%id','1');
              sql:=sql.Replace('%p','0');
              sql:=sql.Replace('%c',rs_bookmarkg);
              sql:=sql.replace('%u',Mainform.username);
              sql:=sql.replace('%ts',Maindata.getTimestamp);
              MainData.doScript(sql);

              //todo : lwh-personnal bookmark root
            {  id:=1;
              sql:=Maindata.getQuery('Q0002','SELECT MAX(ID) FROM LWH_BKDIR');
              MainData.readDataSet(Q,sql,true);
              if Q.RecordCount>0 then
              BEGIN
                   Q.First;
                   id:=Q.Fields[0].AsInteger;
                   inc(id);
                   sql:=Maindata.getQuery('Q0011','INSERT OR REPLACE INTO LWH_BKDIR(ID,PARENTBM,CAPTION,LASTUSER, ROWVERSION) VALUES (%id, %p, '.', ''%u'',''%ts'');');
                   sql:=sql.Replace('%id',inttostr(id));
                   sql:=sql.Replace('%p','0');
                   sql:=sql.Replace('%c','['+Mainform.username+']');
                   sql:=sql.replace('%u',Mainform.username);
                   sql:=sql.replace('%ts',Maindata.getTimestamp);
                   MainData.doScript(sql);
              END;
              // Personal bookmark. caption = '[' + username + ']'
              sql:=Maindata.getQuery('Q0011','INSERT OR REPLACE INTO LWH_BKDIR(ID,PARENTBM,CAPTION,LASTUSER, ROWVERSION) VALUES (%id, %p, '.', ''%u'',''%ts'');');
              sql:=sql.Replace('%id','?');
              sql:=sql.Replace('%p','0');
              sql:=sql.Replace('%c','['+Mainform.username+']');
              sql:=sql.replace('%u',Mainform.username);
              sql:=sql.replace('%ts',Maindata.getTimestamp);
              MainData.doScript(sql);

              sql:=Maindata.getQuery('Q0001','SELECT ID FROM LWH_BKDIR WHERE PARENTBM = %p AND CAPTION=''%c''');
              sql:=sql.Replace('%p','0');
              sql:=sql.Replace('%c','['+Mainform.username+']');
              MainData.readDataSet(Q,sql,true);
              ID:=-1;
              if Q.RecordCount>0 then
              begin
                   SQL:=q.Fields[0].Name;
                   id:=Q.Fields[0].AsInteger;
              end else
              begin }
                   {Q.close;
                   sql:=Maindata.getQuery('Q0002','SELECT MAX(ID) FROM LWH_BKDIR');
                   Q.SQL.Text:=sql;
                   Q.open;
                   if Q.RecordCount>0 then
                   BEGIN
                        if q.Fields[0].IsNull then
                        begin
                             id:=2;
                        end else
                        begin
                             id:=Q.fields[0].AsInteger;
                             id:=id + 1;
                        end;
                   END ELSE
                   BEGIN
                        id:=2;
                   END;
                   Q.close;
                   sql:=Maindata.getQuery('Q0003','INSERT INTO LWH_BKDIR(ID,PARENTBM,CAPTION,LASTUSER, ROWVERSION) VALUES (%id, %p, ''%c'', ''%u'',''%ts'')');
                   sql:=sql.replace('%id',inttostr(id));
                   sql:=sql.replace('%p','0');
                   sql:=sql.replace('%c','['+Mainform.username+']');
                   sql:=sql.replace('%u',Mainform.username);
                   sql:=sql.replace('%ts',Maindata.getTimestamp);
                   Q.SQL.text:=sql;
                   Q.ExecSQL;
                   TSqlTransaction(Q.transaction).Commit; }
              end;
              //Q.close;

              h:=TBM.create(id,0,rs_bookmark+' '+Mainform.username);
              root:= TreeView1.Items.AddObject(nil,rs_bookmark+' '+Mainform.username,h);
              root.HasChildren:=true;
       except
          on E: Exception do
             Error(E, dber_none, 'TFBookmark.LoadBMDir(Node: TTreeNode) '+sql);
       end;
     finally
       if assigned(Q) then
       begin
            Q.close;
            Q.free;
       end;
       Screen.Cursor := crDefault;
     end;
end;

end.


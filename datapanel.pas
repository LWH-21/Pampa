unit DataPanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,Types,typinfo,
  RessourcesStrings,
  DataAccess, DB,LWData,SQLDB,
  Controls, Dialogs, DBCtrls, ExtCtrls, Forms, Menus,StdCtrls, Graphics,FPImage,
  Buttons, GR32,GR32_Image,LCLType,
  Generics.Collections,Generics.Defaults,
  fpjson,jsonparser;

type


TSizeMode =  (sm_none, sm_move, sm_left, sm_right, sm_top, sm_bottom);

TLWControlType = (lwct_none,lwct_column, lwct_label, lwct_button, lwct_flag);

TLWStyleItem = class
  code : Shortstring;
  Libelle  : ShortString;

  constructor create(c : shortstring);

end;

TLWControl = class
           aparent : TWinControl;
           ctrlType : TLWControlType;
           name : string;
           tablename : shortstring;
           currentstyle : string;
           ctrl : Tcontrol;
           def  : TColumnDesc;
           left, top, height, width : integer;
           taborder : integer;
           caption : string;
           hint : string;
           showhint : boolean;
           selected : boolean;
           selorder : integer;
           zoom     : integer;

           Datasource : TDataSource;
           OnMouseMove: TMethod;
           OnMouseDown : TMethod;
           OnEnter: TMethod;
public
           constructor create (aOwner : TWinControl; code : TJSONObject; src : TDataSource; tname : shortstring);
           constructor create (aOwner : TWinControl; kind : TLWControlType; src : TDataSource; tname : shortstring);
           function getBounds : Trect;
           function getSizeMode(x, y : integer) :  TSizeMode;
           procedure paint(cv : Tcanvas);

           procedure resize(m : TSizeMode; val : integer);

           procedure setField(c : TColumnDesc);
           procedure setSField(s : Shortstring);


           procedure SetOnEnter( M : Tmethod);
           procedure SetOnMouseDown(M : TMethod);

           procedure setPosX(x : integer);
           procedure setPosY(y : integer);
           procedure setHeight(h : integer);
           procedure setWidth(w : integer);
           procedure setCaption(c : string);
           procedure setHint(c : string);
           procedure setTaborder(t : integer);
           procedure setSelected(s : boolean; o : integer = -1);
           procedure setZoom(z : integer);
           procedure refresh;

           destructor destroy;override;

end;

Tdico = specialize TObjectDictionary <string,TLWControl>;

TDataPanel = class(TScrollBox)
  private

          DataSource : TDataSource;
          DesignMode : boolean;
          FPrarentClose : TCloseEvent;
          Json : TJSONData;
          oldMousePos : Tpoint;
          selnum : integer;
          sizemode : TsizeMode;
          winpa : TWinControl;

//          FOnsave : TSave;
   protected

   public
             ColumnDesc : TTableDesc;
             CtrlList : Tdico;
             nbsel  : integer;
             TableName : string;



             constructor create(AOwner: TComponent; aname : shortstring);

             procedure add_ctrl(n : shortstring; x,y : integer);
             procedure align(D : char);
             procedure CalcZOrder;
             procedure Ctrl_Enter(Sender: TObject);
             procedure Ctrl_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
             procedure DeleteControls;
             procedure DragDrop(Sender, Source: TObject; X, Y: Integer);
             procedure DragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
             procedure GenerateJson;
             function GetDesignMode : boolean;
             function  GetInternalName : string;
             procedure init(u : ShortString);
             procedure KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
             procedure MouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);
             procedure MouseMove(Sender: TObject;Shift: TShiftState; X: Integer; Y: Integer);
             procedure NotifyChange;
             procedure onFocus(Sender: TObject);
             procedure paint(Sender: TObject);
             procedure save;
             procedure setColor(c : Tcolor);
             procedure SetDataSource(s : TDataSource; tname : shortstring);
             Procedure SetDesign(d : boolean);
             procedure SetDesignMode(Sender : Tobject);
             procedure SetJson(s : string);
             Procedure SetNbSel(n : integer);
             procedure setTable(tname : string; CDesc : TTableDesc);
             procedure setZoom(z : integer);
             procedure showinterface(s : boolean);
             destructor Destroy; override;


   published

   end;

implementation


uses UFCustomDP, Main;


constructor TLWStyleItem.create(c : shortstring);

begin
  code:=c;
  if c='CA' then libelle:='Calendar' else
  if c='CB' then libelle:='CheckBox' else
  if c='ED' then libelle:='Edit' else
  if c='EM' then libelle:='EditMask' else
  if c='LB' then libelle:='ListBox' else
  if c='ME' then libelle:='Memo' else
  if c='RB' then libelle:='RadioButton' else
  libelle:=c;
end;

constructor TLWControl.create (aOwner : TWinControl; code : TJSONObject; src : TDataSource; tname : shortstring);

var lclassname : shortstring;
    index,n : integer;
    val : shortstring;
    col : Tcolumndesc;

begin
  lclassname:=uppercase(code.Strings['CLASS']);
  zoom:=100;
  name:=uppercase(code.Strings['NAME']);
  aparent:=aOwner;
  tablename:=tname;
  if lclassname='TBITBTN' then ctrltype:=lwct_button;
  if lclassname='TDBEDIT' then ctrltype:=lwct_column;
  if (lclassname='TSTATICTEXT') or (lclassname='TLABEL') then ctrltype:=lwct_label;
  case ctrltype of
          lwct_column :
          begin
            ctrl:=TDBEdit.create(aOwner);
            (ctrl as TDBEdit).ReadOnly:=false;
          end;
          lwct_label :
          begin
            ctrl:=TLabel.create(aOwner);
            TLabel(ctrl).Caption:='- - - ';
            ctrl.Color:=clNone;
          end;
          lwct_button:
          begin
            ctrl:=TBitBtn.CREATE(aOwner);
            ctrl.Parent:=aOwner;
            setCaption('??');
          end;
  end;
  width:=100;
  height:=23;
  datasource:=src;
  if assigned(ctrl) then
  begin
          ctrl.name:=name;
          ctrl.parent:=aOwner;
          ctrl.Left:=0;ctrl.top:=0;ctrl.width:=100;ctrl.height:=23;
          ctrl.AutoSize:=false;
  end;
  selected:=false;

  index:=code.indexOfName('LEFT');
  if index>=0 then
  begin
          if not TryStrToInt(code.Items[index].asstring,n) then n:=100;
          setPosX(n);
   end;
   index:=code.indexOfName('TOP');
   if index>=0 then
   begin
        if not TryStrToInt(code.Items[index].asstring,n) then n:=100;
        setPosY(n);
   end;
   index:=code.indexOfName('WIDTH');
   if index>=0 then
   begin
       if not TryStrToInt(code.Items[index].asstring,n) then n:=100;
       setWidth(n);
   end;
   index:=code.indexOfName('HEIGHT');
   if index>=0 then
   begin
        if not TryStrToInt(code.Items[index].asstring,n) then n:=100;
        setHeight(n);
   end;
   index:=code.indexOfName('HINT');
   if index>=0 then
   begin
        if code.Items[index].asstring>' ' then
        begin
            setHint(code.Items[index].asstring);
        end;
   end;
   index:=code.indexOfName('FIELD');
   if index>=0 then
   begin
        val:=code.Items[index].asstring;
        {todo : lwh à virer
        IF val='ID' then val:='SY_ID';
        if val='LASTNAME' then val:='SY_LASTNAME';
        if val='FIRSTNAME' then val:='SY_FIRSTNAME';
        if val='CODE' then val:='SY_CODE'; }
        col:=Maindata.tablesdesc.Find(tname,val);
        setField(col);
   end;
   index:=code.indexOfName('TAB');
   if index>=0 then
   begin
        if code.Items[index].asstring>' ' then
        begin
             SetTabOrder(code.Items[index].asInteger);
        end;
   end;
   index:=code.indexOfName('CAPTION');
   if index>=0 then
   begin
        if code.Items[index].asstring>' ' then
        begin
            setCaption(code.Items[index].asString);
        end;
   end;
end;

constructor TLWControl.create (aOwner : TWinControl; kind : TLWControlType; src : TDataSource; tname : shortstring);

begin
    zoom:=100;
    name:=uppercase(tname);
    aparent:=aOwner;
    ctrltype:=kind;
    case ctrltype of
            lwct_column :
            begin
              ctrl:=TDBEdit.create(aOwner);
              ctrl.Parent:=aOwner;
            end;
            lwct_label :
            begin
              ctrl:=TLabel.create(aOwner);
              ctrl.Parent:=aOwner;
              SetCaption('? ? ? ? ');
              ctrl.Color:=clNone;
            end;
            lwct_button :
            begin
              ctrl:=TBitBtn.CREATE(aOwner);
              ctrl.Parent:=aOwner;
              setCaption('??');
            end;
    end;
    if assigned(ctrl) then
    begin
        ctrl.AutoSize:=false;
    end;
    hint:='';
    SetTabOrder(0);
    SetWidth(100);
    SetHeight(23);
    datasource:=src;
end;

function TLWControl.getBounds : Trect;

begin
     if assigned(ctrl) and (not selected) then
     begin
          left:=ctrl.Left;
          top:=ctrl.top;
          width:=ctrl.Width;
          height:=ctrl.Height;
     end;
     result.Left:=trunc(left*zoom / 100);
     result.Top:=trunc(top * zoom / 100);
     result.Width:=trunc(width * zoom / 100);
     result.Height:=trunc(height * zoom / 100);
end;

function TLWControl.getSizeMode(x, y : integer) :  TSizeMode;

var r, r1 : Trect;
    p : Tpoint;

begin
  result:=sm_none;
  if selected then
  begin
       r:=getBounds;
       p.x:=x;p.y:=y;
       if r.Contains(p) then
       begin
         result:=sm_move;
         r1:=r; r1.bottom:=r1.top + 4;
         if r1.Contains(p) then result:=sm_top;
         r1:=r; r1.top := r1.bottom - 4;
         if r1.Contains(p) then result:=sm_bottom;
         r1:=r; r1.Right:=r1.left + 4;
         if r1.Contains(p) then result:=sm_left;
         r1:=r; r1.Left:=r1.Right - 4;
         if r1.Contains(p) then result:=sm_right;
       end;
  end;
end;


{
@html(<p>See <a href="https://wiki.freepascal.org/Colors">Colors</a></p>)
}
procedure TLWControl.paint(cv : Tcanvas);

var r : trect;
    s : shortstring;
    l : Tlabel;

begin
  r:=getBounds;
  if selected then
  begin
    InflateRect(r,-2,-2);
    cv.Brush.Color:=clLtGray;
    cv.fillrect(r);
    cv.pen.Color:=TColor($FF69B4); // HotPink
    cv.Pen.Width:=1;
    cv.Rectangle(r);
    InflateRect(r,2,2);
    cv.Brush.Color:=clRed;
    cv.FrameRect(r);
    cv.Brush.Color:=clblack;
    cv.Fillrect(r.left,r.top,r.Left+6,r.top+6);
    cv.Fillrect(r.left,r.bottom-6,r.Left+6,r.bottom);
    cv.Fillrect(r.right -6 ,r.top,r.right,r.top + 6);
    cv.Fillrect(r.right -6 ,r.bottom - 6,r.right,r.bottom);
    s:=self.name;
    if assigned(def) then s:=s+' : '+def.col_name;
    cv.TextRect(r,r.left+10,r.top+2,s);
  end else
  begin
    cv.pen.Color:=TColor($FF69B4); // HotPink
    cv.Brush.color:=TColor($D3D3D3); // LightGrey
    cv.Pen.Width:=1;
    cv.Frame(r);
    if ctrl is Tlabel then
    begin
      cv.FillRect(r);
      l:=Tlabel(ctrl);
      cv.TextOut(R.left, R.top, l.Caption);
    end;
  end;
end;



procedure TLWControl.resize(m : TSizeMode; val : integer);

var r : Trect;

begin
     r:=getBounds;
     case m of
             sm_left :
             begin
                  setPosx(r.left + val);
                  setWidth(r.width - val);
             end;
             sm_right :
             begin
                  setWidth(r.width + val);
             end;
             sm_top :
             begin
                  SetPosy(r.Top + val);
                  setHeight(R.Height - val);
             end;
             sm_bottom :
             begin
                  setHeight(r.Height + val);
             end;
     end;
end;

procedure TLWControl.SetOnEnter(M : TMethod);


begin
  OnEnter:=M;
  if assigned(ctrl) then
  begin
      if IsPublishedProp(ctrl,'OnEnter') then
      begin
         SetMethodProp(ctrl,'OnEnter',M);
      end;
  end;
end;

procedure TLWControl.SetOnMouseDown(M : TMethod);

begin
  OnMouseDown:=M;
  if assigned(ctrl) then
  begin
      if IsPublishedProp(ctrl,'OnMouseDown') then
      begin
         SetMethodProp(ctrl,'OnMouseDown',M);
      end;
  end;
end;

procedure TLWControl.setSelected(s : boolean; o : integer = -1);

begin
    selected:=s;
    if assigned(ctrl) then
    begin
         ctrl.Visible:=not s;
         ctrl.enabled:=not s;
         if s then
         begin
           assert(o>0,'SelOrder must be > 0');
           ctrl.SendToBack;
           selorder:=o;
         end else
         begin
           ctrl.BringToFront;
           ctrl.top:=top;
           ctrl.left:=left;
           ctrl.height:=height;
           ctrl.width:=width;
           selorder:=-1;
         end;
    end;
end;



procedure TLWControl.setCaption(c : string);

begin
     c:=trim(c);
     if assigned(ctrl) then
     begin
          if (not (ctrl is TDBEdit)) then
          begin
            if (caption<>c) then
            begin
                 caption:=c;
                 if assigned(ctrl) then ctrl.caption:=c;
            end;
          end else
          begin
            caption:='';
          end;
     end;
end;

procedure TLWControl.setTaborder(t : integer);

begin
     if t<-1 then t:=-1;
     taborder:=t;
     if assigned(ctrl) then
     begin
          if ctrl is TWinControl then
          begin
               TwinControl(ctrl).TabOrder:=t;
          end;
     end;
end;

procedure TLWControl.setPosX(x : integer);

begin
   if x>=0 then
   begin
        left:=x;
        if assigned(ctrl) and (not selected) then
        begin
            if ctrl.left<>x then ctrl.left:=x;
        end;
   end;
end;

procedure TLWControl.setPosY(y : integer);

begin
   if y>=0 then
   begin
        top:=y;
        if assigned(ctrl) and (not selected) then
        begin
            if ctrl.top<>y then ctrl.top:=y;
        end;
   end;
end;

procedure TLWControl.setHeight(h : integer);

begin
   if h>=23 then
   begin
        height:=h;
        if assigned(ctrl) and (not selected) then
        begin
            if ctrl.height<>h then ctrl.height:=h;
        end;
   end;
end;

procedure TLWControl.setHint(c : string);

begin
   hint:=c;
   if assigned(ctrl) then
   begin
       ctrl.Hint:=c;
       showhint:=c>' ';
       ctrl.ShowHint:=showhint;
   end;
end;

procedure TLWControl.setWidth(w : integer);

begin
   if w>=20 then
   begin
        Width:=w;
        if assigned(ctrl) and (not selected) then
        begin
            if ctrl.width<>w then ctrl.width:=w;
        end;
   end;
end;

procedure TLWControl.setZoom(z : integer);

begin
   zoom:=z;
   if assigned(ctrl) then
   begin
       ctrl.Top:=trunc(top * zoom / 100) ;
       ctrl.Left:=trunc(left * zoom / 100);
       ctrl.Width:=trunc(width * zoom / 100);
       ctrl.height := trunc(height * zoom / 100);
   end;
end;

procedure TLWControl.refresh;


begin
     if assigned(def)  then
     begin
              if assigned(ctrl) then
              begin
                  if not (ctrl is TDBEdit) then
                  begin
                      FreeAndNil(ctrl);
                  end;
              end;
              if not assigned(ctrl) then
              begin
                   ctrl:=TDBEDIT.create(aparent);
              end;
              ctrl.parent:=aparent;
              TDBEdit(ctrl).Text:='   ';
              TDBEdit(ctrl).DataSource:=DataSource;
              TDBEDIT(ctrl).DataField:=def.col_name;
              TDBEDIT(ctrl).ReadOnly:=false;
     end;

     if assigned(ctrl) then
     begin
          ctrl.Left:=left;
          ctrl.Top:=top;
          ctrl.width:=width;
          ctrl.height:=height;
          ctrl.name:=name;
          ctrl.AutoSize:=false;
          if ctrl is TWinControl then TWinControl(ctrl).taborder:=taborder;

          ctrl.hint:=hint;
          ctrl.showhint:=showhint;
          if assigned(def) then
          begin
               if ctrl is  TDBEDIT then
               begin
                    if (def.col_name='SY_ID') or (def.col_name='SY_CRC') then
                    begin
                         TDBEDIT(ctrl).ReadOnly:=true;
                         TDBEDIT(ctrl).TabStop:=false;
                    end;
                    if def.col_lenght>0 then
                    begin
                         if def.col_type='CHAR' then TDBEDIT(ctrl).MaxLength:=def.col_lenght;
                    end;
               end;
          end;
          if ctrl is Tlabel then
          begin
               ctrl.caption:=caption;
          end;

           // voir https://www.freepascal.org/docs-html/current/rtl/typinfo/getmethodprop.html
          try
           // M:=TMethod(OnMouseMove);
           // SetMethodProp(ctrl,'OnMouseMove',m);
            //M:=TMethod(OnMouseDown);
            //SetMethodProp(ctrl,'OnMouseDown',m);
          except
          end;
     end;
end;

procedure TLWControl.setField(c : TColumnDesc);

var old : string;

begin
     {TODO : LWH a revoir }
{     old:='?';
     if assigned(def) then old:=def.style;
     def:=c;
     if assigned(def) then
     begin
          if (def.style<>old) then
          begin
              refresh;
          end;
     end;}
  def:=c;
     refresh;
end;

procedure TLWControl.setSField(s : shortstring);

var c : Tcolumndesc;

begin
  c:=Maindata.tablesdesc.Find(tablename,s);
  setField(c);
end;

destructor TLWControl.Destroy;

begin
  freeAndNil(ctrl);
  inherited;
end;

(* *)

constructor TDataPanel.create(AOwner: TComponent; aname : shortstring);

var MyItem:TMenuItem;
    h : integer;

begin
  inherited create(AOwner);
  if AOwner is Twincontrol then  parent:=TWinControl(AOwner);
  winpa:=parent;
  while (assigned(winpa)) and (not (winpa is Tform)) do winpa:=winpa.parent;

  name:=aname;
  CtrlList := TDico.create;
  BorderStyle:=bsSingle;
  Json:=nil;
  DesignMode:=false;
  selnum:=0;
  SetNbSel(0);
  sizemode:=sm_none;
  dragmode:=dmmanual;
  onMouseDown:=nil;
  OnEnter:=@Onfocus;
  ParentBackground:=true;

 { h := abs(GetFontData(Font.Reference.Handle).height);
  self.Font:=TFont.Create;
  font.Height:=h;}

  if not assigned(PopupMenu) then
  begin
      PopupMenu:=TPopupMenu.Create(self);
      PopupMenu.Parent:=self;
  end else
  begin
    MyItem:=TMenuItem.Create(Self);
    MyItem.Caption:='-';
    MyItem.Name:='Separator';
    PopupMenu.Items.Add(MyItem);
  end;
  if assigned(PopupMenu) then
  begin
       MyItem:=TMenuItem.Create(Self);
       MyItem.Caption:=rs_design;
       MyItem.Name:='DESIGNMODE';
       MyItem.Hint:=rs_design_hint;
       MyItem.OnClick:=@SetDesignMode;
       PopupMenu.Items.Add(MyItem);

       MyItem:=TMenuItem.Create(Self);
       MyItem.Caption:=rs_export;
       MyItem.Name:='EXPORT';
       MyItem.Hint:=rs_export_hint;
       //MyItem.OnClick:=@exporter;
       PopupMenu.Items.Add(MyItem);
  end;
  onPaint:=@Paint;
end;

procedure TDataPanel.add_ctrl(n : shortstring; x,y : integer);

var c : TLWControl;
    dbcb : TDbCheckBox;
    nom : string;
    M : Tmethod;

begin
  c:=nil;
  if n='Ctrl_column' then
  begin
     nom:='C'+intToHex(random(100),2)+intToHex(CtrlList.count + 1, 2);
     c:=TLWControl.create(self,lwct_column,DataSource,nom);
  end else
  if (n='Ctrl_text') then
  begin
     nom:='STT'+intToHex(random(100),2)+intToHex(CtrlList.count + 1, 2);
     c:=TLWControl.create(self,lwct_label,DataSource,nom);
  end else
  if (n='Ctrl_button') then
  begin
       nom:='BT'+intToHex(random(100),2)+intToHex(CtrlList.count + 1, 2);
       c:=TLWControl.create(self,lwct_button,DataSource,nom);
  end;
  if assigned(c) then
  begin
    c.tablename:=self.TableName;
    CtrlList.Add(nom,c);
    c.setPosX(x);
    c.setPosY(y);
    c.setWidth(100);
    c.setHeight(23);
    c.DataSource:=self.DataSource;

    M.Data:=Pointer(self);
    M.Code:=Pointer(@TDataPanel.Ctrl_Enter);
    c.SetOnEnter(M);
    M.code:=Pointer(@TDataPanel.Ctrl_MouseDown);
    c.SetOnMouseDown(M);


    c.refresh;
    c.selected:=true;
  end;
  paint(self);
end;

procedure TDataPanel.CalcZOrder;

var lst : array of TLWControl;
    c,d : TLWControl;
    i,j,nb : integer;
    r : trect;
    change : boolean;
    readonly : boolean;
    x1,y1,x2,y2 : integer;

begin
     nb:=CtrlList.count;
     setLength(lst,nb);
     i:=0;
     for c in CtrlList.values do
     begin
         c.refresh;
         lst[i]:=c;
         inc(i);
     end;

     for i:=0 to  (nb - 1) do
     begin
       for j:=0 to (nb - 2) do
       begin
         change:=false;
         y1:=lst[j].top; y1:=round(y1 / 5);
         y2:=lst[j + 1].top; y2:=round(y2 / 5);

         x1:=lst[j].left;x1 := round(x1 / 5);
         x2:=lst[j + 1].left;x2 := round(x2 / 5);


         if y1>y2 then change:=true
         else
         if y1<y2 then change:=false
         else
         if x1>x2 then change:=true;
         if change then
         begin
           c:=lst[j];
           lst[j]:=lst[j + 1];
           lst[j + 1]:=c;
         end;
       end;
     end;
     j:=0;
     for i:=0 to nb - 1 do
     begin
       case lst[i].ctrlType of
           lwct_column:
           begin
                if assigned(lst[i].ctrl) then
                begin
                  readonly:=false;
                  // https://www.freepascal.org/docs-html/rtl/typinfo/index-5.html
                  if IsPublishedProp(lst[i].ctrl,'ReadOnly') then
                  begin
                       x1:= GetOrdProp(lst[i].ctrl,'ReadOnly');
                       readOnly:=(GetOrdProp(lst[i].ctrl,'ReadOnly')>0);
                  end;
                  if (not readonly) and (IsPublishedProp(lst[i].ctrl,'TabStop')) then
                  begin
                       x1:= GetOrdProp(lst[i].ctrl,'TabStop');
                       readOnly:=(GetOrdProp(lst[i].ctrl,'TabStop')=0);
                  end;
                end else readonly:=true;
                if not readonly then
                begin
                     lst[i].setTabOrder(j);
                     inc(j);
                end else
                begin
                     lst[i].setTabOrder(-1);
                end;
           end;
           lwct_label :
           begin
                lst[i].setTabOrder(-1);
           end;
           lwct_button :
           begin
                lst[i].setTabOrder(j);
                inc(j);
           end;
           else
           begin
             lst[i].setTabOrder(-1);
           end;
       end;

     end;
     repaint;
end;

procedure TDataPanel.align(D : char);

var c,r : TLWControl;
    rc : trect;
    m : integer;

begin
     m:=maxint;
     if nbsel<2 then exit;
     for c in ctrlList.values do
     begin
          if c.selected then
          begin
               if c.selorder<m then
               begin
                    m:=c.selorder;
                    r:=c;
               end;
          end;
     end;
     if assigned(r) then
     begin
       rc:=r.getBounds;
       for c in ctrlList.values do
       begin
         if (c.selected) and (c<>r) then
         begin
              case D of
                    'L' : c.setPosX(rc.Left);
                    'R' : c.setPosX(rc.right - c.width);
                    'T' : c.setPosy(rc.top);
                    'B' : c.setPosy(rc.bottom - c.height);
                    'W' : c.setWidth(rc.width);
                    'H' : c.setHeight(rc.Height);
              end;
         end;
       end;
       paint(self);
     end;
end;

procedure TDataPanel.Ctrl_Enter(Sender: TObject);

var selectedControl : TLWControl;
    change : boolean;

begin
  if sender is Tcontrol and DesignMode then
  begin
       change:=false;
       if (CtrlList.TryGetValue(TControl(Sender).name,selectedControl)) then
       begin
          if  not selectedControl.selected then
          begin
             inc(selnum);
             change:=true;
             selectedControl.Setselected(true,selnum);
          end;
       end;
       if change then Paint(nil);
  end;
end;

procedure TDataPanel.Ctrl_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);

var selectedControl : TLWControl;
    change : boolean;
    n : integer;

begin
  if sender is Tcontrol and DesignMode then
  begin
       change:=false;
       oldMousePos.x:=-1;
       oldMousePos.Y:=-1;
       if not ( (ssCtrl in Shift) or (ssShift in Shift))  then
       begin
         for selectedControl in ctrlList.values do
         begin
           if selectedControl<>Sender then
           begin
                if selectedControl.selected then
                begin
                     selectedControl.Setselected(false);
                     change:=true;
                end;
           end;
         end;
         setNbsel(0);
       end;
       n:=nbsel;
       if (CtrlList.TryGetValue(TControl(Sender).name,selectedControl)) then
       begin
          if not selectedControl.Selected then
          begin
               change:=true;
               inc(selnum);
               inc(n);
               selectedControl.SetSelected(true,selnum);
          end else
          begin
               selectedControl.SetSelected(true,selnum);
          end;
       end;
       setNbsel(n);
       if change then Paint(nil);
  end;
end;

procedure TDataPanel.DeleteControls;

var c : TLWControl;

begin
  for c in ctrlList.values do
  begin
      if c.selected then
      begin
        ctrlList.Remove(c.name);
        c.Free;
      end;
  end;
  paint(nil);
end;

procedure TDataPanel.DragDrop(Sender, Source: TObject; X, Y: Integer);

begin
   if DesignMode and assigned(source) and (source is Tcontrol) and (source is TImage32)  then
   begin
     add_ctrl(TControl(Source).name,X,Y);
   end;
end;



Procedure TDataPanel.DragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);

begin
  accept:=False;
  if DesignMode and assigned(source) and (source is Tcontrol) and (source is TImage32) then
  begin
    if leftStr(TControl(source).Name,4)='Ctrl' then accept:=true;
  end;
end;

function TDataPanel.GetDesignMode : boolean;

begin
  result:=DesignMode;
end;

function TDataPanel.GetInternalName : string;

begin
  result:=self.name;
end;

Procedure TDataPanel.GenerateJson;

var jsonobj : TJSONObject;
    datapanel : TJSONObject;
    obj : TJSONObject;
    lst : TJSONObject;
    c : TLWControl;
    s : string;


begin
     jsonobj := TJSONObject.create();
     s:=getInternalName();
     datapanel:=TJSONObject.create(['ID',s]);
     datapanel.add('CPT',ctrlList.count);
     datapanel.add('USR',MainForm.username);
     if color<>clDefault then
     begin
       datapanel.add('COLOR',ColorToString(color));
     end;

     lst:=TJSONObject.create();
     lst.add ('Control',TJSONArray.Create);

     for c in ctrlList.values do
     begin
        if assigned(c) AND assigned(c.ctrl) then
        begin
            c.refresh;
            obj:=TJSONObject.Create(['CLASS',c.ctrl.ClassName]);
            obj.add('NAME',uppercase(c.name));
            obj.add('LEFT',c.left);
            obj.add('TOP',c.top);
            obj.add('WIDTH',c.width);
            obj.add('HEIGHT',c.height);

            s:=trim(c.hint);
            if s>' ' then obj.add('HINT',s);
            if (assigned(c.def) and (c.ctrltype=lwct_column)) then obj.add('FIELD',c.def.col_name);
            obj.add('TAB',c.taborder);
            obj.add('CAPTION',c.caption);
            lst.Arrays['Control'].add(obj);
        end;
     end;

     datapanel.add('Content',lst);
     jsonobj.add('DataPanel',datapanel);

     freeAndNil(Json);
     Json:=jsonobj;


end;

procedure TDataPanel.init(u : ShortString);

var nom, sjson :  string;
    j : TJsonData;

begin
     nom:=name;
     j:=MainData.getIhm(Mainform.username,nom);
     if assigned(j) then
     begin
       sjson:=j.AsJson;
       freeandNil(j);
     end else
     begin
       sjson:='{}';
     end;
     if (not designmode) and (sjson > ' ') then SetJson(sjson);
end;

{ https://lazarus-ccr.sourceforge.io/docs/lcl/lcltype/index-2.html
  https://www.freepascal.org/docs-html/rtl/classes/tshiftstate.html
}
procedure TDataPanel.KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

var c : TLWControl;
    change : boolean;
    r : trect;


begin
     change:=false;
     if DesignMode then
     begin
       case key of
             VK_BACK : DeleteControls;
             VK_DOWN :
             begin
               for c in ctrlList.values do
                 begin
                     if c.selected then
                     begin
                          r:=c.getBounds;
                          if ssShift in Shift  then c.setHeight(r.height - 1)
                          else
                          if ssCtrl in Shift then
                          begin
                               c.setHeight(r.height - 1);
                               c.setPosY(r.top + 1);
                          end
                          else c.setPosY(r.top+ 1);
                          change:=true;
                     end;
                 end;
             end;
             VK_DELETE : DeleteControls;
             VK_LEFT :
             begin
               for c in ctrlList.values do
                 begin
                     if c.selected then
                     begin
                          r:=c.getBounds;
                          if ssShift in Shift  then c.setWidth(r.Width - 1)
                          else
                          if ssCtrl in Shift then
                          begin
                               c.setWidth(r.width - 1);
                               c.setPosX(r.left + 1);
                          end
                          else c.setPosX(r.left - 1);
                          change:=true;
                     end;
                 end;
             end;
             VK_RIGHT :
             begin
               for c in ctrlList.values do
                 begin
                     if c.selected then
                     begin
                          r:=c.getBounds;
                          if ssShift in Shift  then c.setWidth(r.Width + 1)
                          else
                          if ssCtrl in Shift then
                          begin
                               c.setWidth(r.width + 1);
                               c.setPosX(r.left - 1);
                          end
                          else c.setPosX(r.left + 1);
                          change:=true;
                     end;
                 end;
             end;
             VK_UP :
             begin
               for c in ctrlList.values do
                 begin
                     if c.selected then
                     begin
                          r:=c.getBounds;
                          if ssShift in Shift  then c.setHeight(r.height + 1)
                          else
                          if ssCtrl in Shift then
                          begin
                               c.setHeight(r.height + 1);
                               c.setPosY(r.top - 1);
                          end
                          else c.setPosY(r.top - 1);
                          change:=true;
                     end;
                 end;
             end;
       end;
       if change then paint(nil);
     end;
end;


procedure TDataPanel.MouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X: Integer; Y: Integer);

var c : TLWControl;
    r : Trect;
    p : Tpoint;
    change : boolean;
    n : integer;

begin
  oldMousePos.x:=X;
  oldMousePos.Y:=Y;
  if (DesignMode) and  (not ( (ssCtrl in Shift) or (ssShift in Shift))) and  (Button=mbLeft)   then
  begin
    change:=false;
    p.X:=X;p.y:=Y;
    n:=0;
    for c in ctrlList.values do
    begin
         r:=c.getBounds;
         if not r.Contains(p) then
         begin
           if c.selected then
           begin
             c.setSelected(false);
             change:=true;
           end;
         end else
         begin
            if not c.selected then
            begin
              inc(selnum);
              c.setSelected(true, selnum);
              change:=true;
            end;
         end;
         if c.selected then
         begin
           inc(n);
           if assigned(FCustomDP) then FCustomDP.setInsertObject('');
         end;
    end;
    setNbsel(n);
    if change then
    begin
      if assigned(FCustomDP) then
      begin
              FCustomDP.PanelChange(ch_all);
      end;
      Paint(nil);
    end;
  end;
  if assigned(FCustomDP) and DesignMode and (Button=mbLeft) and (nbsel=0) then
  begin
       if FcustomDP.insert_object>' ' then
       begin
         add_ctrl(FCustomdp.insert_object,X,Y);
         FCustomDP.setInsertObject('');
       end;
  end;
  FCustomDP.PanelChange(ch_all);
end;

procedure TDataPanel.MouseMove(Sender: TObject; Shift: TShiftState; X: Integer; Y: Integer);

var diffx, diffy : integer;
    nx, ny,n : integer;
    r : Trect;
    c : TLWControl;
    change : boolean;
    new : TCursor;

begin
  change:=false;
  if (DesignMode) then
  begin
       if  (ssLeft in Shift) and ((oldMousePos.x>0) or (oldMousePos.y>0)) then
       begin
         diffx:=X - oldMousePos.x;
         diffy:=Y - oldMousePos.y;
         if ((diffx<>0) or (diffy<>0)) and ((abs(diffx)<200) and (abs(diffy)<200)) then
         begin
           n:=0;
           for c in ctrlList.values do
           begin
              if c.selected then
              begin
                inc(n);
                case sizemode of
                        sm_move :
                        begin
                          r:=c.getBounds;
                          change:=true;
                          nx:=r.Left + diffx;
                          ny:=r.top + diffy;
                          c.setPosX(nx);
                          c.setPosy(ny);
                        end;
                        sm_left :
                        if diffx<>0 then
                        begin
                             change:=true;
                             c.resize(sizemode,diffx);
                        end;
                        sm_right :
                        if diffx<>0 then
                        begin
                             change:=true;
                             c.resize(sizemode,diffx);
                        end;
                        sm_top :
                        if diffy<>0 then
                        begin
                             change:=true;
                             c.resize(sizemode,diffy);
                        end;
                        sm_bottom :
                        if diffy<>0 then
                        begin
                             change:=true;
                             c.resize(sizemode,diffy);
                        end;
                end;
              end;
           end;
           setnbsel(n);
         end;
       end else
       begin
            sizemode:=sm_none;
            for c in ctrlList.values do
            begin
               if (c.selected) and (sizemode=sm_none) then
               begin
                    sizemode:=c.getSizeMode(x,y);
                    if sizemode<>sm_none then break;
               end;
            end;
            case sizemode  of
              sm_none  : new:=crDefault;
              sm_left  : new:=crSizeWE;
              sm_right : new:=crSizeWE;
              sm_top   : new:=crSizeNS;
              sm_bottom: new:=crSizeNS;
              sm_move  : new:=crSize;
            end;
            if Screen.cursor<>new then Screen.cursor:=new;
       end;
       if change then
       begin
         paint(self);
         if assigned(FCustomDP) then
         begin
              FCustomDP.PanelChange(ch_dimpos);
         end;
       end;
  end;

  oldMousePos.x:=X;
  oldMousePos.Y:=Y;
end;

procedure TDataPanel.NotifyChange;

begin

    FCustomDP:=TFCustomDP.get;
    if assigned(FCustomDP) then
    begin
        FCustomDP.PanelChange(ch_all);
    end;
end;

procedure TDataPanel.onFocus(Sender: TObject);

var p : TWinControl;

begin
  p:=self.parent;
  while assigned(p) and (not (p is Tform)) do
  begin
       p:=p.parent;
  end;
  If assigned(p) and (p is Tform) then
  begin
    MainForm.updatePanel(p as Tform);
  end else
  begin
       Mainform.updatePanel(Mainform);
  end;
end;

procedure TDataPanel.Paint(sender : TObject);

var
  x, y, n: Integer;
  r,r1 : trect;
  //Bitmap: TBitmap32;
  Bitmap : TBitmap;
  c,sel : TLWControl;
  lv1,lv2,lh1,lh2 : boolean;

begin
  If DesignMode then
    begin
      Bitmap := TBitmap.Create; // Double buffering
      try
        // Initializes the Bitmap Size
        Bitmap.Height := Height;
        Bitmap.Width := Width;
        Bitmap.canvas.Brush.Color:=clWhite;
        Bitmap.Canvas.Pen.Color := clWhite;
        Bitmap.Canvas.Brush.Style := bsSolid;

        Bitmap.Canvas.Rectangle(0,0,width,height);
        x:=0;y:=0;
        Bitmap.Canvas.Pen.Color := clLtGray;
        Bitmap.canvas.Brush.Color:=clLtGray;
        Bitmap.Canvas.Pen.Width:=4;

        while x<(width - 10) do
        begin
        x:=x+10;
        y:=0;
        while y< (height - 10) do
        begin
          y:=y+10;
          bitmap.Canvas.Pixels[x,y]:=clLtGray;
        end;
        end;

        n:=0;
        for c in ctrlList.values do
        begin
          if c.selected then
          begin
              sel:=c;
              inc(n);
          end;
          c.paint(Bitmap.Canvas);
        end;
        setnbsel(n);
        if (nbsel=1) and assigned(sel) then
        begin
          r:=sel.getbounds;
          lv1:=false;lv2:=false;lh1:=false;lh2:=false;
          for c in ctrlList.values do if c<>sel then
          begin
            r1:=c.getBounds;
            if (r1.Left=r.left) or (r1.Right = r.Left) then lv1:=true;
            if (r1.Left=r.right) or (r1.Right = r.Right) then lv2:=true;
            if (r1.top=r.top) or (r1.bottom = r.top) then lh1:=true;
            if (r1.top=r.bottom) or (r1.bottom = r.bottom) then lh2:=true;
            if (lh1 and lh2 and lv1 and lv2) then break;
          end;
          Bitmap.canvas.Brush.Style:=bsClear;
          Bitmap.canvas.pen.style:=psDot;
          Bitmap.Canvas.Pen.Width:=1;
          if lv1 then
          begin
            Bitmap.Canvas.Pen.color:=clblue;
            bitmap.Canvas.Line(r.left,0,r.left,height);
          end;
          if lv2 then
          begin
            Bitmap.Canvas.Pen.color:=clGreen;
            bitmap.Canvas.Line(r.right,0,r.right,height);
          end;
          Bitmap.canvas.pen.style:=psDash;
          if lh1 then
          begin
            Bitmap.Canvas.Pen.color:=clFuchsia;
            bitmap.Canvas.Line(0,r.top,width,r.top);
          end;
          if lh2 then
          begin
            Bitmap.Canvas.Pen.color:=clTeal;
            bitmap.Canvas.Line(0,r.bottom,width,r.bottom);
          end;
        end;
        // couleurs : https://wiki.freepascal.org/Colors
        bitmap.Canvas.Brush.Color:=clWhite;
        Bitmap.Canvas.Font.Size:=8;
        Bitmap.Canvas.Font.Color:=clRed;
        for c in ctrlList.values do
        begin
         if c.taborder>=0 then
         begin
              Bitmap.Canvas.TextOut(c.left+c.width + 3,c.top - 10, intTostr(c.taborder));
         end;
        end;
        canvas.Draw(self.HorzScrollBar.ScrollPos,self.VertScrollBar.ScrollPos,bitmap);
        canvas.Changed;
      finally
        Bitmap.Free;
      end;
    end else
    begin
         if not self.ParentBackground then
         begin
           try
             Canvas.Lock;
             try
               Canvas.Brush.Color := self.color;
               Canvas.Brush.Style := bsSolid;
               Canvas.Pen.Color := clnone;
               Canvas.Pen.Style := psClear;
               Canvas.Rectangle(self.HorzScrollBar.ScrollPos,self.VertScrollBar.ScrollPos,self.HorzScrollBar.ScrollPos+Width,self.VertScrollBar.ScrollPos+Height);
             except
             end;
           finally
             Canvas.Unlock;
           end;
         end;
    end;
end;

procedure TDataPanel.save;

var s : string;

begin
  generateJson;
  if assigned(Json) then
  begin
      s:=Json.FormatJson([foSingleLineArray,foSingleLineObject,foDoNotQuoteMembers,foUseTabchar,foSkipWhiteSpace],1);
      Maindata.SaveIhm(getInternalName, s);
  end;
end;

procedure TDataPanel.setColor(c : Tcolor);

begin
     if c=clDefault then
     begin
          ParentBackground:=true;
          Color:=c;
     end else
     begin
          ParentBackground:=false;
          Color:=c;
     end;
end;

procedure TDataPanel.SetDataSource(s : TDataSource; tname : shortstring);

begin
  DataSource:=s;
  DataSource.AutoEdit:=true;
  tablename:=tname;
end;

Procedure TDataPanel.SetDesign(d : boolean);

var c : TLWControl;
    M : Tmethod;

begin
  if designMode=d then exit;
  DesignMode:=d;
  if DesignMode then
   begin
     for c in ctrlList.values do
     begin;
       M.Data:=Pointer(self);
       M.Code:=Pointer(@TDataPanel.Ctrl_Enter);
       c.SetOnEnter(M);
       M.code:=Pointer(@TDataPanel.Ctrl_MouseDown);
       c.SetOnMouseDown(M);
       c.Setselected(false);
       if c.ctrlType=lwct_label then
       begin
         tlabel(c.ctrl).color:=TColor($D3D3D3); //LightGrey
         tlabel(c.ctrl).autosize:=false;
         tlabel(c.ctrl).transparent:=false;
       end;
       c.refresh;
     end;
     onPaint:=@Paint;
     showinterface(true);
     ondragover:=@dragover;
     ondragdrop:=@dragdrop;
     onMouseDown:=@MouseDown;
     onMouseMove:=@MouseMove;
     winpa:=parent;
     while (assigned(winpa)) and (not (winpa is Tform)) do winpa:=winpa.parent;
     if assigned(winpa) and (winpa is Tform) then  winpa.OnKeyDown:=@KeyDown;
   end else
   begin
     OnPaint:=@Paint;
     ondragover:=nil;
     ondragdrop:=nil;
     onMouseDown:=nil;
     onMouseMove:=nil;
     if assigned(winpa) and (winpa is Tform) then  winpa.OnKeyDown:=nil;
    // OnKeyDown:=nil;
     for c in ctrlList.values do
     begin
        M.Code:=nil;
        M.Data:=Pointer(self);
        c.SetOnEnter(m);
        c.SetOnMouseDown(m);
        c.SetSelected(false);
        c.refresh;
        if c.ctrlType=lwct_column then
        begin
          TDBEdit(c.ctrl).ReadOnly:=false;
          TDBEdit(c.ctrl).Enabled:=true;
          if TDBEdit(c.ctrl).ReadOnly then showmessage('readonly');
        end;
        if c.ctrlType=lwct_label then
        begin
          Tlabel(c.ctrl).color:=clnone;
          Tlabel(c.ctrl).autosize:=false;
          Tlabel(c.ctrl).transparent:=true;
        end;
        c.ctrl.Invalidate;
        c.ctrl.repaint;
     end;
     showinterface(false);
   end;
   selnum:=0;
   Refresh;
end;

procedure TDataPanel.SetNbSel(n : integer);

begin
  if nbsel<>n then
  begin
     nbsel:=n;
     notifychange;
  end;
  if (nbsel=0) and (selnum<>0) then selnum:=0;
end;

procedure TDataPanel.SetDesignMode(Sender : Tobject);

begin
  setDesign(Not DesignMode);
end;

procedure TDataPanel.setTable(tname : string; CDesc : TTableDesc);

var c,n : TColumnDesc;
    item : TCollectionItem;

begin
  TableName:=tname;
  ColumnDesc := TTableDesc.create;
  for item in Cdesc do
  begin
      if item is TColumnDesc then
      begin
        c:=TColumnDesc(item);
        if c.table_name=tname then
        begin
             n:=ColumnDesc.Add();
             c.copy(n);
        end;
      end;
  end;
end;

procedure TDataPanel.SetJson(s : string);

var
    jObject : TJSONObject;
    data : TJsonData;
    i : integer;
    c : TLWControl;

begin
    if s<=' ' then s:='{}';
    assert((s>' '),'Invalid Json String');
    json:=GetJson(s);
    data:=Json.FindPath('DataPanel.ID');
    IF assigned(data) then
    begin
        s:=data.Value;
        if s>' ' then name:=s;
    end;
    self.ParentBackground:=true;
    data:=Json.FindPath('DataPanel.COLOR');
    IF assigned(data) then
    begin
        s:=data.Value;
        if s>' ' then
        begin
             color:=StringToColor(s);
             if color<>clDefault then
             begin
                  self.ParentBackground:=false;
             end;
        end;
    end;
    data:=Json.findPath('DataPanel.Content.Control');
    if assigned(data) and (data.JSONType=jtarray) then
    begin
         for I:=0 to Data.Count-1 do
         begin
              jObject:=TJSONArray(Data).Objects[i];
              c:=nil;
              begin
                     c:=TLWControl.create(self,jObject,Datasource,tablename);
                     CtrlList.Add(c.name,c);
              end;
         end;
    end;
end;

procedure TDataPanel.setZoom(z : integer);

var c : TLWControl;

begin
  for c in ctrlList.values do
  begin;
       c.setzoom(z);
  end;
  Font.Size:=trunc(10 * z / 100);
end;

procedure TDataPanel.showinterface(s : boolean);

begin
  if s then
  begin
    FCustomDP:=TFCustomDP.get;
    FCustomDP.setPanel(self);
    FCustomDP.ShowOnTop;
    NotifyChange;
  end else
  begin
      FCustomDP:=TFCustomDP.get;
      FCustomDP.setPanel(nil);
      FCustomDP.Hide;
  end;
end;

destructor TDataPanel.Destroy;

var c : TLWControl;
    col : TCollectionItem;

begin
  freeAndNil(Json);
  if assigned(CtrlList) then
  begin
    for c in CtrlList.values do
    begin
       c.free;
    end;
    freeAndNil(CtrlList);
  end;
  if assigned(ColumnDesc) then
  begin
    for col in ColumnDesc do
    begin
         col.Free;
    end;
    FreeAndNil(ColumnDesc);
  end;
  inherited;
end;


end.


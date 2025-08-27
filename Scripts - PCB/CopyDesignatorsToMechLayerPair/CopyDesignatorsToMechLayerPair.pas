{.................................................................................
 Summary   This script copies (duplicates) component designators to mech
           layer or mech layer pair.
                  
           Designators will display the same text as the parent component, but will
           have '.Designator' special text, they are combined as part of component footprint.
                                                                              
                                                                              
 Author/Created by:    Petar Perisin  
 circa 2014 v3.1  Modified by Randy Clemmons for AD14 and Higher
                  Changed Board.LayerStack. to Board.LayerStack_V7.
 09/04/2021 v4.0  BLM  Added support for AD19+ mech layers & some refactoring.
 25/04/2021 v4.1  BLM  Minor tweaks to UI text & stringlist handling.
 2023-07-12 v4.2  BLM  eliminate V7 stack interfaces for AD19+
 2025-08-27 v4.3  BLM  Improve mechlayer iteration, separate ComboBox loading code
 .................................................................................}

const
    AD19VersionMajor  = 19;
    NoMechLayerKind   = 0;      // enum const does not exist for AD17/18

var
    LegacyMLS       : boolean;
    Board           : IPCB_Board;
    ML1, ML2        : integer;
    slMechPairs     : TStringList;
    slMechSingles   : TStringList;
    LayerName1      : WideString;
    LayerName2      : WideString;

function GetAllMechEnabledLayers(Board : IPCB_Board) : TStringList; forward;

procedure TFormMechLayerDesignators.ButtonCancelClick(Sender: TObject);
begin
    Close;
    slMechPairs.Clear;
    slMechSingles.Clear;
end;

procedure TFormMechLayerDesignators.FormMechLayerDesignatorsShow(Sender: TObject);
var
    i               : Integer;

begin
// are any layer pairs defined ?..
    if slMechPairs.Count = 0 then
    begin
        RadioButtonSingle.Checked := True;
        RadioButtonPair.Enabled := False;
        GroupBoxLayer.Caption := 'Choose Mech Layer:';

        RadioButtonLayer1.Enabled := False;
        RadioButtonLayer2.Enabled := False;
    end;

    if (RadioButtonPair.Checked) then
    begin
        for i := 0 to (slMechPairs.Count - 1) do
        begin
            LayerName1 := slMechPairs.Names(i);
            LayerName2 := slMechPairs.ValueFromIndex(i);

            ComboBoxLayers.Items.Add(LayerName1 + ' <----> ' + LayerName2);
            if ComboBoxLayers.Items.Count = 1 then
            begin
                    ComboBoxLayers.SetItemIndex(0);
                    RadioButtonLayer1.Caption := LayerName1;
                    RadioButtonLayer2.Caption := LayerName2;
            end;
        end;
    end else
    begin
//   single layer radio button ticked/checked.
        for i := 0 to (slMechSingles.Count - 1) do
        begin
//          slMechSingles.(LayerName=Layer);
            LayerName1 := slMechSingles.Names(i);

            ComboBoxLayers.Items.Add(LayerName1);
            if ComboBoxLayers.Items.Count = 1 then
                ComboBoxLayers.SetItemIndex(0);
        end;
    end;
end;

procedure TFormMechLayerDesignators.RadioButtonSingleClick(Sender: TObject);
var
    i : Integer;
begin
    if GroupBoxLayer.Caption <> 'Choose Mech Layer:' then
    begin
        RadioButtonLayer1.Enabled := True;
        RadioButtonLayer2.Enabled := False;

        RadioButtonLayer2.Caption := 'Single Layer';
        GroupBoxLayer.Caption := 'Choose Mech Layer:';

        ComboBoxLayers.Clear;

        for i := 0 to (slMechSingles.Count - 1) do
        begin
            ComboBoxLayers.Items.Add(slMechSingles.Names(i));
        end;
        if slMechSingles.Count > 0 then
        begin
            ComboBoxLayers.SetItemIndex(0);
            RadioButtonLayer1.Caption := slMechSingles.Names(0);
        end;
    end;
end;

procedure TFormMechLayerDesignators.RadioButtonPairClick(Sender: TObject);
var
    i : integer;
begin
    if GroupBoxLayer.Caption <> 'Choose Mech Layer Pair:' then
    begin
        RadioButtonLayer1.Enabled := True;
        RadioButtonLayer2.Enabled := True;
        GroupBoxLayer.Caption := 'Choose Mech Layer Pair:';

        ComboBoxLayers.Clear;

        for i := 0 to (slMechPairs.Count - 1) do
        begin
            ComboBoxLayers.Items.Add(slMechPairs.Names(i) + ' <----> ' + slMechPairs.ValueFromIndex(i) );
        end;
        if slMechPairs.Count > 0 then
        begin
            ComboBoxLayers.SetItemIndex(0);
            RadioButtonLayer1.Caption := slMechPairs.Names(0);
            RadioButtonLayer2.Caption := slMechPairs.ValueFromIndex(0);
        end;
    end;
end;

procedure TFormMechLayerDesignators.ComboBoxLayersChange(Sender: TObject);
var
    i : integer;
begin
    i := ComboBoxLayers.GetItemIndex;
    if RadioButtonPair.Checked then
    begin
        if slMechPairs.Count > 0 then
        begin
            RadioButtonLayer1.Caption := slMechPairs.Names(i);
            RadioButtonLayer2.Caption := slMechPairs.ValueFromIndex(i);
        end;
    end;
    if RadioButtonSingle.Checked then
    begin
        if slMechSingles.Count > 0 then
        begin
            RadioButtonLayer1.Caption := slMechSingles.Names(i);
            RadioButtonLayer2.Caption := 'Single Layer';
        end;
    end;
end;

procedure TFormMechLayerDesignators.ButtonOKClick(Sender: TObject);
var
    MechTop         : TLayer;
    MechBot         : TLayer;
    i, flag         : Integer;
    Primitive       : IPCB_Primitive;
    NewPrim         : IPCB_Primitive;
    CompIterator    : IPCB_BoardIterator;
    OverlayIterator : IPCB_GroupIterator;
    Component       : IPCB_Component;
    ASetOfLayers    : IPCB_LayerSet;
    NewPrims        : TObjectList;

begin
    for i := 0 to (slMechSingles.Count - 1) do
    begin
        LayerName1 := slMechSingles.Names(i);
        ML1        := slMechSingles.ValueFromIndex(i);

        if RadioButtonPair.Checked then
        begin
            if (LayerName1 = RadioButtonLayer1.Caption) then
                if RadioButtonLayer1.Checked then MechTop := ML1
                else                              MechBot := ML1;
             if (LayerName1 = RadioButtonLayer2.Caption) then
                 if RadioButtonLayer2.Checked then MechTop := ML1
                 else                              MechBot := ML1;
        end else
        begin
            if (LayerName1 = ComboBoxLayers.Text) then
            begin
                MechTop := ML1;
                MechBot := ML1;
                break;
            end;
        end;
   end;

   // Cycle through all components, or only selected ones, and
   // copy designators etc to the mech layers defined.
    ASetOfLayers := LayerSetUtils.CreateLayerSet;
    ASetOfLayers.IncludeSignalLayers;
    CompIterator := Board.BoardIterator_Create;
    CompIterator.AddFilter_ObjectSet(MkSet(eComponentObject));
    CompIterator.AddFilter_IPCB_LayerSet(ASetOfLayers);
    CompIterator.AddFilter_Method(eProcessAll);

    Component := CompIterator.FirstPCBObject;
    While (Component <> Nil) Do
    Begin
//   No selected components - make it for all components
        if (RadioButtonAll.Checked) or (RadioButtonSelected.Checked and Component.Selected) then
        begin

            NewPrim := Component.Name.Replicate;

            if Component.Layer = eTopLayer then NewPrim.Layer := MechTop
            else                                NewPrim.Layer := MechBot;

            NewPrim.Text := '.Designator';

            Board.AddPCBObject(NewPrim);
            Component.AddPCBObject(NewPrim);

            if CheckBoxOverlayPrims.Checked then
            begin
                // Copy comment first
                if Component.CommentOn then
                begin
                    NewPrim := Component.Comment.Replicate;

                    if Component.Layer = eTopLayer then NewPrim.Layer := MechTop
                    else                                NewPrim.Layer := MechBot;

                    NewPrim.Text := '.Comment';

                    Board.AddPCBObject(NewPrim);
                    Component.AddPCBObject(NewPrim);
                end;

//   copy all other overlay primitives to mechLayer -
                ASetOfLayers := LayerSetUtils.EmptySet;
                AsetOfLayers.Include(eTopOverlay);
                AsetOfLayers.Include(eBottomOverlay);
                OverlayIterator := Component.GroupIterator_Create;
                OverlayIterator.SetState_FilterAll;
                OverlayIterator.AddFilter_IPCB_LayerSet(ASetOfLayers);   // DNW on Group ??

                NewPrims := TObjectList.Create;

                Primitive := OverlayIterator.FirstPCBObject;
                while (Primitive <> nil) do
                begin
                    if ASetOfLayers.Contains(Primitive.Layer) then
                    begin
                        NewPrim := Primitive.Replicate;

                        if Primitive.Layer = eTopOverlay then NewPrim.Layer := MechTop
                        else                                  NewPrim.Layer := MechBot;

                        NewPrims.Add(NewPrim);
                    end;
                    Primitive := OverlayIterator.NextPCBObject;
                end;
                Component.GroupIterator_Destroy(OverlayIterator);

// should NOT add or delete from inside an iterated collection.
                for i := 0 to (NewPrims.Count -1) do
                begin
                    NewPrim := NewPrims.Items(i);
                    Board.AddPCBObject(NewPrim);
                    Component.AddPCBObject(NewPrim);
                end;
                NewPrims.Destroy;

            end;  // OverlayPrims..
        end;      // if Selected..
        Component := CompIterator.NextPCBObject;
    End;
    Board.BoardIterator_Destroy(CompIterator);

    Close;
end;

Procedure Start;
var
    VerMajor        : integer;
    MechLayerPairs  : IPCB_MechanicalLayerPairs;
//    MechPair        : TMechanicalPair;       // IPCB_MechanicalLayerPairs.LayerPair(MechPairIdx)
    i, j            : Integer;

begin
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = nil then
    begin
        ShowMessage('Focused Doc Not a .PcbDoc ');
        exit;
    end;

    VerMajor := GetBuildNumberPart(Client.GetProductVersion, 0);

    LegacyMLS := true;
    if VerMajor >= AD19VersionMajor then
    begin
        LegacyMLS := false;
    end;

    slMechPairs := TStringList.Create;
    slMechPairs.StrictDelimiter := true;
    slMechPairs.NameValueSeparator := '=';
//  slMechSingles.("LayerName=Layer");
    slMechSingles := GetAllMechEnabledLayers(Board);

// sort into layer numeric order assending; Padleft(,4).
    for i := 0 to (slMechSingles.Count - 2) do
    begin
        for j := (i + 1) to (slMechSingles.Count - 1) do
        begin
            ML1 := PadLeft(slMechSingles.ValueFromIndex(i), 4);
            ML2 := PadLeft(slMechSingles.ValueFromIndex(j), 4);
            if ML1 > ML2 then slMechSingles.Exchange(i, j);
        end;
    end;

    MechLayerPairs  := Board.MechanicalPairs;
    for i := 0 to (slMechSingles.Count - 1) do
    begin
        LayerName1 := slMechSingles.Names(i);
        ML1        := slMechSingles.ValueFromIndex(i);

        for j := (i + 1) to (slMechSingles.Count - 1) do
        begin
            ML2 := slMechSingles.ValueFromIndex(j);

            if MechLayerPairs.PairDefined(ML1, ML2) then
            begin
                LayerName2 := slMechSingles.Names(j);
                slMechPairs.Add(LayerName1 + '=' + LayerName2);
            end;
        end;
    end;

    FormMechLayerDesignators.ShowModal;
end;

{.......................................................................................}
function GetAllMechEnabledLayers(Board : IPCB_Board) : TStringList;
var
    LIterator     : IPCB_LayerObjectIterator;
    LayerObj      : IPCB_LayerObject;
//    MechLayer     : IPCB_MechanicalLayer;
    MechLayerKind : TMechanicalKind;
    Layer         : TLayer;
    LayerName     : Widestring;

begin
    Result := TStringList.Create;
    Result.StrictDelimiter := true;
    Result.NameValueSeparator := '=';
//  Warning: Iterated LayerObjects may NOT be in any order/sorted !!
    LIterator := Board.LayerIterator;
    LIterator.AddFilter_MechanicalLayers;
    LIterator.SetBeforeFirst;
    While LIterator.Next Do
    Begin
        LayerObj  := LIterator.LayerObject;
// these have same value
//        Layer     := LayerObj.V7_LayerID.ID;
        Layer     := LIterator.Layer;
// Board.LayerName(Layer) == LayerObj.Name == LayerObj.GetState_LayerDisplayName(eLayerNameDisplay_Long)
        LayerName := LayerObj.Name;

        MechLayerKind := NoMechLayerKind;
        if not LegacyMLS then MechLayerKind := LayerObj.Kind;

        Result.Add(LayerName + '=' + IntToStr(Layer));
    end;
end;

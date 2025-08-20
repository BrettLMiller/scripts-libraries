{..............................................................................}
{ Summary   Trims or Extends tracks to the first selected track (Destination). }
{           Similar to common AutoCAD function available in many 2D/3D tools.  }
{ PcbDoc & PcbLib                                                              }
{                                                                              }
{ Created by:    Petar Perisin                                                 }
{..............................................................................

20240713 : BLM use fn to replace builtin Board.GetObjectAt..() Layer6 limitations
20250820 : BLM tidy comments etc, support PcbLib.

 Notes:
  SpatialIterator does NOT work with group primitives: dimensions & components.
  SIterator := Board.SpatialIterator_Create;

  method does not work non-spatial board iterator:
  Iterator.AddFilter_Area (x1, y2, x2, y1)

  TV6_Layerset eMech16 max. before AD16 :
  Board.GetObjectAtXYAskUserIfAmbiguous(x, y, ObjectSet, TV6_LayerSet, eEditAction_*)  
...............................................................................}
const
    cESC      =-1;
    cAltKey   = 1;
    cShiftKey = 2;
    cCntlKey  = 3;

procedure ProcessTracks(Board : IPCB_Board, DestinTrack : IPCB_Track, Track2Modify : IPCB_Track); forward;
function nGetObjectAtCursor(Board : TPCB_Board, const ObjectSet : TSet, const LayerSet : TPCB_LayerSet, const msg : TString) : IPCB_Primitive; forward;
function Magnitude(const P1, P2 : TCoordPoint) : extended; forward;
function Angle(const P1, P2 : TCoordPoint) : extended;     forward;

Procedure TrimExtend;
Var
    PCBLib           : IPCB_Library;
    Board            : IPCB_Board;
    ObjSet           : TObjectSet;
    LayerSet         : IPCB_LayerSet;
    CLayer           : TLayer;
    DestinTrack      : IPCB_Track;
    Track2Modify     : IPCB_Track;

Begin
    Board  := PCBServer.GetCurrentPCBBoard;
    PCBLib := PCBServer.GetCurrentPCBLibrary;
    if PCBLib <> nil then
        Board := PCBLib.Board;
    if Board = nil then exit;

    ObjSet   := MkSet(eTrackObject);
    CLayer   := Board.CurrentLayer;
    LayerSet := LayerSetUtils.EmptySet;
    LayerSet.Include(CLayer);

    Repeat
        DestinTrack := nGetObjectAtCursor(Board, ObjSet, LayerSet, 'Select Destination Track');
        if DestinTrack = nil then break;
        if DestinTrack = cESC then break;

        Repeat
            Track2Modify := nGetObjectAtCursor(Board, ObjSet, LayerSet, 'Select Track to Extend');
            if Track2Modify = nil then break;
            if Track2Modify = cESC then break;
//            Board.NewUndo;
            PCBServer.PreProcess;

            ProcessTracks(Board, DestinTrack, Track2Modify);

            PCBServer.PostProcess;
        until Track2Modify = cESC;
    until (DestinTrack = cESC);

    Board.ViewManager_FullUpdate;
end;

procedure ProcessTracks(Board : IPCB_Board, DestinTrack : IPCB_Track, Track2Modify : IPCB_Track);
var
    kDestin          : Float;      // gradient
    kModify          : Float;      // gradient
    ADestin          : Float;      // slope angle
    AModify          : Float;      // slope angle


    PointX, PointY   : Integer;
    CursorX, CursorY : Integer;
    helpY            : Integer;

begin
    Track2Modify.BeginModify;

// Get the cursor location - used for trim, when lines cross over
    CursorX := Board.XCursor;
    CursorY := Board.YCursor;

// test parallel and co-linear.
// both tracks vertical
    if DestinTrack.x1 = DestinTrack.x2 then
    if Track2Modify.x1 = Track2Modify.x2 then
    if Track2Modify.x1 <> DestinTrack.x1 then
    begin
        ShowMessage('Tracks are parallel and not colinear');
        exit;
    end;
// both tracks horizontal
    if DestinTrack.y1 = DestinTrack.y2 then
    if Track2Modify.y1 = Track2Modify.y2 then
    if Track2Modify.y1 <> DestinTrack.y1 then
    begin
        ShowMessage('Tracks are parallel and not colinear');
        exit;
    end; 

    ADestin := Angle(Point(DestinTrack.x1, DestinTrack.y1), Point(DestinTrack.x2, DestinTrack.y2) );

 // when DestinTrack is vertical
    if DestinTrack.x1 = DestinTrack.x2 then
    begin
        if Track2Modify.x1 <> Track2Modify.x2 then
        begin
            kModify := (Track2Modify.y2 - Track2Modify.y1) / (Track2Modify.x2 - Track2Modify.x1);

            // check if this line crosses over DestinTrack
            if ((Track2Modify.x1 <= DestinTrack.x1) and (Track2Modify.x2 <= DestinTrack.x1)) or ((Track2Modify.x1 >= DestinTrack.x1) and (Track2Modify.x2 >= DestinTrack.x1)) then
            begin
                // Tracks do not cross over

                // Now we need to figure out which endpoint of Track2Modify is closer to DestinTrack
                if Abs(Track2Modify.x1 - DestinTrack.x1) < Abs(Track2Modify.x2 - DestinTrack.x1) then
                begin
                    // Track2Modify.x1 is closer
                    Track2Modify.y1 := Track2Modify.y1 + Int(kModify * (DestinTrack.x1 - Track2Modify.x1));
                    Track2Modify.x1 := DestinTrack.x1;
                end else
                begin
                    // Track2Modify.x2 is closer
                    Track2Modify.y2 := Track2Modify.y2 + Int(kModify * (DestinTrack.x2 - Track2Modify.x2));
                    Track2Modify.x2 := DestinTrack.x2;
                end;
            end else
            begin
                  // Lines cross over, DestinTrack is vertical
                if CursorX < DestinTrack.x1 then
                begin
                     // keep left side

                     // check which point is on the left side
                    if Track2Modify.x2 < DestinTrack.x1 then
                    begin
                        // modify Track2Modify.x1
                        Track2Modify.y1 := Track2Modify.y1 + Int(kModify * (DestinTrack.x1 - Track2Modify.x1));
                        Track2Modify.x1 := DestinTrack.x1;
                    end else
                    begin
                        // modify Track2Modify.x2
                        Track2Modify.y2 := Track2Modify.y2 + Int(kModify * (DestinTrack.x2 - Track2Modify.x2));
                        Track2Modify.x2 := DestinTrack.x2;
                    end;
                end else
                begin
                     // Keep right side

                     // check which point is on the right side
                     if Track2Modify.x2 > DestinTrack.x1 then
                     begin
                        // modify Track2Modify.x1
                        Track2Modify.y1 := Track2Modify.y1 + Int(kModify * (DestinTrack.x1 - Track2Modify.x1));
                        Track2Modify.x1 := DestinTrack.x1;
                     end else
                     begin
                        // modify Track2Modify.x2
                        Track2Modify.y2 := Track2Modify.y2 + Int(kModify * (DestinTrack.x2 - Track2Modify.x2));
                        Track2Modify.x2 := DestinTrack.x2;
                     end;
                end;
            end;
        end
        else ShowMessage('Tracks are parallel');
    end;

    if DestinTrack.x1 <> DestinTrack.x2 then
    begin
        // calculate gradient for destination track
        kDestin := (DestinTrack.y2 - DestinTrack.y1)/(DestinTrack.x2 - DestinTrack.x1);

        if Track2Modify.x1 <> Track2Modify.x2 then
        begin
            kModify := (Track2Modify.y2 - Track2Modify.y1)/(Track2Modify.x2 - Track2Modify.x1);

            if Abs(kDestin - kModify) < 0.1 then
                ShowMessage('Tracks are parallel')
            else
            begin

                // find intersection point of line functions.
                PointX := Int((DestinTrack.y1 - Track2Modify.y1 + (kModify * Track2Modify.x1) - (kDestin * Destintrack.x1)) / (kModify - kDestin));
                PointY := int(Track2Modify.y1 + kModify * (PointX - Track2Modify.x1));

                // find if the 2 lines cross/touch
                if ((Track2Modify.x1 <= PointX) and (Track2Modify.x2 <= PointX)) or ((Track2Modify.x1 >= PointX) and (Track2Modify.x2 >= PointX)) then
                begin
                    // tracks do not cross or touch

                    // test which endpoint from Track2Modify is closer to DestinTrack
                    if Abs(Track2Modify.x1 - PointX) < Abs(Track2Modify.x2 - PointX) then
                    begin
                        // Track2Modify.x1 is closer
                        Track2Modify.x1 := PointX;
                        Track2Modify.y1 := PointY;
                    end else
                    begin
                        // Track2Modify.x2 is closer
                        Track2Modify.x2 := PointX;
                        Track2Modify.y2 := PointY;
                    end;
                end else
                begin
                    // Lines cross over, they are not vertical

                    // test if point is above or below DestinTrack
                    helpY := DestinTrack.y1 + Int(kDestin * (CursorX - DestinTrack.x1));

                    if CursorY < helpY then
                    begin
                        // keep part under axis

                        // test which endpoint of Track2Modify is above the DestinTrack
                        helpY := DestinTrack.y1 + Int(kDestin * (Track2Modify.x1 - DestinTrack.x1));

                        if Track2Modify.y1 < helpY then
                        begin
                            // first point is under DestinTrack - modify second point
                            Track2Modify.x2 := PointX;
                            Track2Modify.y2 := PointY;
                        end else
                        begin
                            // first point is above DestinTrack - modify it
                            Track2Modify.x1 := PointX;
                            Track2Modify.y1 := PointY;
                        end;
                    end else
                    begin
                        // keep part above axis

                        // test if point of Track2Modify is under the DestinTrack
                        helpY := DestinTrack.y1 + Int(kDestin * (Track2Modify.x1 - DestinTrack.x1));

                        if Track2Modify.y1 > helpY then
                        begin
                            // first point is above DestinTrack - modify second point
                            Track2Modify.x2 := PointX;
                            Track2Modify.y2 := PointY;
                        end else
                        begin
                            // first point is under DestinTrack - modify it
                            Track2Modify.x1 := PointX;
                            Track2Modify.y1 := PointY;
                        end;
                    end;
                end;
            end;
        end;

     // vertical Track2Modify line.
        if Track2Modify.x1 = Track2Modify.x2 then
        begin
            // check it crosses over DestinTrack
            PointY := DestinTrack.y1 + Int(kDestin * (Track2Modify.x1 - DestinTrack.x1));

            // Check whether lines cross over
            if ((Track2Modify.y1 <= PointY) and (Track2Modify.y2 <= PointY)) or ((Track2Modify.y1 >= PointY) and (Track2Modify.y2 >= PointY)) then
            begin
                // 2 lines do not cross over

                // Find point closer to DestinTrack
                if Abs(Track2Modify.y1 - PointY) < Abs(Track2Modify.y2 - PointY) then
                    // Track2Modify.y1 is closer
                    Track2Modify.y1 := PointY
                else
                    // Track2Modify.y2 is closer
                    Track2Modify.y2 := PointY;
            end else
            begin
                // Lines cross over, Track2Modify is vertical
                if CursorY < PointY then
                begin
                    // keep lower part : check which point is under
                    if Track2Modify.y2 < PointY then
                        // modify Track2Modify.y1
                        Track2Modify.y1 := PointY
                    else
                        // modify Track2Modify.y2
                        Track2Modify.y2 := PointY;
                end else
                begin
                    // keep upper part : check which point is above
                    if Track2Modify.y2 > PointY then
                        // modify .y1
                        Track2Modify.y1 := PointY
                    else
                        // modify .y2
                        Track2Modify.y2 := PointY;
                end;
            end;
        end;
    end;

    Track2Modify.GraphicallyInvalidate;
    Track2Modify.EndModify;
end;

function nGetObjectAtCursor(Board : TPCB_Board, const ObjectSet: TObjectSet,  const LayerSet : TPCB_LayerSet, const msg : TString) : IPCB_Primitive;
var
    x, y          : TCoord;
    Iterator      : IPCB_BoardIterator;
    Prim          : IPCB_Primitive;
    BRect         : TCoordRect;

begin
    Result := eNoObject;

    if Board.ChooseLocation(x, y, msg) then  // false = ESC Key is pressed
    begin
        if Result = eNoObject then
        begin
            Iterator := Board.BoardIterator_Create;
            Iterator.SetState_FilterAll;
            Iterator.AddFilter_IPCB_LayerSet(LayerSet);
            Iterator.AddFilter_ObjectSet(ObjectSet);

            Prim := Iterator.FirstPCBObject;
            while (Prim <> Nil) do
            begin
                BRect := Prim.BoundingRectangle;                 //  ShrinkBoundingRectangle(Prim.BoundingRectangle);

                if (BRect.X1 < x) and (BRect.X2 > x) and  (BRect.Y1 < y) and (BRect.Y2 > y) then
                    Result := Prim;

                Prim := Iterator.NextPCBObject;
            end;
            Board.BoardIterator_Destroy(Iterator);
        end;
    end
    else
        Result := cESC;
end;

function Magnitude(const P1, P2 : TCoordPoint) : extended;
begin
    Result := Power(P2.x - P1.x, 2) + Power(P2.y - P1.y, 2);
    Result := Sqrt(Result);
end;

function Angle(const P1, P2 : TCoordPoint) : extended;
begin
    Result := ArcCos((P2.x - P1.x) / Magnitude(P1, P2) );
end;

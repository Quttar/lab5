program lab5;

uses windows,messages, {���������� � ��������� DLL}
     sysUtils; {��������� ������� ������ ��� �������������� ����� � �.�.}

function WndProc(hWnd: THandle; Msg: integer;
                 wParam: longint; lParam: longint): longint;
                 stdcall; forward;

var xOffset:integer; //���������� ��� ����������� ����������
    yOffset:integer;
    timeStamp:longword;
    leftButtonPressed:bool;
    xLinePrev:integer;
    yLinePrev:integer;
    drawColorBrush:COLORREF;
    drawColorPen:COLORREF;
    drawWidth:integer;
    rgbPenIndex:integer;
    rgbPenEnable:bool;

    colorTable: array[0..7] of COLORREF;

procedure WinMain; {�������� ���� ��������� ���������}
  const szClassName='Shablon';
  var   wndClass:TWndClassEx;
        hWnd: THandle;
        msg:TMsg;
begin
  wndClass.cbSize:=sizeof(wndClass);
  wndClass.style:=cs_hredraw or cs_vredraw;
  wndClass.lpfnWndProc:=@WndProc;
  wndClass.cbClsExtra:=0;
  wndClass.cbWndExtra:=0;
  wndClass.hInstance:=hPrevInst;
  wndClass.hInstance:=hInstance;
  wndClass.hIcon:=loadIcon(0, idi_Application);
  wndClass.hCursor:=loadCursor(0, idc_Arrow);
  wndClass.hbrBackground:=GetStockObject(white_Brush);
  wndClass.lpszMenuName:=nil;
  wndClass.lpszClassName:=szClassName;
  wndClass.hIconSm:=loadIcon(0, idi_Application);

  RegisterClassEx(wndClass);

  hwnd:=CreateWindowEx(
         0,
         szClassName, {��� ������ ����}
         'Paint Lite',    {��������� ����}
         ws_overlappedWindow,     {����� ����}
         cw_useDefault,           {Left}
         cw_useDefault,           {Top}
         800,                     {Width}
         800,                     {Height}
         0,                       {����� ������������� ����}
         0,                       {����� �������� ����}
         hInstance,               {����� ���������� ����������}
         nil);                    {��������� �������� ����}

  ShowWindow(hwnd,sw_Show);  {���������� ����}
  updateWindow(hwnd);   {������� wm_paint ������� ���������, ����������
                         ���� ����� ������� ��������� (�������������)}

  xOffset:=0; //���������� ��� ����������� ����������
  yOffset:=0;
  timeStamp:=0;

  while GetMessage(msg,0,0,0) do begin {�������� ��������� ���������}
    TranslateMessage(msg);   {Windows ����������� ��������� �� ����������}
    DispatchMessage(msg);    {Windows ������� ������� ���������}
  end; {����� �� wm_quit, �� ������� GetMessage ������ FALSE}
end;

function RgbPenFunction(x: integer):integer;
begin
  result := 0;
  if ((x >= 768) and (x <= 1279)) then result := 255;
  if ((x >= 512) and (x <= 767)) then result := x - 512;
  if ((x >= 1280) and (x <= 1535)) then result := 1535 - x;
end;

function WndProc(hWnd: THandle; Msg: integer; wParam: longint; lParam: longint): longint; stdcall;

  var ps:TPaintStruct;
      hdc:THandle;
      rect:TRect;
      s:shortstring; //������ ��� � �����-�������
      moveFlag:boolean;

      hBrush:THandle;
      hPen:THandle;
      xPos:integer;
      yPos:integer;
begin
  result:=0;

  

  case Msg of
    wm_create:
      begin
        leftButtonPressed := false; //��� ������ ��������� ����� ������ ���� �� ������

        //������� ������
        colorTable[0] := RGB(0, 192, 0); //��������
        colorTable[1] := RGB(192, 0, 0); //�������
        colorTable[2] := RGB(0, 0, 192); //�����
        colorTable[3] := RGB(240, 240, 0); //������
        colorTable[4] := RGB(0, 240, 240); //�������
        colorTable[5] := RGB(255,192,203); //�������
        colorTable[6] := RGB(139,0,255); //����������
        colorTable[7] := RGB(255, 255, 255); //�����

        drawColorBrush := colorTable[1]; //���� �����
        drawColorPen := colorTable[0]; //���� ����
        drawWidth := 100; //������� ����� ��� ���������

        rgbPenEnable := false; //�������� �� rgb ����
        rgbPenIndex := 0; //������� ���� rgb ����
      end;

    {wm_paint:
      begin
        //SetWindowText(hwnd, PChar('TimeStamp = ' + intToStr(TimeStamp)));

        hdc:=BeginPaint(hwnd,ps); //������� WM_PAINT �� ������� � ������ ���������
        //Ellipse(hdc, 300, 300, 500, 500);

        endPaint(hwnd,ps);
      end;}

    {WM_KEYDOWN:
      begin
        //SetWindowText(hwnd, 'wm_keydown');

        moveFlag:=true;
        case wParam of
          vk_up: dec(yOffset); // �������� ������� ���������
          vk_down: inc(yOffset);
          vk_left: dec(xOffset);
          vk_right: inc(xOffset);
          vk_escape: begin xOffset:=0; yOffset:=0; end; // ������� �� ���������
        else
          moveFlag:=false; // ����� ������� �� ���������
        end;
        if moveFlag then begin // ���� ������� ���������
          invalidaterect(hwnd,nil,true);
          updateWindow(hwnd); //������������ ���� ������ ��, �� ��������� ����������� �������
        end;
      end;}

    WM_LBUTTONDOWN:
      begin
        SetCapture(hwnd);
        leftButtonPressed := true;

        xLinePrev := smallint(LOWORD(lParam));
        yLinePrev := smallint(HIWORD(lParam));

        hdc := GetDC(hwnd);

        hPen := SelectObject(hdc, CreatePen(PS_SOLID, 1, drawColorPen));
        hBrush := SelectObject(hdc, CreateSolidBrush(drawColorPen));

        Ellipse(hdc, xLinePrev - drawWidth div 2, yLinePrev - drawWidth div 2, xLinePrev + drawWidth div 2, yLinePrev + drawWidth div 2);

        DeleteObject(SelectObject(hdc, hBrush));
        DeleteObject(SelectObject(hdc, hPen));
        ReleaseDC(hwnd, hdc);
      end;

    WM_LBUTTONUP:
      begin
        ReleaseCapture();
        leftButtonPressed := false;
      end;

    WM_RBUTTONDOWN:
      begin
        xPos := smallint(LOWORD(lParam));
        yPos := smallint(HIWORD(lParam));

        hdc := GetDC(hwnd);
        hBrush := SelectObject(hdc, CreateSolidBrush(drawColorBrush));
        ExtFloodFill(hdc, xPos, yPos, GetPixel(hdc, xPos, yPos), FLOODFILLSURFACE);
        DeleteObject(SelectObject(hdc, hBrush));
        ReleaseDC(hwnd, hdc);
      end;

    WM_MOUSEMOVE:
      if leftButtonPressed then begin
        //����� ����� ��� rgb ����
        if (rgbPenEnable) then
        begin
          rgbPenIndex := (rgbPenIndex + 10) mod 1536;
          drawColorPen := RGB(RgbPenFunction(rgbPenIndex), RgbPenFunction((rgbPenIndex + 1024) mod 1536), RgbPenFunction((rgbPenIndex + 512) mod 1536));
          //SetWindowText(hwnd, PChar('rgbPenIndex = ' + IntToStr(rgbPenIndex) + '  Fg(x) = ' + IntToStr(RgbPenFunction((rgbPenIndex + 1024) mod 1536))));
        end;


        xPos := smallint(LOWORD(lParam));
        yPos := smallint(HIWORD(lParam));

        //SetWindowText(hwnd, PChar('Coordintates: ' + intToStr(xPos) + '; ' + intToStr(yPos)));

        hdc := GetDC(hwnd);

        hPen := SelectObject(hdc, CreatePen(PS_SOLID, drawWidth, drawColorPen));

        MoveToEx(hdc, xLinePrev, yLinePrev, nil);
        LineTo(hdc, xPos, yPos);
        xLinePrev := xPos;
        yLinePrev := yPos;

        DeleteObject(SelectObject(hdc, hPen));

        ReleaseDC(hwnd, hdc);
      end;

    WM_KEYDOWN:
      begin


        //���� ����
        if ((wParam >= byte('1')) and (wParam <= byte('8'))) then
        begin
          rgbPenEnable := false; //��������� rgb ����
          drawColorPen := colorTable[wParam - byte('1')];
        end;

        //���� �������
        if ((wParam >= VK_F1) and (wParam <= VK_F8)) then
        begin
          drawColorBrush := colorTable[wParam - VK_F1];
        end;

        //RGB ����
        if (wParam = byte('9')) then
        begin
            rgbPenEnable := true;
        end;

      end;
    {wm_timer:
      if timeStamp>0 then begin // ���� ����� �� ����, �� �� ����� ��������������
        invalidateRect(hwnd,nil,true);
      end;}

    wm_destroy:
      begin
        //killTimer(hwnd,0);
        PostQuitMessage(0);
      end;

    else
      result:=DefWindowProc(hwnd,msg,wparam,lparam);
  end;
end;



begin
  //����������� beta
  //�����-�� �������
  //English comment
  WinMain;
end.

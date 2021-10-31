program lab5;

uses windows,messages, {èíòåðôåéñû ê ñèñòåìíûì DLL}
     sysUtils; {Ñëóæåáíûå ôóíêöèè Äåëüôè äëÿ ôîðìàòèðîâàíèÿ ñòðîê è ò.ä.}

function WndProc(hWnd: THandle; Msg: integer;
                 wParam: longint; lParam: longint): longint;
                 stdcall; forward;

var xOffset:integer; //Ôàêòè÷åñêè ýòî ñòàòè÷åñêèå ïåðåìåííûå
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

procedure WinMain; {Îñíîâíîé öèêë îáðàáîòêè ñîîáùåíèé}
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
         szClassName, {èìÿ êëàññà îêíà}
         'Paint Lite',    {çàãîëîâîê îêíà}
         ws_overlappedWindow,     {ñòèëü îêíà}
         cw_useDefault,           {Left}
         cw_useDefault,           {Top}
         800,                     {Width}
         800,                     {Height}
         0,                       {õýíäë ðîäèòåëüñêîãî îêíà}
         0,                       {õýíäë îêîííîãî ìåíþ}
         hInstance,               {õýíäë ýêçåìïëÿðà ïðèëîæåíèÿ}
         nil);                    {ïàðàìåòðû ñîçäàíèÿ îêíà}

  ShowWindow(hwnd,sw_Show);  {îòîáðàçèòü îêíî}
  updateWindow(hwnd);   {ïîñëàòü wm_paint îêîííîé ïðîöåäóðå, ïðîðèñîâàâ
                         îêíî ìèíóÿ î÷åðåäü ñîîáùåíèé (íåîáÿçàòåëüíî)}

  xOffset:=0; //Ôàêòè÷åñêè ýòî ñòàòè÷åñêèå ïåðåìåííûå
  yOffset:=0;
  timeStamp:=0;

  while GetMessage(msg,0,0,0) do begin {ïîëó÷èòü î÷åðåäíîå ñîîáùåíèå}
    TranslateMessage(msg);   {Windows òðàíñëèðóåò ñîîáùåíèÿ îò êëàâèàòóðû}
    DispatchMessage(msg);    {Windows âûçîâåò îêîííóþ ïðîöåäóðó}
  end; {âûõîä ïî wm_quit, íà êîòîðîå GetMessage âåðíåò FALSE}
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
      s:shortstring; //Ñòðîêà êàê â Òóðáî-Ïàñêàëå
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
        leftButtonPressed := false; //Ïðè ñòàðòå ïðîãðàììû ëåâàÿ êíîïêà ìûøè íå íàæàòà

        //Òàáëèöà öâåòîâ
        colorTable[0] := RGB(0, 192, 0); //Çåëåííûé
        colorTable[1] := RGB(192, 0, 0); //Êðàñíûé
        colorTable[2] := RGB(0, 0, 192); //Ñèíèé
        colorTable[3] := RGB(240, 240, 0); //Æåëòûé
        colorTable[4] := RGB(0, 240, 240); //Ãîëóáîé
        colorTable[5] := RGB(255,192,203); //Ðîçîâûé
        colorTable[6] := RGB(139,0,255); //Ôåîëåòîâûé
        colorTable[7] := RGB(255, 255, 255); //Áåëûé

        drawColorBrush := colorTable[1]; //Öâåò êèñòè
        drawColorPen := colorTable[0]; //Öâåò ïåðà
        drawWidth := 100; //Òîëùèíà ëèíèè ïðè ðèñîâàíèè

        rgbPenEnable := false; //Âêëþ÷åíî ëè rgb ïåðî
        rgbPenIndex := 0; //Òåêóùèé öâåò rgb ïåðà
      end;

    {wm_paint:
      begin
        //SetWindowText(hwnd, PChar('TimeStamp = ' + intToStr(TimeStamp)));

        hdc:=BeginPaint(hwnd,ps); //Óäàëèòü WM_PAINT èç î÷åðåäè è íà÷àòü ðèñîâàíèå
        //Ellipse(hdc, 300, 300, 500, 500);

        endPaint(hwnd,ps);
      end;}

    {WM_KEYDOWN:
      begin
        //SetWindowText(hwnd, 'wm_keydown');

        moveFlag:=true;
        case wParam of
          vk_up: dec(yOffset); // Äâèæåíèå íàäïèñè ñòðåëêàìè
          vk_down: inc(yOffset);
          vk_left: dec(xOffset);
          vk_right: inc(xOffset);
          vk_escape: begin xOffset:=0; yOffset:=0; end; // Âåðíóòü ïî óìîë÷àíèþ
        else
          moveFlag:=false; // èíà÷å íàäïèñü íå äâèãàëàñü
        end;
        if moveFlag then begin // Åñëè íàäïèñü äâèãàëàñü
          invalidaterect(hwnd,nil,true);
          updateWindow(hwnd); //Ïåðåðèñîâàòü îêíî ñåé÷àñ æå, íå äîæèäàÿñü îïóñòîøåíèÿ î÷åðåäè
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
        //Ñìåíà öâåòà äëÿ rgb ïåðà
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


        //Öâåò ïåðà
        if ((wParam >= byte('1')) and (wParam <= byte('8'))) then
        begin
          rgbPenEnable := false; //Îòêëþ÷àåì rgb ïåðî
          drawColorPen := colorTable[wParam - byte('1')];
        end;

        //Öâåò çàëèâêè
        if ((wParam >= VK_F1) and (wParam <= VK_F8)) then
        begin
          drawColorBrush := colorTable[wParam - VK_F1];
        end;

        //RGB ïåðî
        if (wParam = byte('9')) then
        begin
            rgbPenEnable := true;
        end;

      end;
    {wm_timer:
      if timeStamp>0 then begin // Åñëè âðåìÿ íå èäåò, òî íå íóæíî ïåðåðèñîâûâàòü
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
  //Êîììåíòàðèé beta
  //Êàêîé-òî êîììåíò
  //English comment
  //Äîáàâëåí êîììåíò
  //english comment
  WinMain;
end.

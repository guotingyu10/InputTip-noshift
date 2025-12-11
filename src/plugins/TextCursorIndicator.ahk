; Text Cursor Indicator Plugin
; 功能: 在文本光标处显示一个颜色指示器，颜色随鼠标悬停变化
; 1. 实时获取文本光标位置
; 2. 在光标位置显示一个细长的彩色矩形
; 3. 颜色跟随鼠标悬停变化 (示例逻辑：鼠标移动时改变颜色)

global TCI_Gui := ""
global TCI_Color := "Red" ; 默认颜色
global TCI_Enabled := true

; 初始化插件
TCI_Init()

TCI_Init() {
    global TCI_Gui
    ; 创建指示器 GUI
    try {
        ; 使用 createGuiOpt 保持一致性，如果不可用则回退
        TCI_Gui := createGuiOpt("TextCursorIndicator", ["s1", "Microsoft YaHei"], "-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 +E0x20")
    } catch {
        TCI_Gui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 +E0x20", "TextCursorIndicator")
    }
    
    TCI_Gui.BackColor := TCI_Color
    TCI_Gui.Show("NA NoActivate w2 h20 x-100 y-100") ; 初始隐藏在屏幕外
    
    ; 启动定时器更新位置和颜色
    SetTimer(TCI_Update, 50)
}

; 开关快捷键 Ctrl+Shift+F11
^+F11:: {
    global TCI_Enabled, TCI_Gui
    TCI_Enabled := !TCI_Enabled
    if (TCI_Enabled) {
        SetTimer(TCI_Update, 50)
        ToolTip("文本光标指示器已开启")
        SetTimer(() => ToolTip(), -2000)
    } else {
        SetTimer(TCI_Update, 0) ; 关闭定时器
        TCI_Gui.Move(-100, -100) ; 隐藏 GUI
        ToolTip("文本光标指示器已关闭")
        SetTimer(() => ToolTip(), -2000)
    }
}

TCI_Update() {
    if (!TCI_Enabled || !IsObject(TCI_Gui))
        return

    ; 获取光标位置
    if (GetCaretPosEx(&left, &top, &right, &bottom)) {
        x := left
        y := top
        h := bottom - top
        
        ; 如果高度异常（例如 0），设置默认高度
        if (h <= 0)
            h := 20
            
        ; 更新 GUI 位置和大小
        try {
            TCI_Gui.Move(x, y, 2, h)
            
            ; 根据鼠标位置改变颜色 (示例逻辑)
            ; 这里实现"跟随鼠标颜色变化"的字面意思：根据鼠标在屏幕的位置计算颜色
            MouseGetPos(&mx, &my)
            
            ; 简单的颜色变换算法：根据鼠标 X 坐标改变红色分量，Y 坐标改变绿色分量
            ; 为了效果明显，使用 HSV 或简单的 RGB 映射
            screenWidth := A_ScreenWidth
            screenHeight := A_ScreenHeight
            
            r := Mod(Round((mx / screenWidth) * 255), 255)
            g := Mod(Round((my / screenHeight) * 255), 255)
            b := 128 ; 固定蓝色分量
            
            newColor := Format("{:02X}{:02X}{:02X}", r, g, b)
            
            if (TCI_Gui.BackColor != newColor) {
                TCI_Gui.BackColor := newColor
            }
            
            ; 确保窗口显示 (如果之前被隐藏)
            if (!WinExist("ahk_id " TCI_Gui.Hwnd)) {
                TCI_Gui.Show("NA NoActivate")
            }
            
        } catch {
            ; 忽略错误
        }
    } else {
        ; 如果获取不到光标位置，隐藏指示器
        TCI_Gui.Move(-100, -100)
    }
}

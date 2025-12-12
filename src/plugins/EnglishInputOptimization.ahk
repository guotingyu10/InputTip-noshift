; English Input Optimization Plugin
; 功能: 英文状态下，长按字母变大写，长按数字变符号，长按标点变Shift+标点
; 包含倒计时显示和开关功能

; 配置 (单位: 秒)
global EIO_DelayX := 0.5  ; 字母
global EIO_DelayY := 0.5  ; 数字
global EIO_DelayZ := 0.5  ; 标点

; 样式配置


; 开关配置
global EIO_ShowCountdown := true
global EIO_CountdownGui := ""
global EIO_CountdownParams := {}

; 全局开关
global EIO_Enabled := 0 ; 0关闭 1开启

; 初始化
EIO_Init()

EIO_Init() {
    ; 辅助函数: 读取配置并处理注释和类型转换
    ReadOpt(key, defaultVal, isNum := false) {
        val := readIni(key, defaultVal, "EnglishInputOptimization")
        if (InStr(val, ";"))
            val := StrSplit(val, ";")[1]
        val := Trim(val)
        if (isNum && IsNumber(val))
            return Number(val)
        return val
    }

    ; 读取配置
    global EIO_Enabled := ReadOpt("EnglishInputOptimization_Enable", 1, true)
    global EIO_FontSize := ReadOpt("EIO_FontSize", 20, true)
    global EIO_FontName := ReadOpt("EIO_FontName", "Microsoft YaHei")
    global EIO_FontColor := ReadOpt("EIO_FontColor", "Gray")
    global EIO_BgColor := ReadOpt("EIO_BgColor", "010101")
    global EIO_BgTransparent := ReadOpt("EIO_BgTransparent", 1, true)
    global EIO_PosType := ReadOpt("EIO_PosType", 2, true)
    global EIO_PosX := ReadOpt("EIO_PosX", 1000, true)
    global EIO_PosY := ReadOpt("EIO_PosY", 300, true)
    global EIO_ShowCountdown := ReadOpt("EIO_ShowCountdown", 1, true)

    try {
        A_TrayMenu.Add()
        A_TrayMenu.Add("英文输入优化配置", EIO_ShowConfigGui)
    }

    if (!EIO_Enabled) {
        return
    }

    ; 字母 a-z
    Loop 26 {
        key := Chr(Ord("a") + A_Index - 1)
        Hotkey("$" key, EIO_Bind(key, EIO_DelayX))
    }
    
    ; 数字 0-9
    Loop 10 {
        key := String(A_Index - 1)
        Hotkey("$" key, EIO_Bind(key, EIO_DelayY, "+" key))
    }
    
    ; 标点 [];',./\-=`
    punctuations := ["[", "]", ";", "'", ",", ".", "/", "\", "-", "="]
    for key in punctuations {
        Hotkey("$" key, EIO_Bind(key, EIO_DelayZ))
    }
}

EIO_ShowConfigGui(*) {
    try {
        if (FileExist("InputTip.ini")) {
            Run("InputTip.ini")
            MsgBox("请在打开的配置文件中找到 [EnglishInputOptimization] 部分进行修改。`n修改完成后保存文件，重启软件生效。", "配置说明", "Iconi")
        } else {
            MsgBox("配置文件 InputTip.ini 不存在", "错误", "Icon!")
        }
    }
}

EIO_Bind(key, delay, shiftKey := "") {
    return (*) => EIO_HandleKey(key, delay, shiftKey)
}

EIO_HandleKey(key, delay, shiftKey := "") {
    ; 检查输入法状态 (1: 中文, 0: 英文)
    try {
        if (IME.GetInputMode()) {
            SendInput("{Blind}" key)
            return
        }
    } catch {
        SendInput("{Blind}" key)
        return
    }
    
    ; 开始倒计时显示
    if (EIO_ShowCountdown) {
        EIO_StartCountdown(key, delay, shiftKey)
    }
    
    if !KeyWait(key, "T" delay) {
        ; 长按触发
        if (EIO_ShowCountdown) {
            EIO_StopCountdown()
        }
        
        if (shiftKey == "") {
            SendInput("+" key)
        } else {
            SendInput(shiftKey)
        }
        KeyWait(key)
    } else {
        ; 短按触发
        if (EIO_ShowCountdown) {
            EIO_StopCountdown()
        }
        SendInput("{Blind}" key)
    }
}

EIO_StartCountdown(key, delay, shiftKey) {
    global EIO_CountdownGui, EIO_CountdownParams
    
    EIO_CountdownParams := { start: A_TickCount, delay: delay, key: key, shift: shiftKey }
    
    try {
        if (EIO_CountdownGui) {
            try {
                EIO_CountdownGui.Destroy()
            }
        }
        
        ; 构建字体选项
        fontOptStr := "s" EIO_FontSize " c" EIO_FontColor
        
        ; 尝试使用项目提供的 createGuiOpt 以保持一致性，如果不可用则回退到普通 Gui
        try {
             ; +E0x20 (WS_EX_TRANSPARENT) 点击穿透
             EIO_CountdownGui := createGuiOpt("EIO_Countdown", [fontOptStr, EIO_FontName], "-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 +E0x20") 
        } catch {
             EIO_CountdownGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 +E0x20", "EIO_Countdown")
             EIO_CountdownGui.SetFont(fontOptStr, EIO_FontName)
        }
        
        ; 设置背景色
        EIO_CountdownGui.BackColor := EIO_BgColor
        if (EIO_BgTransparent) {
            WinSetTransColor(EIO_BgColor, EIO_CountdownGui)
        }
        
        EIO_CountdownGui.Add("Text", "vTxt Center", "                  ")
        
        ; 先隐藏显示以计算 AutoSize
        EIO_CountdownGui.Show("Hide AutoSize")
        
        ; 计算位置
        EIO_GetPosition(&x, &y, EIO_CountdownGui)
        
        ; 显示在指定位置
        EIO_CountdownGui.Show("NA NoActivate x" x " y" y)
        
        SetTimer(EIO_UpdateCountdown, 20)
    }
}

EIO_StopCountdown() {
    global EIO_CountdownGui
    SetTimer(EIO_UpdateCountdown, 0)
    if (EIO_CountdownGui) {
        try {
            EIO_CountdownGui.Destroy()
        }
        EIO_CountdownGui := ""
    }
}

EIO_UpdateCountdown() {
    global EIO_CountdownGui, EIO_CountdownParams
    if (!EIO_CountdownGui)
        return

    elapsed := (A_TickCount - EIO_CountdownParams.start) / 1000
    remaining := EIO_CountdownParams.delay - elapsed
    if (remaining < 0)
        remaining := 0
    
    ; 显示格式: 0.00
    txt := Format("{:.2f}", remaining)
    
    try {
        EIO_CountdownGui["Txt"].Value := txt
        
        EIO_GetPosition(&x, &y, EIO_CountdownGui)
        
        EIO_CountdownGui.Move(x, y)
    }
}

EIO_GetPosition(&x, &y, guiObj) {
    x := 0, y := 0
    
    if (EIO_PosType == 1) { ; Screen Center
        guiObj.GetPos(,, &w, &h)
        x := (A_ScreenWidth - w) / 2
        y := (A_ScreenHeight - h) / 2
    } else if (EIO_PosType == 2) { ; Custom
        x := EIO_PosX
        y := EIO_PosY
    } else { ; Follow Cursor/Mouse
        gotPos := false
        ; 尝试获取光标位置 (需要 InputTip 主程序环境)
        try {
            if (GetCaretPosEx(&left, &top, &right, &bottom)) {
                x := right + 10
                y := top
                gotPos := true
            }
        }
        
        if (!gotPos) {
            MouseGetPos(&x, &y)
            x += 20
            y += 20
        }
    }
}


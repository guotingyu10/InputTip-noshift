; English Input Optimization Plugin
; 功能: 英文状态下，长按字母变大写，长按数字变符号，长按标点变Shift+标点
; 包含倒计时显示和开关功能

; 配置 (单位: 秒)
global EIO_DelayX := 0.5  ; 字母
global EIO_DelayY := 0.5  ; 数字
global EIO_DelayZ := 0.5  ; 标点

; 开关配置
global EIO_ShowCountdown := true
global EIO_CountdownGui := ""
global EIO_CountdownParams := {}

; 初始化
EIO_Init()

; 注册开关热键 (Ctrl+Shift+F12)
Hotkey("^+F12", EIO_ToggleSwitch)

EIO_Init() {
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
        
        ; 尝试使用项目提供的 createGuiOpt 以保持一致性，如果不可用则回退到普通 Gui
        try {
             ; +E0x20 (WS_EX_TRANSPARENT) 点击穿透
             EIO_CountdownGui := createGuiOpt("EIO_Countdown", ["s10", "Microsoft YaHei", "cGray"], "-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 +E0x20") 
        } catch {
             EIO_CountdownGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner +E0x08000000 +E0x20", "EIO_Countdown")
             EIO_CountdownGui.SetFont("s10 cGray", "Microsoft YaHei")
        }
        
        ; 设置背景色并透明化
        EIO_CountdownGui.BackColor := "010101"
        WinSetTransColor("010101", EIO_CountdownGui)
        
        EIO_CountdownGui.Add("Text", "vTxt Center", "                  ")
        
        EIO_CountdownGui.Show("NA AutoSize NoActivate")
        
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
        
        x := 0, y := 0
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
        
        EIO_CountdownGui.Move(x, y)
    }
}

EIO_ToggleSwitch(*) {
    global EIO_ShowCountdown
    EIO_ShowCountdown := !EIO_ShowCountdown
    state := EIO_ShowCountdown ? "ON" : "OFF"
    ToolTip("English Input Optimization Countdown: " state)
    SetTimer(() => ToolTip(), -2000)
}

; InputTip - CopyTip Plugin
; 当复制内容时，提示"复制:'复制的内容的第一行'"

#Requires AutoHotkey v2.0

class CopyTip {
    static Enable := 1
    static FontSize := 12
    static FontName := "Microsoft YaHei"
    static BgColor := "333333"
    static FontColor := "FFFFFF"
    static Duration := 1500
    static PosType := 0 ; 0=Follow Mouse, 1=Screen Center, 2=Custom
    static PosX := 0
    static PosY := 0
    static GuiObj := ""
    static TimerFn := ""
    
    static Init() {
        this.Enable := readIni("CopyTip_Enable", 1, "CopyTip")
        this.FontSize := readIni("CopyTip_FontSize", 12, "CopyTip")
        this.FontName := readIni("CopyTip_FontName", "Microsoft YaHei", "CopyTip")
        this.BgColor := readIni("CopyTip_BgColor", "333333", "CopyTip")
        this.FontColor := readIni("CopyTip_FontColor", "FFFFFF", "CopyTip")
        this.Duration := readIni("CopyTip_Duration", 1500, "CopyTip")
        this.PosType := readIni("CopyTip_PosType", 0, "CopyTip")
        this.PosX := readIni("CopyTip_PosX", 0, "CopyTip")
        this.PosY := readIni("CopyTip_PosY", 0, "CopyTip")
        
        if (this.Enable) {
            OnClipboardChange(this.HandleClipboardChange.Bind(this))
        }
        
        try {
            A_TrayMenu.Add()
            A_TrayMenu.Add("复制提示配置", this.ShowConfigGui.Bind(this))
        }
    }
    
    static ShowConfigGui(*) {
        try {
            if (FileExist("InputTip.ini")) {
                Run("InputTip.ini")
                MsgBox("请在打开的配置文件中找到 [CopyTip] 部分进行修改。`n修改完成后保存文件，重启软件生效。", "配置说明", "Iconi")
            } else {
                MsgBox("配置文件 InputTip.ini 不存在", "错误", "Icon!")
            }
        }
    }
    
    static HandleClipboardChange(DataType) {
        if (DataType != 1) ; 1 = Text, 2 = Non-Text
            return
            
        try {
            text := A_Clipboard
            if (text == "")
                return
                
            ; Get first line
            firstLine := StrSplit(text, ["`r`n", "`r", "`n"])[1]
            if (StrLen(firstLine) > 50)
                firstLine := SubStr(firstLine, 1, 50) "..."
                
            this.ShowTip("复制: '" firstLine "'")
        }
    }
    
    static ShowTip(text) {
        if (this.TimerFn) {
            SetTimer(this.TimerFn, 0)
            this.TimerFn := ""
        }
        if (this.GuiObj) {
            try this.GuiObj.Destroy()
        }
        
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound +Owner")
        g.BackColor := this.BgColor
        g.SetFont("s" this.FontSize " c" this.FontColor, this.FontName)
        g.Add("Text", "Center", text)
        
        this.GuiObj := g
        
        g.Show("NoActivate Hide") ; Calculate size
        g.GetPos(,, &w, &h)
        
        x := 0
        y := 0
        
        if (this.PosType == 0) { ; Follow Mouse
            MouseGetPos(&mx, &my)
            x := mx + 20
            y := my + 20
        } else if (this.PosType == 1) { ; Screen Center
            x := (A_ScreenWidth - w) / 2
            y := (A_ScreenHeight - h) / 2
        } else { ; Custom
            x := this.PosX
            y := this.PosY
        }
        
        ; Ensure within screen bounds
        if (x + w > A_ScreenWidth)
            x := A_ScreenWidth - w - 10
        if (y + h > A_ScreenHeight)
            y := A_ScreenHeight - h - 10
            
        g.Show("NoActivate x" x " y" y)
        
        this.TimerFn := this.HideTip.Bind(this)
        SetTimer(this.TimerFn, -this.Duration)
    }
    
    static HideTip() {
        if (this.GuiObj) {
            try {
                this.GuiObj.Destroy()
                this.GuiObj := ""
            }
        }
        this.TimerFn := ""
    }
}

; Start Plugin
CopyTip.Init()

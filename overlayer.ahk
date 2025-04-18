#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

global myGui := ""

InitGui() {
    global myGui
    if !IsObject(myGui) {
        try {
            myGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound")
        } catch {
            MsgBox("GUIの作成に失敗しました。")
            ExitApp()
        }
    }
}

main() {
    static files := []
    static index := 1

    folder := ""
    if A_Args.Length > 0 {
        folder := A_Args[1]
    } else {
        ; フォルダ選択ダイアログを表示
        folder := DirSelect("表示するテキストファイルのフォルダを選んでください")
        if !folder {
            MsgBox("キャンセルされました")
            ExitApp()
        }
    }

    if !FileExist(folder) {
        MsgBox("指定されたディレクトリが存在しません: " folder)
        ExitApp()
    }

    files := []
    for f in DirList(folder, "*.txt")
        files.Push(f)

    if files.Length == 0 {
        MsgBox("テキストファイルが見つかりません")
        ExitApp()
    }

    index := 1
    InitGui()
    ShowText(files, index)

    Hotkey("PgUp", (*) => (index := PrevIndex(index, files.Length), ShowText(files, index)))
    Hotkey("PgDn", (*) => (index := NextIndex(index, files.Length), ShowText(files, index)))
    Hotkey("^r",    (*) => Reload(folder))
    Hotkey("Esc",   (*) => ExitApp())
}

ShowText(files, index) {
    global myGui

    file := files[index]
    content := FileRead(file, "UTF-8")
    lines := StrSplit(content, "`n", "`r")

    meta := Map()
    body := ""
    for line in lines {
        line := Trim(line)
        if RegExMatch(line, "^//\s*([a-zA-Z_]+)\s*=\s*(.*)", &m) {
            meta[m[1]] := m[2]
        } else {
            body .= line . "`n"
        }
    }

    defaultX := 2000
    defaultY := 100
    defaultSize := 28
    ; defaultX := 80
    ; defaultY := 200
    ; defaultSize := 28

    defaultColor := "White"

    x := meta.Has("x") ? meta["x"] : defaultX
    y := meta.Has("y") ? meta["y"] : defaultY
    fontSize := meta.Has("fontSize") ? meta["fontSize"] : defaultSize
    color := meta.Has("color") ? ParseColor(meta["color"]) : defaultColor
    backColor := (color = "Black") ? "White" : "Black"

    myGui.Destroy()

    ; ウィンドウのサイズを画面全体に設定
    myGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound")
    myGui.BackColor := backColor
    WinSetTransColor(backColor, myGui.Hwnd)

    ; ウィンドウのサイズを画面全体に合わせる
    myGui.Width := A_ScreenWidth
    myGui.Height := A_ScreenHeight

    myGui.SetFont("s" . fontSize . " Bold", "Meiryo")

    ; 文字の位置をウィンドウ内で調整
    x := Mod(A_ScreenWidth + x, A_ScreenWidth)
    if x < 0 {
        x := 0
    }

    y := Mod(A_ScreenHeight + y, A_ScreenHeight)
    if y < 0 {
        y := 0
    }

    ; テキスト追加
    myGui.Add("Text", "x" . x . " y" . y . " c" . color . " BackgroundTrans", body)

    ; GUI表示
    myGui.Show("NoActivate x0 y0 w" . A_ScreenWidth . " h" . A_ScreenHeight)
}

ParseColor(c) {
    c := Trim(c)
    allowedColors := Map("Red", "Red", "Blue", "Blue", "Green", "Green", "White", "White", "Black", "Black")
    return allowedColors.Has(c) ? c : "White"
}

NextIndex(current, max) {
    return (current >= max) ? 1 : current + 1
}

PrevIndex(current, max) {
    return (current <= 1) ? max : current - 1
}

Reload(folder) {
    Run(A_AhkPath . " `"" . A_ScriptFullPath . "`" `"" . folder . "`"")
    ExitApp()
}

DirList(folder, pattern) {
    list := []
    Loop Files folder "\" pattern {
        list.Push(A_LoopFilePath)
    }
    return list
}

main()

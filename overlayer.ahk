#Requires AutoHotkey v2.0
#SingleInstance Force

SetWorkingDir A_ScriptDir

config := Map(
    "x", 2000, "y", 0, "size", 16, "color", "White",
    "next", "^NumpadMult", "prev", "^NumpadDiv", "reload", "^r", "first", "^l"
)

; config.iniの設定ファイルが存在するか確認
configFile := "config.ini"
if (!FileExist(configFile)) {
    FileAppend(generateIniText(config, true), configFile)
}
; config.iniの読み込み
ini := FileRead(configFile, "UTF-8")
Loop Parse ini, "`n", "`r" {
    if (RegExMatch(A_LoopField, "^(x|y|size|color|next|prev|reload|first)\s*=\s*(.+)$", &m)) {
        key := m[1], val := Trim(m[2])
        config[key] := val
    }
}

; プロジェクトディレクトリの決定
if A_Args.Length > 0 {
    watchDir := A_Args[1]
} else {
    ; フォルダ選択ダイアログを表示
    watchDir := DirSelect("表示するテキストファイルのフォルダを選んでください")
    if !watchDir {
        MsgBox("キャンセルされました")
        ExitApp()
    }
}

SetWorkingDir watchDir

; overlayer.iniの設定ファイルが存在するか確認
overlayerFile := "overlayer.ini"
if (!FileExist(overlayerFile)) {
    FileAppend(generateIniText(config), overlayerFile)
}

; overlayer.iniの読み込み
overlayerIni := FileRead(overlayerFile, "UTF-8")
Loop Parse overlayerIni, "`n", "`r" {
    if (RegExMatch(A_LoopField, "^(x|y|size|color|next|prev|reload|first)\s*=\s*(.+)$", &m)) {
        key := m[1], val := Trim(m[2])
        config[key] := val
    }
}

; キーバリデーション
if (config["next"] = config["prev"]) {
    MsgBox "nextキーとprevキーが同じです。設定を見直してください。"
    ExitApp
}

validKeys := "Enter|Tab|Space|PgUp|PgDn|Home|End|Up|Down|Left|Right|F\d+|[A-Z0-9]|NumpadAdd|NumpadSub|NumpadMult|NumpadDiv"
pattern := "i)^(\^?(" . validKeys . "))$"
if (!RegExMatch(config["next"], pattern) || !RegExMatch(config["prev"], pattern)) {
    MsgBox "無効なキーが設定されています。"
    ExitApp
}

; テキストファイル読み込み
files := []
Loop Files "*.txt" {
    files.Push(A_LoopFileFullPath)
}

if (files.Length = 0) {
    MsgBox "テキストファイルが見つかりません。"
    ExitApp
}

currentIndex := 1
currentFile := files[currentIndex]

ShowText(fileName) {
    global myGui, textCtrl, config

    ; GUIを完全に作り直す
    if IsSet(myGui)
        myGui.Destroy()

    myGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound")
    backColor := (config["color"] = "Black") ? "White" : "Black"
    myGui.BackColor := backColor
    WinSetTransColor(backColor, myGui.Hwnd)
    myGui.Width := A_ScreenWidth
    myGui.Height := A_ScreenHeight

    text := FileRead(fileName, "UTF-8")

    meta := config.Clone()
    if RegExMatch(text, "s)^---\R(.*?)\R---\R", &metaBlock) {
        Loop Parse metaBlock[1], "`n", "`r" {
            if RegExMatch(A_LoopField, "^(x|y|size|color)\s*=\s*(.+)$", &m) {
                meta[m[1]] := Trim(m[2])
            }
        }
        text := SubStr(text, metaBlock.Len + 1)
    }

    x := Mod(A_ScreenWidth + meta["x"], A_ScreenWidth)
    y := Mod(A_ScreenHeight + meta["y"], A_ScreenHeight)

    myGui.SetFont("s" meta["size"] " c" meta["color"] " Bold", "Meiryo")
    textCtrl := myGui.Add("Text", "x" x " y" y " BackgroundTrans", text)

    myGui.Show("NoActivate x0 y0 w" . A_ScreenWidth . " h" . A_ScreenHeight)
}

ShowText(currentFile)

; ホットキー登録
Hotkey(config["next"], NextText)
Hotkey(config["prev"], PrevText)
Hotkey(config["reload"], ReloadFiles)
Hotkey(config["first"], FirstText)
Hotkey("Escape", (*) => ExitApp())

FirstText(*) {
    global files, currentFile, currentIndex
    currentIndex := 1
    currentFile := files[currentIndex]
    ShowText(currentFile)
}

NextText(*) {
    global files, currentFile, currentIndex
    currentIndex := Mod(currentIndex, files.Length) + 1
    currentFile := files[currentIndex]
    ShowText(currentFile)
}

PrevText(*) {
    global files, currentFile, currentIndex
    currentIndex := Mod(currentIndex + files.Length - 2, files.Length) + 1
    currentFile := files[currentIndex]
    ShowText(currentFile)
}

ReloadFiles(*) {
    global files, currentFile, currentIndex
    files := []
    Loop Files "*.txt" {
        files.Push(A_LoopFileFullPath)
    }

    ; ファイルリストを再読み込み
    idx := 0
    Loop files.Length {
        if (files[A_Index] = currentFile) {
            idx := A_Index
            break
        }
    }

    ; currentIndex と currentFile の更新
    currentIndex := (idx > 0) ? idx : 1
    currentFile := files[currentIndex]

    ShowText(currentFile)
}

; config.iniのデフォルト値を生成する関数
generateIniText(configMap, includeKeys := false) {
    if (includeKeys) {
        iniText := "[Keys]`n"
        iniText .= "next = " configMap["next"] "`n"
        iniText .= "prev = " configMap["prev"] "`n"
        iniText .= "reload = " configMap["reload"] "`n"
        iniText .= "first = " configMap["first"] "`n"
        iniText .= "`n"
    }
    iniText .= "[Text]`n"
    iniText .= "x = " configMap["x"] "`n"
    iniText .= "y = " configMap["y"] "`n"
    iniText .= "size = " configMap["size"] "`n"
    iniText .= "color = " configMap["color"] "`n"
    return iniText
}

return
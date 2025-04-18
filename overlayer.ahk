#Requires AutoHotkey v2.0
#SingleInstance Force

SetWorkingDir A_ScriptDir

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

; デフォルト設定
defaultConfig := Map("x", 0, "y", 0, "size", 16, "color", "White", "next", "PgDn", "prev", "PgUp")
config := defaultConfig.Clone()

; 設定ファイルの読み込みまたは生成
configFile := "overlayer.ini"
if (!FileExist(configFile)) {
    FileAppend "
(
[Overlay]
x = 0
y = 0
size = 16
color = White

[Keys]
next = PgDn
prev = PgUp
)", configFile
} else {
    ini := FileRead(configFile, "UTF-8")
    Loop Parse ini, "`n", "`r" {
        if (RegExMatch(A_LoopField, "^(x|y|size|color|next|prev)\s*=\s*(.+)$", &m)) {
            key := m[1], val := Trim(m[2])
            config[key] := val
        }
    }
}

; キーバリデーション
if (config["next"] = config["prev"]) {
    MsgBox "nextキーとprevキーが同じです。設定を見直してください。"
    ExitApp
}

validKeys := "Enter|Tab|Space|PgUp|PgDn|Home|End|Up|Down|Left|Right|F\d+|[A-Z0-9]"
if (!RegExMatch(config["next"], "i)^(" . validKeys . ")$") || !RegExMatch(config["prev"], "i)^(" . validKeys . ")$")) {
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

    meta := Map("x", config["x"], "y", config["y"], "size", config["size"], "color", config["color"])
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
Hotkey("^r", ReloadFiles)
Hotkey("Escape", (*) => ExitApp())

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

return

' F1 25 - Rafa Pro (60 fps): abre o app sem janela preta.
' Liga o servidor escondido e mostra a janela do painel.
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
pasta = fso.GetParentFolderName(WScript.ScriptFullName)
sh.CurrentDirectory = pasta

node = "C:\Program Files\nodejs\node.exe"
If Not fso.FileExists(node) Then
  r = MsgBox("O Node.js nao esta instalado. Instalar agora?" & vbCrLf & "(depois e so abrir o app de novo)", vbYesNo + vbQuestion, "F1 25 - Rafa Pro")
  If r = vbYes Then sh.Run "winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements", 1, True
  WScript.Quit
End If

' 0 = janela escondida, False = nao espera
sh.Run """" & node & """ """ & pasta & "\servidor.js"" --app", 0, False

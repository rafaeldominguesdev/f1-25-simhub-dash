// F1 25 Rafa Pro: abre o app sem janela preta.
// Liga "node app\servidor.js --app" escondido; o servidor abre a janela do app.
// Compilado no PC pelo "Compilar exe.bat" (usa o csc.exe que ja vem no Windows).
using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

[assembly: System.Reflection.AssemblyTitle("F1 25 Rafa Pro")]
[assembly: System.Reflection.AssemblyProduct("F1 25 Rafa Pro")]

static class Launcher
{
    const string TITULO = "F1 25 Rafa Pro";

    [STAThread]
    static void Main()
    {
        string pasta = AppDomain.CurrentDomain.BaseDirectory;
        string app = Path.Combine(pasta, "app");
        string servidor = Path.Combine(app, "servidor.js");
        if (!File.Exists(servidor))
        {
            MessageBox.Show("Não achei a pasta \"app\" ao lado deste programa.\n\nDeixe o F1 25 Rafa Pro.exe na mesma pasta da pasta \"app\".",
                TITULO, MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }

        string node = AcharNode();
        if (node == null)
        {
            DialogResult r = MessageBox.Show("O Node.js não está instalado. O app precisa dele para funcionar.\n\nInstalar agora? Leva 1 ou 2 minutos.",
                TITULO, MessageBoxButtons.YesNo, MessageBoxIcon.Question);
            if (r != DialogResult.Yes) return;
            try
            {
                ProcessStartInfo w = new ProcessStartInfo("winget", "install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements");
                w.UseShellExecute = true;
                Process p = Process.Start(w);
                p.WaitForExit();
            }
            catch (Exception)
            {
                MessageBox.Show("Não consegui instalar pelo winget.\n\nBaixe o Node.js LTS em nodejs.org, instale e abra o app de novo.",
                    TITULO, MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            node = AcharNode();
            if (node == null)
            {
                MessageBox.Show("Instalação terminada. Abra o app de novo.", TITULO, MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
        }

        ProcessStartInfo psi = new ProcessStartInfo(node, "\"" + servidor + "\" --app");
        psi.WorkingDirectory = app;
        psi.UseShellExecute = false;
        psi.CreateNoWindow = true;
        psi.WindowStyle = ProcessWindowStyle.Hidden;
        try { Process.Start(psi); }
        catch (Exception e)
        {
            MessageBox.Show("Não consegui ligar o app:\n\n" + e.Message, TITULO, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    static string AcharNode()
    {
        string[] fixos = {
            Environment.ExpandEnvironmentVariables(@"%ProgramFiles%\nodejs\node.exe"),
            @"C:\Program Files\nodejs\node.exe",
            Environment.ExpandEnvironmentVariables(@"%LOCALAPPDATA%\Programs\nodejs\node.exe"),
        };
        foreach (string f in fixos) if (File.Exists(f)) return f;
        string path = Environment.GetEnvironmentVariable("PATH") ?? "";
        foreach (string d in path.Split(';'))
        {
            try
            {
                string f = Path.Combine(d.Trim().Trim('"'), "node.exe");
                if (File.Exists(f)) return f;
            }
            catch (Exception) { }
        }
        return null;
    }
}

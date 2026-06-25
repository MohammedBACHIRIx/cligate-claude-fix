using System;
using System.Diagnostics;
using System.Text;

class Program
{
    static int Main(string[] args)
    {
        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = "powershell.exe";
        
        StringBuilder arguments = new StringBuilder();
        arguments.Append("-ExecutionPolicy Bypass -File \"C:\\Users\\Lenovo\\github\\cligate-claude-fix\\claude-launcher.ps1\"");
        
        foreach (string arg in args)
        {
            arguments.Append(" ");
            arguments.Append(QuoteArgument(arg));
        }
        
        startInfo.Arguments = arguments.ToString();
        startInfo.UseShellExecute = false;
        
        try
        {
            using (Process process = Process.Start(startInfo))
            {
                process.WaitForExit();
                return process.ExitCode;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine("Error launching Claudy: " + ex.Message);
            return 1;
        }
    }

    static string QuoteArgument(string arg)
    {
        if (string.IsNullOrEmpty(arg)) return "\"\"";
        if (arg.Contains(" ") || arg.Contains("\""))
        {
            return "\"" + arg.Replace("\"", "\\\"") + "\"";
        }
        return arg;
    }
}

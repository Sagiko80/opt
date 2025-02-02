using System;
using System.IO;
using System.Globalization;
using Microsoft.SqlServer.Dts.Runtime;

public void Main()
{
    try
    {
        // Get the current date in YYYYMMDD format
        string dateSuffix = DateTime.Now.ToString("yyyyMMdd", CultureInfo.InvariantCulture);

        // Get the full file path from SSIS variable
        string oldFilePath = Dts.Variables["User::FilePath"].Value.ToString();
        
        // Get directory, filename without extension, and extension
        string directory = Path.GetDirectoryName(oldFilePath);
        string filename = Path.GetFileNameWithoutExtension(oldFilePath);
        string extension = Path.GetExtension(oldFilePath);

        // New file name with _YYYYMMDD appended
        string newFilePath = Path.Combine(directory, filename + "_" + dateSuffix + extension);

        // Rename the file
        File.Move(oldFilePath, newFilePath);

        Dts.TaskResult = (int)ScriptResults.Success;
    }
    catch (Exception ex)
    {
        Dts.TaskResult = (int)ScriptResults.Failure;
    }
}
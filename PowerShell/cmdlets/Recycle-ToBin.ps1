#Recycle-ToBin.ps1
<#
.Synopsis
    This cmdlet moves item to Recycle Bin instead of deleting them permanently.
    It is useful while operating in an untested or partially tested environment.
#>
param(

[Parameter(mandatory=$true)]
$Path
)
    Add-Type -AssemblyName Microsoft.VisualBasic
    $item = Get-Item -Path $Path -ErrorAction SilentlyContinue
    if ($item -eq $null)
    {
        Write-Error("'{0}' not found" -f $Path)
    }
    else
    {
        $fullpath=$item.FullName
        Write-Information("Moving '{0}' to the Recycle Bin" -f $fullpath) -Verbose -InformationAction Continue
        if (Test-Path -Path $fullpath -PathType Container)
        {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($fullpath,'OnlyErrorDialogs','SendToRecycleBin')
        }
        else
        {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($fullpath,'OnlyErrorDialogs','SendToRecycleBin')
        }
    }
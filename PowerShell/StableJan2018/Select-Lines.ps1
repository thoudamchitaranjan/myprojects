<#
.Synopsis
    Selects only the lines containing the value of the $Substring from the list
fetched from the file $Path. The result is stored in -Destination file path.
#>
param (
        [Parameter(mandatory=$true,
        Position=0,
        HelpMessage="The list file which contains the list for Selecting wanted lines.")]
        [ValidateScript({Test-Path $_})]
        [string]$Path,

        [Parameter(mandatory=$false,
        Position=1,
        HelpMessage="The destination file path where the list will be stored. It should not exist.
        If it may exist and you want to replace it, the use -DeletePrevious switch")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({-not $PSBoundParameters['ReplaceOriginal']})]
        [string]$Destination,

        [Parameter(mandatory=$false,
        Position=2,
        HelpMessage="The lines containing this string are Selected. Accepts only a single string.")]
        [ValidateNotNullOrEmpty()]
        [string]$Substring,

        [Parameter(mandatory=$false,
        HelpMessage="Select this to delete previous existing -Destination file")]
        [switch]$DeletePrevious=$false,

        [Parameter(mandatory=$false,
        HelpMessage="Select this to delete the original file after processing.")]
        [ValidateScript({-not [string]::IsNullOrWhiteSpace($Destination)})]
        [switch]$DeleteOriginal=$false,
        
        [Parameter(mandatory=$false,
        HelpMessage="Select this to replace the original file with the resulting file.")]
        [ValidateScript({[string]::IsNullOrWhiteSpace($PSBoundParameters['Destination'])})]
        [switch]$ReplaceOriginal=$false
        )
Begin{
    if(($ReplaceOriginal) -and (-not [string]::IsNullOrWhiteSpace($Destination))){
        Write-Warning -Message "Result will be stored in the original file name. Destination file will not be created." -Verbose -InformationAction Continue
    }
    elseif(($DeleteOriginal) -and ([string]::IsNullOrWhiteSpace($Destination))){
        Write-Warning -Message "Valid Destination file path should be entered if original file is to be deleted."  -Verbose -InformationAction Continue
    }
    elseif(($DeletePrevious) -and ([string]::IsNullOrWhiteSpace($Destination))){
        Write-Warning -Message "Use and enter Destination file path to avoid replacing the original file."  -Verbose -InformationAction Continue
    }
}###begin
Process{
    ###Specifies default file management of original file.
        if(([string]::IsNullOrWhiteSpace($Destination))-and (-not ($ReplaceOriginal -or $DeleteOriginal -or $DeletePrevious))){
            Write-Warning -Message "Specify -Destination to avoid loss of data or -ReplaceOriginal. Exiting..."  -Verbose -InformationAction Continue
            Return $null
        }
    if((-not [string]::IsNullOrWhiteSpace($Path)) -and ($false -ieq (Test-Path "$Path"))){
        Write-Error -Message "List file for Selecting lines does not exist." -Verbose -InformationAction Continue
        Return $null
    }
    elseif(($DeletePrevious) -and ([string]::IsNullOrWhiteSpace($Destination))){
        Write-Warning -Message "Exiting to avoid loss of data."  -Verbose -InformationAction Continue
        Return $null
    }
    if(($DeletePrevious) -and (-not [string]::IsNullOrWhiteSpace($Destination)) -and (Test-Path $Destination)){
        Remove-Item $Destination | Out-Null
    }
    elseif((-not [string]::IsNullOrWhiteSpace($Destination)) -and (Test-Path "$Destination")){
        Write-Warning -Message "Previous '$Destination' file already exist. Cancelling line Selection." -Verbose -InformationAction Continue
        Return $null
    }
    if($ReplaceOriginal){
        $tempFilePath=$Path -replace ".txt","Temp.txt"
    }
    elseif(-not [string]::IsNullOrWhiteSpace($Destination)){
        $tempFilePath=$Destination -replace ".txt","Temp.txt"
    }
    if((-not [string]::IsNullOrWhiteSpace($tempFilePath)) -and (Test-Path $tempFilePath)){
        Remove-Item $tempFilePath | Out-Null
    }
    ##############################Reading list
    if(-not [string]::IsNullOrWhiteSpace($Substring)){
        foreach($line in Get-Content "$Path")
        {
            if($line -imatch [regex]::Escape($substring)){
                Write-Output $line >> "$tempFilepath"
            }
        }###foreach $line
    ###############################Reading done.
        if($ReplaceOriginal){
            Remove-Item $Path
            Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Path))
        }
        elseif($DeleteOriginal){
            Move-Item -Path $tempFilePath -Destination $Destination
            ###Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Destination))
            Remove-Item -Path $Path | Out-Null
        }
        <#
        elseif(($DeletePrevious)-and ([string]::IsNullOrWhiteSpace($Destination)) -and (Test-Path $Path)){
            Remove-Item $Path
            Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Path))
        }
        #>
        else{
            Move-Item -Path $tempFilePath -Destination $Destination
            ###Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Destination))
        }
        Write-Information -MessageData "Lines with '$Substring' in the file have been Selected." -Verbose -InformationAction Continue
    }
    else
    {
        Write-Information -MessageData "Lines Selection canceled." -Verbose -InformationAction Continue
    }
}###Process
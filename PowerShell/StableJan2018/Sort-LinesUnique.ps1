<#
.Synopsis
    Sorts a list file content, and removes duplicate line from the list, keeping only one instance of the line.
    Replaces the original file by default.
#>
param (
    [CmdletBinding()]

    [Parameter(
    mandatory=$true,
    Position=0,
    HelpMessage="The source file path containing the list to be sorted.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [string]$Path,

    [Parameter(
    mandatory=$false,
    Position=1,
    HelpMessage="Provide value for this to get the sorted list in a different file.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({-not (Test-Path $_)})]
    [ValidateScript({-not $PSBoundParameters['ReplaceOriginal']})]
    [string]$Destination,

    [Parameter(
    mandatory=$false,
    HelpMessage="Select this to delete the original source file after procesiing.")]
    [ValidateScript({-not [string]::IsNullOrWhiteSpace($Destination)})]
    [switch]$DeleteOriginal=$false,

    [Parameter(
    mandatory=$false,
    HelpMessage="Select this to remove -Destination file if it already exist.")]
    [switch]$DeletePrevious=$false,

    [Parameter(
    mandatory=$false,
    HelpMessage="Select this to replace the source file by the resulting file with same name.")]
    [ValidateScript({[string]::IsNullOrWhiteSpace($PSBoundParameters['Destination'])})]
    [switch]$ReplaceOriginal=$false
    )

    Begin{
        New-Variable -Name "tempFilePath" -Visibility Private
        if(($ReplaceOriginal) -and (-not [string]::IsNullOrWhiteSpace($Destination))){
            Write-Warning -Message "Result will be stored in the original file name. Destination file will not be created." -Verbose -InformationAction Continue
        }
        elseif(($DeleteOriginal) -and ([string]::IsNullOrWhiteSpace($Destination))){
            Write-Warning -Message "Valid Destination file path should be entered if original file is to be deleted."  -Verbose -InformationAction Continue
        }
        elseif(($DeletePrevious) -and ([string]::IsNullOrWhiteSpace($Destination))){
            Write-Warning -Message "Use and enter Destination file path to avoid replacing the original file."  -Verbose -InformationAction Continue
        }
    }
    Process{
        ###Specifies default file management of original file.
        if(([string]::IsNullOrWhiteSpace($Destination))-and (-not ($ReplaceOriginal -or $DeleteOriginal -or $DeletePrevious))){
            Write-Warniing -Message "Specify -Destination to avoid loss of data or -ReplaceOriginal. Exiting..."  -Verbose -InformationAction Continue
            Return $null
        }
        
        if((-not [string]::IsNullOrWhiteSpace($Path)) -and ($false -ieq (Test-Path "$Path"))){
            Write-Error -Message "List file for Sorting lines does not exist." -Verbose -InformationAction Continue
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
            Write-Warning -Message "Previous '$Destination' file already exist. Cancelling line Rejection." -Verbose -InformationAction Continue
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
        ##################Reading list.
        Get-Content $Path | sort | get-unique >> $tempFilePath
        ################################Reading done.
        if($ReplaceOriginal){
            Remove-Item $Path
            Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Path))
        }
        elseif($DeleteOriginal){
            Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Destination))
            Remove-Item -Path $Path | Out-Null
        }
        <#
        elseif(($DeletePrevious)-and ([string]::IsNullOrWhiteSpace($Destination)) -and (Test-Path $Path)){
            Remove-Item $Path
            Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Path))
        }
        #>
        else{
            Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Destination))
        }
        <#
        if($ReplaceOriginal)
        {
            Remove-Item $Path
            Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Path))
        }
        elseif($DeleteOriginal){
            if((Test-Path $Path) -and ([string]::IsNullOrWhiteSpace($Destination))){
                Remove-Item $Path | Out-Null
                Move-Item $tempListFile -Destination $Path | Out-Null
            }
            elseif(-not [string]::IsNullOrWhiteSpace($Destination)){
                Move-Item $tempListFile -Destination $Destination | Out-Null
            }
        }
        else{
            if(-not [string]::IsNullOrWhiteSpace($Destination)){
                Move-Item $tempListFile -Destination $Destination | Out-Null
            }
        }
        #>
        Write-Information -MessageData "$Path  file is Uniquely sorted." -InformationAction Continue -Verbose
    }
    End{
        
        Remove-Variable "tempFilePath"
        
    }
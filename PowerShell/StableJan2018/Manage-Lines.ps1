
            <#
            .Synopsis
                Manages a list file content.
                It can remove duplicate lines from the list, keeping only one instance of the line.
                It can select/reject lines containing -SubString from the list and store in a new file.
                It can even replace the original file with the resulting file.
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
                    ###[ValidateScript({-not $PSBoundParameters['ReplaceOriginal']})]
                [string]$Destination,

                    [Parameter(mandatory=$false,
                    Position=2,
                    HelpMessage="The lines containing this string are Selected/Rejected. Accepts only a single string.")]
                    [ValidateNotNullOrEmpty()]
                [string]$Substring,

                    [Parameter(
                    mandatory=$false,
                    HelpMessage="Select this to sort unique the content lines of source file.")]
                [switch]$SortLinesUnique=$false,

                    [Parameter(
                    mandatory=$false,
                    HelpMessage="Select this to select from the content lines of source file.")]
                [switch]$SelectLines=$false,
        
                    [Parameter(
                    mandatory=$false,
                    HelpMessage="Select this to reject from the content lines of source file.")]
                [switch]$RejectLines=$false,

                    [Parameter(
                    mandatory=$false,
                    HelpMessage="Select this to delete the original source file after procesiing.")]
                    ###[ValidateScript({-not [string]::IsNullOrWhiteSpace($Destination)})]
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
        
                    ###guards against unspecified operation.
                    if(-not ($SortLinesUnique -or $SelectLines -or $RejectLines)){
                        Write-Information -MessageData "`nATTENTION----------Specify process please.-----------" -Verbose -InformationAction Continue
                        Return $null
                    }
                    ###Guards against multiple specified operations.
                    elseif(($SortLinesUnique -and $SelectLines) -or ($SelectLines -and $RejectLines) -or ($RejectLines -and $SortLinesUnique)){
                        Write-Warning -Message "You can perform only one category of operation at a time." -Verbose -InformationAction Continue
                        Return $null
                    }
                    ###Guards against incomplete file path inputs.
                    if((-not [string]::IsNullOrWhiteSpace($Path)) -and ($false -ieq (Test-Path "$Path"))){
                        Write-Error -Message "List file for processing lines does not exist." -Verbose -InformationAction Continue
                        Return $null
                    }
        
                    ###Test the -Destination file path.
                    if(-not [string]::IsNullOrWhiteSpace($Destination)){
                        ###Deletes the file with the same name as the -Destination in the same location.
                        if(($DeletePrevious) -and (Test-Path $Destination)){
                            Remove-Item $Destination | Out-Null
                        }
                        elseif(Test-Path "$Destination"){
                            Write-Warning -Message "Previous '$Destination' file already exist. Adding results to the previous file." -Verbose -InformationAction Continue
                            ###Write-Warning -Message "Previous '$Destination' file already exist. Cancelling line processing." -Verbose -InformationAction Continue
                            ###Return $null
                        }
                        ######Trying to create the destination file exclusively.
                        try{
                            if(-not (Test-Path "$Destination")){
                                New-Item -Path $Destination -ItemType File -ErrorAction SilentlyContinue | Out-Null
                            }
                            if(-not (Test-Path $Destination)){
                                Write-Warning -Message "-Destination path is not valid. Try Again..." -Verbose -InformationAction Continue
                                Return $null
                            }
                
                        }
                        Catch{
                            Write-Warning -Message "-Destination path is not valid. Try Again..." -Verbose -InformationAction Continue
                            Return $null
                        }
                        $tempFilePath=$Destination -replace ".txt","Temp.txt"
                    }
                    else{###-Destination is null.
                        ###Specifies default file management of original file.
                        if(-not ($ReplaceOriginal -or $DeleteOriginal -or $DeletePrevious)){
                            Write-Warning -Message "Specify -Destination to avoid loss of data or Use -ReplaceOriginal. Exiting..."  -Verbose -InformationAction Continue
                            Return $null
                        }
                        elseif($DeletePrevious -or $DeleteOriginal){
                            Write-Warning -Message "Specify -Destination or You can use -ReplaceOriginal. Exiting to avoid loss of data."  -Verbose -InformationAction Continue
                            Return $null
                        }
                        $tempFilePath=$Path -replace ".txt","Temp.txt"
                    }

                    ###Removes the residual temporary file, if present, before operation starts.
                    if(Test-Path $tempFilePath){
                        Remove-Item $tempFilePath | Out-Null
                    }
                    New-Item $tempFilePath | Out-Null
            ##############################Selects the operation.########################

                    if($SortLinesUnique){
                        ##################Sorting list.
                        Get-Content $Path | sort | get-unique >> $tempFilePath
                        ################################Reading done.
                    }
                    elseif($SelectLines){
                        ##############################Selecting Lines
                        if(-not [string]::IsNullOrWhiteSpace($Substring)){
                            foreach($line in Get-Content "$Path")
                            {
                                if($line -imatch [regex]::Escape($Substring)){
                                    Write-Output $line >> "$tempFilepath"
                                }
                            }###foreach $line
                
                        }
                        ###############################Reading done.
                    }
                    elseif($RejectLines){
                        ##############################Rejecting Lines.
                        if(-not [string]::IsNullOrWhiteSpace($Substring)){
                            foreach($line in Get-Content "$Path")
                            {
                                if($line -inotmatch [regex]::Escape($Substring)){
                                    Write-Output $line >> "$tempFilepath"
                                }
                            }###foreach $line
                        }
                        ################################Reading done.
                    }###elseif
            #############################################################################
                    ###Managing the file names to give the desired file names.
                    if($ReplaceOriginal){
                        Remove-Item $Path
                        Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Path))
                    }
                    elseif($DeleteOriginal){
                        Get-Content $tempFilePath >> $Destination
                        ###Move-Item -Path $tempFilePath -Destination $Destination
                        ###Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Destination))
                        Remove-Item -Path $Path | Out-Null
                    }
                    <#
                    elseif(($DeletePrevious)-and ([string]::IsNullOrWhiteSpace($Destination)) -and (Test-Path $Path)){
                        Remove-Item $Path
                        Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Path))
                    }
                    #>
                    elseif(Test-Path $tempFilePath){
                        Get-Content $tempFilePath >> $Destination
                        Remove-Item $tempFilePath
                        ###Move-Item -Path $tempFilePath -Destination $Destination
                        ###Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($Destination))
                    }
                    if($SortLinesUnique){
                        Write-Information -MessageData "List in $Path  file is successfully sorted unique." -InformationAction Continue -Verbose
                        }
                        elseif($SelectLines){
                            Write-Information -MessageData "List in $Path  file is successfully selected." -InformationAction Continue -Verbose
                            }
                            elseif($RejectLines){
                                Write-Information -MessageData "List in $Path  file is successfully rejected." -InformationAction Continue -Verbose
                                }
                }
                End{
        
                    Remove-Variable "tempFilePath"
        
                }
        
    
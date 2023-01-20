<#
.Synopsis
    Fetches the files(currently, only image files are supported.) from the url provided.
    The fetched files are stored in the destination.
.Parameter
    -Uri is the url from which files will be downloaded.
    -Destination is the folder where the images will be downloaded.
        The folder will be created if not available.
        The server directory structure will be maintained inside the destination folder.
#>
param(
    [CmdletBinding()]

        [Parameter(mandatory=$true,
        Position=0,
        HelpMessage="The url of a webpost which has the images shown.")]
        [ValidateNotNullOrEmpty()]
    [string]$Uri,

        [Parameter(mandatory=$true,
        Position=1,
        HelpMessage="The destination folder path where images are to be downloaded to.")]
        [ValidateNotNullOrEmpty()]
    [string]$Destination,

        [Parameter(mandatory=$false,
        Position=2,
        HelpMessage="Select the keywords, images extensions here, each seperated by commas.")]
        [ValidateNotNullOrEmpty()]
    [string[]]$SelectList=".jpg",

        [Parameter(
        mandatory=$false,
        HelpMessage="Select this to select those lines which contains all the -SelectList keywords.")]
    [switch]$SelectOverlap=$false,

        [Parameter(
        Position=3,
        HelpMessage="Enter one or more strings as keywords for rejecting lines from the list file.")]
        [ValidateNotNullOrEmpty()]
    [string[]]$RejectList,

        [Parameter(
        mandatory=$false,
        HelpMessage="Select this to reject those lines which contains not some, but all the -RejectList keywords.")]
    [switch]$RejectOverlap=$false,

        [Parameter(
        Position=2,
        HelpMessage="Enter one or more strings as keywords for replacing in the lines content of the file.")]
        [ValidateNotNullOrEmpty()]
    [string[]]$RemoveList,

        [Parameter(mandatory=$false,
        HelpMessage="Select this to delete previous images list file and refetch the image urls.")]
    [switch]$Restart=$false,

        [Parameter(mandatory=$false,
        HelpMessage="Select this to fetch(i.e. download) the images.")]
    [switch]$FetchJpgs=$false

)###param

Begin{
    ###############################################################################
    Function Remove-Text {
        ###Created especially to Convert the links of thumbnails to links of their actual files.
        ###The values in -ReplaceList are removed from the links of the thumbnails.
        ###Change the value of $substring to adjust for each situation.
        param(
                    [Parameter(mandatory=$true,
                    Position=0,
                    HelpMessage="The full path of the file which is to be edited.")]
                    [ValidateNotNullOrEmpty()]
                    [ValidateScript({Test-Path $_})]
            [string]$Path,

                    [Parameter(
                    mandatory=$false,
                    Position=1,
                    HelpMessage="Destination list file full path.")]
                    [ValidateNotNullOrEmpty()]
                    [ValidateScript({-not (Test-Path $_)})]
                    [ValidateScript({-not $PSBoundParameters['ReplaceOriginal']})]
            [string]$Destination,

                    [Parameter(
                    Position=2,
                    HelpMessage="Enter one or more strings as keywords for replacing in the lines content of the file.")]
                    [ValidateNotNullOrEmpty()]
            [string[]]$RemoveList='Thum/Thum-',

                    [Parameter(
                    mandatory=$false,
                    HelpMessage="Select this to replace original file by the output file.")]
                    [ValidateScript({[string]::IsNullOrWhiteSpace($PSBoundParameters['Destination'])})]
            [switch]$ReplaceOriginal=$false
            )
        Process{
            $tempFilePath=$Path -replace ".txt","Temp.txt"
            if($false -ieq (Test-Path "$Path")){
                Return "List file does not exist."
                }
                else{
                    foreach($keyword in $RemoveList){
                        if(-not [string]::IsNullOrWhiteSpace($keyword)){
                            foreach($thumbnailLink in Get-Content "$Path"){
                                $thumbnailLink = $thumbnailLink.Replace($keyword,"")
                                Write-Output $thumbnailLink >> $tempFilePath
                            }
                            Write-Information -MessageData  "Text $keyword removed from lines." -Verbose -InformationAction Continue
                        }###if
            
                    }###foreach()
                }###else
            if($ReplaceOriginal){
                    Remove-Item $Path | Out-Null
                    Rename-Item $tempFilePath -NewName ([System.IO.Path]::GetFileName($Path)) | Out-Null
                    }
                    else{
                        Move-Item -Path $tempFilePath -Destination $Destination | Out-Null
                    }
         }
         end{
                Remove-Variable "tempFilePath"
            }
    }###Remove-Text() ends here.
    ###############################################################################
    Function Url-ToPath {
        <#
        .Synopsis
            Returns the relative directory/file path for the supplied url, so that it can be used to join
            any Windows Directory path.
        .Parameter
            Select -linux to switch to linux type of path.
        #>
        param(
            [CmdletBinding()]

            [Parameter(
            mandatory=$true,
            Position=0,
            ValueFromPipeline=$true,
            HelpMessage="The url which will be converted to windows relative path.")]
            [ValidateNotNullOrEmpty()]
            [string[]]$Uri,

            [Parameter(
            mandatory=$false,
            Position=1,
            HelpMessage="Select this to convert to linux path.")]
            [switch]$linux=$false
            )
            begin{
                [string]$specialChars = "?*`"|<>:"
            }
            process{
                $actualLink=$Uri -replace ".*//(.*)",'$1'
                $rePattern = ($specialChars.ToCharArray() |ForEach-Object { [regex]::Escape($_) }) -join "|"
                $actualLink = $actualLink -replace $rePattern,""
                $actualLink = $actualLink.TrimEnd()
                $actualLink = $actualLink.TrimEnd("/")
                if($linux){
                    Return $actualLink
                }
                else{
                    $actualLink=$actualLink -replace "/","\"
                    Return $actualLink
                }
            }
            end{
                Remove-Variable specialChars
            }
    }#######Url-ToPath() ends here.
    ################################################################################
    Function Manage-Lines {
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
                    [ValidateScript({-not $PSBoundParameters['ReplaceOriginal']})]
                [string]$Destination,

                    [Parameter(mandatory=$false,
                    Position=2,
                    HelpMessage="The lines containing this string are Rejected. Accepts only a single string.")]
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
                    [ValidateScript({[string]::IsNullOrWhiteSpace($PSBoundParameters['Destination']) })]
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
                                if($line -imatch [regex]::Escape($substring)){
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
                                if($line -inotmatch [regex]::Escape($substring)){
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
        
    }######Manage-Lines() ends here.
    ###############################################################################
    Function Filter-Lines {
        param(
        [CmdletBinding()]
        
            [Parameter(
            mandatory=$true,
            Position=0,
            HelpMessage="Source list file full path.")]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({Test-Path $_})]
        [string]$Path, ###source file full path.
        
            [Parameter(
            mandatory=$false,
            Position=1,
            HelpMessage="Destination list file full path.")]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({-not (Test-Path $_)})]
            [ValidateScript({-not $PSBoundParameters['ReplaceOriginal']})]
        [string]$Destination,

            [Parameter(
            Position=2,
            HelpMessage="Enter one or more strings as keywords for selecting lines from the list file.")]
            [ValidateNotNullOrEmpty()]
        [string[]]$SelectList,

            [Parameter(
            mandatory=$false,
            HelpMessage="Select this to select those lines which contains all the -SelectList keywords.")]
        [switch]$SelectOverlap=$false,
    
            [Parameter(
            Position=3,
            HelpMessage="Enter one or more strings as keywords for rejecting lines from the list file.")]
            [ValidateNotNullOrEmpty()]
        [string[]]$RejectList,

            [Parameter(
            mandatory=$false,
            HelpMessage="Select this to reject those lines which contains not some, but all the -RejectList keywords.")]
        [switch]$RejectOverlap=$false,
    
            [Parameter(
            mandatory=$false,
            HelpMessage="Select this to delete -Destination file if already present before processing starts.")]
        [switch]$DeletePrevious=$false,

            [Parameter(
            mandatory=$false,
            HelpMessage="Select this to delete the source file after filtering the list.")]
        [switch]$DeleteOriginal=$false,


            [Parameter(
            mandatory=$false,
            HelpMessage="Select this to replace original file by the output file.")]
            [ValidateScript({[string]::IsNullOrWhiteSpace($PSBoundParameters['Destination'])})]
        [switch]$ReplaceOriginal=$false

        )###param

        Begin {
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
        }###Begin
        Process {
        
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
                        Write-Warning -Message "Previous '$Destination' file already exist. Cancelling line Rejection." -Verbose -InformationAction Continue
                        Return $null
                    }
                    ######Trying to create the destination file exclusively.
                    try{
                        New-Item -Path $Destination -ItemType File -ErrorAction SilentlyContinue | Out-Null
                        if(-not (Test-Path $Destination)){
                            Write-Warning -Message "-Destination path is not valid. Try Again..." -Verbose -InformationAction Continue
                            Return $null
                        }
                        else
                        {
                            Remove-Item $Destination
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
                ###New-Item $tempFilePath | Out-Null
                $pathCopy=$Path.Replace(".txt","Copy.txt")
                if(Test-Path $pathCopy){
                    Remove-Item $pathCopy
                    }
                Copy-Item -Path $Path -Destination $pathCopy
                Write-Information -MessageData "`nFiltering.........." -Verbose -InformationAction Continue
                if(-not [string]::IsNullOrWhiteSpace($SelectList)){
                    foreach($keyword in $SelectList){
                        ###pause
                        Write-Information -MessageData "Selecting lines with $keyword" -Verbose -InformationAction Continue
                        if($SelectOverlap){
                            Manage-Lines -Path $pathCopy -Substring $keyword -SelectLines -ReplaceOriginal | Out-Null
                            ###Select-Lines -Path $pathCopy -Destination $tempFilePath -Substring $keyword
                            ###Remove-Item -Path $pathCopy
                            ###Move-Item -Path $tempFilePath -Destination $pathCopy
                            }
                            else{
                                Manage-Lines -Path $pathCopy -Destination $tempFilePath -Substring $keyword -SelectLines | Out-Null
                                ###Select-Lines -Path $pathCopy -Destination $tempFilePath -Substring $keyword
                            }
                    }###foreach()
                    ###pause
                    if(Test-Path $tempFilePath){
                            Remove-Item $pathCopy
                            Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($pathCopy))
                            ###Remove-Item -Path $pathCopy
                            ###Move-Item -Path $tempFilePath -Destination $pathCopy
                            Manage-Lines -Path $pathCopy -SortLinesUnique -ReplaceOriginal
                            ###Sort-ListUnique -Path $pathCopy
                        }###if
                }###if
                if(-not [string]::IsNullOrWhiteSpace($RejectList)){
                    foreach($keyword in $RejectList){
                            Write-Information -MessageData "Rejecting lines with $keyword" -Verbose -InformationAction Continue | Out-Null
                            if($RejectOverlap){
                                "No algoritm yet"
                                ###Reject-Lines -Path $pathCopy -Destination $tempFilePath -Substring $keyword
                            }
                            else{
                                Manage-Lines -Path $pathCopy -Substring $keyword -RejectLines -ReplaceOriginal | Out-Null
                                ###Reject-Lines -Path $pathCopy -Destination $tempFilePath -Substring $keyword
                                ###Remove-Item -Path $pathCopy
                                ###Move-Item -Path $tempFilePath -Destination $pathCopy
                            }
                    }###foreach
                    if(Test-Path $tempFilePath){
                            Rename-Item -Path $tempFilePath -NewName ([System.IO.Path]::GetFileName($pathCopy))
                            ###Remove-Item -Path $pathCopy
                            ###Move-Item -Path $tempFilePath -Destination $pathCopy
                            Manage-Lines -Path $pathCopy -SortLinesUnique -ReplaceOriginal | Out-Null
                            ###Sort-ListUnique -Path $pathCopy
                        }###if
                }###if
                ###pause
                if($ReplaceOriginal){
                    Remove-Item $Path
                    Rename-Item -Path $pathCopy -NewName ([System.IO.Path]::GetFileName($Path))
                    }
                    elseif(($DeleteOriginal) -and (Test-Path ([System.IO.Path]::GetDirectoryName($Destination)))){
                        Remove-Item $Path
                        Move-Item -Path $pathCopy -Destination $Destination
                        }
                        elseif(Test-Path ([System.IO.Path]::GetDirectoryName($Destination))){
                            Move-Item -Path $pathCopy -Destination $Destination
                        }
        }###Process
        End {
                Remove-Variable tempFilePath
                Remove-Variable pathCopy
        }
    }###Filter-Lines() ends here.
    ####################################################################################
    Function Download-FileWithProgress {
        <#<#<#https://blogs.msdn.microsoft.com/jasonn/2008/06/13/downloading-files-from-the-internet-in-powershell-with-progress/
        author:jniver
        modified by:picachu
        #>#>#>
    param(
        [CmdletBinding()]

        [Parameter(mandatory=$true,Position=0,
        HelpMessage="Complete url of file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter(mandatory=$true,Position=1,
        HelpMessage="Full path of destination file with name.")]
        [ValidateScript({-not (Test-Path $_) })]
        [string]$Destination
        )
        Begin{
       
           }
        Process{
           
           ###This code bit was inserted by me.
           $localTempFilePath=[System.IO.Path]::ChangeExtension($Destination,"temp")
           if(Test-Path $localTempFilePath){
                Remove-Item $localTempFilePath
           }
           elseif(-not (Test-Path ([IO.Path]::GetDirectoryName($Destination)))){
                New-Item ([IO.Path]::GetDirectoryName($Destination)) -ItemType Directory  -Verbose -InformationAction Continue | Out-Null
           }
           ####above code bit was inserted by me.
           $uriObject = New-Object "System.Uri" "$Uri"
           $request = [System.Net.HttpWebRequest]::Create($uriObject)
           $request.set_Timeout(15000) #15 second timeout
           $response = $request.GetResponse()
           if(-not [string]::IsNullOrEmpty($response)){
               $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
               ###Write-Output "Length is $totalLength KB"
               $responseStream = $response.GetResponseStream()
                <#<#<##############Appended codes
                Problem with the code when the download file is less than 1024 bytes.
                 Corrected by doing an If/else statement that checks for file length less than 1024:
                #>#>#>
                   $responseContentLength = $response.get_ContentLength()
                    if(-not ($responseContentLength -lt 1024))
                    {
                       $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
                    }
                    else
                    {
                       $totalLength = [System.Math]::Floor(1024/1024)
                    }
                #######Appended codes end here
               $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $localTempFilePath, Create
               $buffer = new-object byte[] 10KB
               $count = $responseStream.Read($buffer,0,$buffer.length)
               $downloadedBytes = $count
                   while ($count -gt 0)
                   {
                       $targetStream.Write($buffer, 0, $count)
                       $count = $responseStream.Read($buffer,0,$buffer.length)
                       $downloadedBytes = $downloadedBytes + $count
                       ###[System.Math]::Floor($downloadedBytes/1024)
                       Write-Progress -activity "Downloading file '$($Uri.split('/') | Select -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)
                   
                   }
               Write-Progress -activity "Finished downloading file '$($Uri.split('/') | Select -Last 1)'"
               $targetStream.Flush()
               $targetStream.Close()
               $targetStream.Dispose()
               $responseStream.Dispose()
               Return $true
           }###if
           else{
                Return $false
           }
        }###Process
        End{
            if(($totalLength -eq [System.Math]::Floor($downloadedBytes/1024)) -and (0 -ne $downloadedBytes)){
                    Move-Item -Path $localTempFilePath -Destination $Destination
           }
            Remove-Variable "uriObject"
            if($response){
                Remove-Variable response
            }
            Remove-Variable "request"
        }
    }###########Download-FileWithProgress() ends here.
    ###################################################################################
    New-Variable -Name "storedStatus"
}###Begin
Process{
        Write-Information -MessageData "Downloading to $Destination" -Verbose -InformationAction Continue
        $imagesListFile=[System.IO.Path]::Combine($Destination,(Url-ToPath -Uri $Uri))
        $imagesListFile=[System.IO.Path]::ChangeExtension($imagesListFile,"txt")
        if(($Restart) -and (Test-Path $imagesListFile)){
            Remove-Item $imagesListFile
            }
        if(-not (Test-Path $imagesListFile)){
            if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($imagesListFile)))){
                New-Item -Path ([System.IO.Path]::GetDirectoryName($imagesListFile)) -ItemType Directory -Verbose -InformationAction Continue | Out-Null
                if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($imagesListFile)))){
                    Write-Error -Message "Unable to create directory. Check folder path or url." -Verbose -InformationAction Continue
                    Return $null
                }
            }
            $info=[System.Net.WebRequest]::Create($Uri)
            ###$info.UserAgent=([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
            $info.Timeout=6000;#6secs max
            $storedStatus=$info.GetResponse()
            $storedStatus.Close()
            if([string]::Equals("OK",$storedStatus.StatusCode) -or [string]::Equals("200",$storedStatus.StatusCode)){
                ###Write-Output "GOOD"
                Write-Information -MessageData "Fetching image urls..." -Verbose -InformationAction Continue
                $iwr=Invoke-WebRequest -Uri $Uri -UseBasicParsing
                $images=$iwr.Images | select src
                $list=$images
                Write-Output $list >> $imagesListFile
                if($SelectOverlap -and (-not [string]::IsNullOrWhiteSpace($SelectList))){
                    Filter-Lines -Path $imagesListFile -SelectList $selectList -SelectOverlap -ReplaceOriginal
                    }
                    elseif(-not [string]::IsNullOrWhiteSpace($SelectList)){
                        Filter-Lines -Path $imagesListFile -SelectList $selectList -ReplaceOriginal
                        }
                if($RejectOverlap -and (-not [string]::IsNullOrWhiteSpace($RejectList))){
                    Filter-Lines -Path $imagesListFile -RejectList $RejectList -RejectOverlap -ReplaceOriginal
                    }
                    elseif(-not [string]::IsNullOrWhiteSpace($RejectList)){
                        Filter-Lines -Path $imagesListFile -RejectList $RejectList -ReplaceOriginal
                        }
                if(-not [string]::IsNullOrWhiteSpace($RemoveList)){
                    Remove-Text -Path $imagesListFile -RemoveList $RemoveList -ReplaceOriginal
                    }
            }###if
        }###if
        else{
            Write-Information -MessageData "Images list file Already exist:`n    $imagesListfile" -Verbose -InformationAction Continue
           }
       if((Test-Path $imagesListFile) -and ($FetchJpgs)){
           foreach($url in Get-Content $imagesListFile){
               $filePath=Url-ToPath -Uri $url
               $filePath=([System.IO.Path]::Combine($Destination,$filePath))
                if(-not (Test-Path $filePath)){
                    if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($filePath)))){
                        New-Item -Path ([System.IO.Path]::GetDirectoryName($filePath)) -ItemType Directory | Out-Null
                    }
                    New-Item -Path $filePath -ItemType File | Out-Null
                    ###pause
                    if(-not (Test-Path $filePath)){
                        Write-Error -Message "Unable to create automatic file from url. Check url(s) for illegal characters." -Verbose -InformationAction Continue
                        ###break
                        Return $null
                        }
                        else{
                            Remove-Item $filePath -Force | Out-Null
                            }
                    ###pause
                    $fileName=([System.IO.Path]::GetFileName($filePath))
                    Write-Information -MessageData "Downloading $fileName" -Verbose -InformationAction Continue
                    ###Command for downloading.
                    Download-FileWithProgress -Uri $url -Destination $filePath
                    }
                    else{
                        Write-Information -MessageData "--->$filePath already exist." -Verbose -InformationAction Continue
                        }
               
           }###foreach()
       }###if
}
End{
    
    Remove-Variable "imagesListFile"
    Remove-Variable "storedStatus"
}
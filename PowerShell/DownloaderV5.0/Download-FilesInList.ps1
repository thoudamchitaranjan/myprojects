<#
.Synopsis
    Downloads files to a folder with the list of urls already stored in a file.
#>
param(
    [CmdletBinding()]

    [Parameter(mandatory=$true,
    Position=0,
    ValueFromPipeline=$true,
    HelpMessage="The full path of the list file which has the urls of images.")]
    [ValidateScript({Test-Path $_})]
    [string]$Path,

    [Parameter(mandatory=$true,
    Position=1,
    HelpMessage="The destination folder where images are to be downloaded to.")]
    [ValidateNotNullOrEmpty()]
    [string]$Destination,

    [Parameter(mandatory=$false,
    Position=2,
    HelpMessage="Select the keywords, images extensions here, each seperated by commas.")]
    [ValidateNotNullOrEmpty()]
    [string[]]$SelectList,

    [Parameter(mandatory=$true,
    HelpMessage="Referer url/website.")]
    [ValidateNotNullOrEmpty()]
    [string]$Referer,

    [Parameter(mandatory=$false,
    HelpMessage="Select this to download the images at the -Destination folder.")]
    [switch]$CustomDirTree=$false
)###param



    begin {
            ###############################################################################
    Function Url-ToPath {<#
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
            HelpMessage="The url which will be converted to windows(by default) relative path.")]
            [ValidateNotNullOrEmpty()]
            [string[]]$Uri,

            [Parameter(mandatory=$true,
            Position=1,
            Helpmessage="Main folder path where the path converted from the url will be joined.")]
            [ValidateNotNullOrEmpty()]
            [string]$Destination,

            [Parameter(
            mandatory=$false,
            Position=1,
            HelpMessage="Select this to convert to linux path instead of windows path.")]
            [switch]$linux=$false
            )
            begin{
                [string]$specialChars = "?*`"|<>:"
            }
            process{
                ###Removing special char for forming legal path.
                $actualLink=$Uri -replace ".*//(.*)",'$1'
                $rePattern = ($specialChars.ToCharArray() |ForEach-Object { [regex]::Escape($_) }) -join "|"
                $actualLink = $actualLink -replace $rePattern,""
                ###Applying checks...
                $actualLink=$actualLink.TrimEnd()
                $actualLink=$actualLink.TrimEnd("/")
                $path=$actualLink.TrimStart("/")
                $Destination=$Destination.TrimEnd()
                $Destination=$Destination.TrimStart()
                $Destination=$Destination.TrimEnd("/")
                $Destination=$Destination.TrimEnd("\")
                if($linux){
                    $fullPath=([System.IO.Path]::Combine($Destination,$path))
                    $fullPath=$fullPath -replace "\\","/"
                    Return $fullPath
                }
                else{
                    $fullPath=([System.IO.Path]::Combine($Destination,$path))
                    $fullPath=$fullPath -replace "/","\"
                    Return $fullPath
                }
            }
            end{
                Remove-Variable specialChars
            }
    }#######Url-ToPath() ends here.

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

            [Parameter(mandatory=$true,
            HelpMessage="Referer url/website.")]
            [ValidateNotNullOrEmpty()]
            [string]$Referer,

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
                    try{
                        Remove-Item $localTempFilePath
                    }
                    catch{
                        Return $false
                        }
               }
               elseif(-not (Test-Path ([IO.Path]::GetDirectoryName($Destination)))){
                    New-Item ([IO.Path]::GetDirectoryName($Destination)) -ItemType Directory  -Verbose -InformationAction Continue | Out-Null
               }
               ####above code bit was inserted by me.
               $uriObject = New-Object "System.Uri" "$Uri"
               $request = [System.Net.HttpWebRequest]::Create($uriObject)
               if(-not [string]::IsNullOrWhiteSpace($Referer)){
                   $request.Referer="$Referer"
                   }
               $request.set_Timeout(6000) #15 second timeout
               $response = $request.GetResponse()
               if(-not [string]::IsNullOrEmpty($response)){
                   $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
                   ###Write-Output "Length is $totalLength KB"
                   $responseStream = $response.GetResponseStream()
                   $responseStream.ReadTimeout=60000###60sec
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
                   try{
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
                    }
                    finally{
                        $targetStream.Flush()
                        $targetStream.Close()
                        $targetStream.Dispose()
                        $responseStream.Dispose()
                    }
                   Write-Progress -activity "Finished downloading file '$($Uri.split('/') | Select -Last 1)'"
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

    }###begin
    process {
        Write-Information -MessageData "`n--------------->Beginning Download session of $Path" -Verbose -InformationAction Continue
        foreach($url in Get-Content $Path){
                    $url=$url.TrimEnd()
                    $filePath=Url-ToPath -Uri $url -Destination $Destination
                    if($CustomDirTree){
                        $fileName=([System.IO.Path]::GetFileName($filePath))
                        $filePath=([System.IO.Path]::Combine($Destination,$fileName))
                    }
                    if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($filePath)))){
                            New-Item -Path ([System.IO.Path]::GetDirectoryName($filePath)) -ItemType Directory | Out-Null
                        }
                    if(-not (Test-Path $filePath)){
                        Write-Information -MessageData "Downloading to $filePath" -Verbose -InformationAction Continue
                        ###Command for downloading.
                        if([string]::IsNullOrWhiteSpace($Referer)){
                           Download-FileWithProgress -Uri $url -Destination $filePath
                           }
                           else{
                            Download-FileWithProgress -Uri $url -Destination $filePath -Referer $url
                            }
                        ###Invoke-WebRequest -Uri $url -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
                        ###.\Download-WithReferer.ps1 -Url $url -Destination $filePath
                        }
                        else{
                            Write-Information -MessageData "$filePath Already exist." -Verbose -InformationAction Continue
                            }
                }###foreach()
    }###Process
    end {
        
    }
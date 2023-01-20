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
                New-Item ([IO.Path]::GetDirectoryName($Destination)) -ItemType Directory | Out-Null
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
#Ok, so the easiest way (that I know of) to download files in powershell
# from the internet is to use the .net WebClient.
#  The simple way I started with was the two liner:

#$client = New-Object "System.Net.WebClient"
#$client.DownloadFile("http://somesite.com/largefile.zip","c:\temp\largefile.zip"

#However I was working on a script that required some pretty large files to be downloaded,
# and using the DownloadFile method has no progress indicator.
#  I figured some users might thing the program died.
#  So I decided to create a method that still uses the webclient to download the files,
# however give a status of where it is in the download.
#  Here is what I came up with, hopefully someone else will find it useful.

function downloadFile($url, $targetFile)
{
    "Downloading $url"
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
    $buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0)
    {
        [System.Console]::CursorLeft = 0
        [System.Console]::Write("Downloaded {0}K of {1}K", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
    }
    "`nFinished Download"
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
}

#This would be used like
#downloadFile "http://somesite/largefile.zip" "c:\temp\largefile.zip"
downloadFile "http://www.xiuren.org/bololi/003/0005.jpg" "D:\0005.jpg"
###https://koz.tv/setup-webclient-timeout-in-powershell/
$Source = @"
using System.Net;
public class ExtendedWebClient : WebClient
{
public int Timeout;
protected override WebRequest GetWebRequest(System.Uri address)
{
WebRequest request = base.GetWebRequest(address);
if (request != null)
{
request.Timeout = Timeout;
}
return request;
}
public ExtendedWebClient()
{
Timeout = 600000; // Timeout value by default
}
}
"@;
Add-Type -TypeDefinition $Source -Language CSharp
$webClient = New-Object ExtendedWebClient;
$webClient.Timeout = 100000; # Change timeout for webClient
#$loadData = $webClient.downloadString('http://www.xiuren.org/bololi/003/0031.jpg')###original script
$webClient.DownloadFile('http://www.xiuren.org/bololi/003/0031.jpg',"D:\0031.jpg")###my modified script
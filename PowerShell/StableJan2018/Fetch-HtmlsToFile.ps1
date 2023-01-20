###This function fetches htmls from the webpage
param (
    [Parameter(mandatory=$true,
    Position=0,
    HelpMessage="Url of webpage containing htmls for data mining.")]
    [ValidateNotNullOrEmpty()]
    [string]$Uri,

    [Parameter(mandatory=$true,
    Position=1,
    HelpMessage="Full path of file for storing htmls list.")]
    [ValidateNotNullOrEmpty()]
    ###[ValidateScript({-not (Test-Path $_)})]
    [string]$Destination
    )
        ###############Checking remote link, like pinging.
        ###This function cannot contain any output to any output device.
        ###It can only return true or false.
        Function checkRemoteUrl {
        param (
            [Parameter(mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Url
            )
        begin{
            New-Variable -Name "info"
            New-Variable -Name "storedStatus"
        }
        process{
            $info = [System.Net.WebRequest]::Create("$Url")
            $info.UserAgent = ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
            $info.Timeout = 6000; # 6 secs max
            $storedStatus = $info.GetResponse()
            try{
                $storedStatus.Close() | Out-Null
            }
            catch{
                return $false
            }
            if("OK" -ieq $storedStatus.StatusCode){
                return $true
            }
        }
        end{
            Remove-Variable -Name "info"
            Remove-Variable -Name "storedStatus"
        }
        }########checkRemoteUrl() ends here.

    if($false -eq (checkRemoteUrl $Uri)){
        Write-Information -MessageData "Webpage does not exist or No Connection.`n---Cancelled." -Verbose -InformationAction Continue
        Return $null
    }
    $iwr = (Invoke-WebRequest -Uri "$Uri" -UseBasicParsing).Links.Href
    $list="$iwr"
    if(-not (Test-Path ([System.IO.Path]::GetDirectoryName($Destination)))){
        New-Item -Path ([System.IO.Path]::GetDirectoryName($Destination)) -ItemType Directory | Out-Null
    }
    if(Test-Path ([System.IO.Path]::GetDirectoryName($Destination))){
        Write-Output "$list" >> "$Destination"
        Return "$Destination"
        }
        else{
            Write-Information -MessageData "Failed to create destination file: `n--->$Destination" -Verbose -InformationAction Continue
            }
    Return $null
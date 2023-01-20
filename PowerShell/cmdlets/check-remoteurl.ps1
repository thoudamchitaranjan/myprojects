<#
.Synopsis
        Checking remote link, like pinging, for availability of a link.
        This function does not give any output to any output device.
        It can only return true or false.
#>
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
            Write-Information -MessageData "Checking url -> $Url" -Verbose -InformationAction Continue
            $storedStatus = $info.GetResponse()
            ###Uncomment for debugging.
            ###$storedStatus
            try{
                $storedStatus.Close() | Out-Null
            }
            catch{
                return $false
            }
            if(("OK" -ieq $storedStatus.StatusCode) -or ("200" -ieq $storedStatus.StatusCode)){
                return $true
            }
            else{
                return $false
            }
        }
        end{
            Remove-Variable -Name "info"
            Remove-Variable -Name "storedStatus"
        }
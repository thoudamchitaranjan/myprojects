$ghostDir = Read-Host -Prompt "Enter the ghost directory: "
Write-Output "Ghost Directory is: $ghostDir"
Get-Content -Path "list.txt"
$status=Test-Path -Path "C:\Users\picachu\Pictures\Project\www.xiuren.org\mistar\002\"
if($false -eq $status)
{
New-Item -ItemType Directory "C:\Users\picachu\Pictures\Project\www.xiuren.org\mistar\002\"
}
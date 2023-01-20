foreach ($line in Get-Content .\xiuren.txt ) 
{
$line.Replace("/","\")
Write-Output "Line is : $line"
}
$line = Get-Content .\xiuren.txt
$line.Replace("/","\")
Write-Output "First line is: "$line[0]
Write-Output "Second line is: "$line[1]
Write-Output "Third line is: "$line[2]
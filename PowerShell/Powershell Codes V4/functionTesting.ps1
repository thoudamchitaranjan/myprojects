Function Test  {
New-Variable -Name minValue -Value $args[0] -Scope Local
New-Variable -Name maxValue -Value $args[1] -Scope Local
Write-Output "minValue is: "$minValue "First Argument is: " $args[0]
Write-Output "maxValue is: "$maxValue "Second Argument is: " $args[1]
}

Test 1001 1350
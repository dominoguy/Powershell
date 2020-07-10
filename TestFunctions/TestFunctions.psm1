#TestFunctions


#$StrFormatMessage = ""

function Formated-Date
{
    Get-Date -UFormat "%d/%A/%Y"
    $strFormatMessage = "Date Formated"
   #return $global:strFormatMessage
   return $strFormatMessage
}

Function testvariable
{
    $testmessage = "test function text"
    return $testmessage
}


Export-ModuleMember -Function Formated-Date,testvariable
#Export-ModuleMember -Variable strFormatMessage

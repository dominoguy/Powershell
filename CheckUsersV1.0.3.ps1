# Version 1.0.3
#
# Update Active Directory Users from CSV File
# Run: .\UpdateUsers.ps1
# CSV File Fields
#   EMPLOYEE,LASTNAME,FIRSTNAME,MIDDLENAME,FULLNAME,POSITION,Facility,Dep
# AD corresponding fields (Office phone is missing in the latest iteration of CSV extract file from Larry)
#   EmployeeNumber, Surname, GivenName, Initials, DisplayName, Title, Office, Department

Param ([Parameter(Mandatory=$false)] [boolean] $ExecuteFound=$False
      ,[Parameter(Mandatory=$false)] [boolean] $ExecuteNew=$False)


# Function for logging.
function logThis
{
   Param ([Parameter(Mandatory=$true)] [string] $logEntry)

   $dt = Get-Date
   $dt.ToShortDateString() +"|"+ $dt.ToShortTimeString() + "|" + $logEntry  |  Add-Content -Path $logFile
}


# Function for exporting newly created users to CSV file
function NewUserExport
{
   Param ($pnEmployeeNumber
         ,$pcFirstName
         ,$pcMiddleName
         ,$pcLastName
         ,$pcLogonName
         ,$pcPassword
         ,$pcEmailAddress
         ,$pcUserType
         ,$pdCreatedDateTime)

   $dt = Get-Date
   $pnEmployeeNumber +"|"+ $pcFirstName +"|"+ $pcMiddleName +"|"+ $pcLastName +"|"+ $pcLogonName +"|"+ $pcPassword +"|"+ $pcEmailAddress +"|"+ $pcUserType +"|"+ $pdCreatedDateTime | Add-Content -Path $cNewUsersExportFile
}



# Function to ratify names
function RatifyName($cName)
{
   $cReturn = $cName
   $cReturn = $cReturn.Replace("'","")
   $cReturn = $cReturn.Replace(" ","")
   $cReturn = $cReturn.Replace("(","_")
   $cReturn = $cReturn.Replace(")","")

   return $cReturn
}

# Get current date to append to log file names
$dDateTime = Get-Date -Format "yyyy-MM-dd-HH-mm"

# Defining log file and source file path.
$logFile             = 'Logs\UpdateUsersLog-'+$dDateTime+'.txt'
$cSourceFile         = 'UpdateUsersSource.csv'
$cPositionOUFile     = 'Position-OU-List.csv'
$cNewUsersExportFile = 'Logs\NewUsersCreated-'+$dDateTime+'.csv'

$nFoundCount     = 0
$nDisabledCount  = 0
$nCreateCount    = 0
$nTotalCount     = 0
$nSuspectCount   = 0
$nEmployeeNumberWrongCount = 0
$lContinue       = $true
$lExecuteFound   = $ExecuteFound
$lExecuteNew     = $ExecuteNew
$lExportHeader   = $True

# Check if log directory exists, it not then create it
if (-not (Test-Path -Path "Logs")) {New-Item -Name "Logs" -ItemType "directory"}

# Check if log file exists, if it does delete it to start fresh
if (Test-Path -Path $logFile -PathType leaf) {Remove-Item $logFile}

logThis " ==== Update started ===="

# Note to user what is parts are read-only and what is no
if (-not $lExecuteFound)
{
   $logMsg = "*** Note *** - FOUND records in read only mode"
   Write-Host $logMsg -ForegroundColor Yellow
   logThis "$logMsg"
}
if (-not $lExecuteNew)
{
   $logMsg = "*** Note *** - NEW records in read only mode"
   Write-Host $logMsg -ForegroundColor Yellow
   logThis "$logMsg"
}


# Check and log current AD Domain and PDC Emulator
$vDomain = Get-ADDomain | Select DistinguishedName, PDCEmulator
# Get Domain Controllers container, just to initiate the AD session
$oRootOu = Get-OrganizationalUnit -identity $vDomain.DomainControllersContainer
logThis "Run on Domain and PDCEmulator: $vDomain"


# Load CSV File
Try
{
   $oSource = Import-CSV -Path $cSourceFile
   $nTotalCount = $oSource.Count
   $logMsg = "Imported CSV File: $cSourceFile - $nTotalCount rows"
   logThis "$logMsg"
   Write-Host  $logMsg
}
Catch
{
   $logMsg = "Error importing CSV file: $cSourceFile - Script aborted."
   logThis "$logMsg"
   Write-Host $logMsg -ForegroundColor Red
   $lContinue = $False
   Break
}

#Load Position-OU CSV file
Try
{
   $oPositionOU = Import-CSV -Path $cPositionOUFile -Delimiter "|"
   $logMsg = "Imported Position-OU CSV File: $cPositionOUFile"
   logThis "$logMsg"
   Write-Host  $logMsg
}
Catch
{
   $logMsg = "Error importing Position-OU CSV file: $cPositionOUFile - Script aborted."
   logThis "$logMsg"
   Write-Host $logMsg -ForegroundColor Red
   $lContinue = $False
   Break
}

#Check to see how many fields exist in the CSV file, and also that expected fields are there
Write-Host "Checking CSV file for correct fields"
$aFields = "employee","lastname","firstname","middlename","fullname","position","facility","dep"
$oFields = ($oSource | Get-Member -MemberType NoteProperty)
if ($oFields.Count -ne $aFields.Count)
{
   $logMsg = "* Warning * - CSV Field count: $($oFields.Count) is different than expected count: $($aFields.Count)"
   logThis "$logMsg"
   Write-Host $logMsg -ForegroundColor Yellow
   $logMsg = "            - Switching to read only mode"
   logThis "$logMsg"
   Write-Host $logMsg -ForegroundColor Yellow
   $lExecuteFound = $False
   $lExecuteNew   = $False
}

foreach ($cFieldName in $aFields)
{
   if ($oFields.Name -NotContains $cFieldName)
   {
      $logMsg = "Error - required field ]$cFieldName[ not found in CSV file: $cPositionOUFile"
      logThis "$logMsg"
      Write-Host $logMsg -ForegroundColor Red
      $lContinue = $False
   }
}

if ($lContinue)
{
   # Run through import CSV file and string any values that have trailing or leading spaces.
   # Also check and see if there are any different positions from our position-ou file.  This is used to know where to place the "new" user in Active Directory OU structure.
   Write-Host "Removing leading/trailing spaces in values and checking for unknown positions specified in CSV file..."
   $nCount = 1
   foreach ($row in $oSource)
   {
      $row.employee  = $row.employee.trim()
      $row.lastname  = $row.lastname.trim()
      $row.firstname = $row.firstname.trim()
      $row.fullname  = $row.fullname.trim()
      $row.position  = $row.position.trim()
      $row.facility  = $row.facility.trim()
      $row.dep       = $row.dep.trim()

      $nCount = $nCount + 1
      if (-not ($oPositionOU.Position -eq $row.Position))
      {
         $logMsg = "Error - found Position: $($row.Position) in CSV file at line $nCount, that does not match known positions in CSV file: $cPositionOUFile"
         logThis "$logMsg"
         Write-Host $logMsg -ForegroundColor Red
         $lContinue = $False
      }
   }
}

if ($lContinue)
{
   # Create logonname from name in CSV file
   $oSource | Add-Member -MemberType NoteProperty -Name LogonName -Value "" -Force

   Write-Host "Sorting by LastName, FirstName, MiddleName"
   $NewSource = $oSource | Sort-Object -Property LastName, FirstName, MiddleName

   # Update LogonName
   $nInitialLogonNameDuplicateCount = 0

   # Generate/Finding logon names
   Write-Host "Generating/Finding LogonNames"
   foreach ($row in $NewSource)
   {
      $nEmployeeNumber = $row.Employee

      $user = Get-ADUser -Filter "EmployeeNumber -eq '$nEmployeeNumber'"  -Properties Department, DisplayName, EmployeeNumber, GivenName, Initials, SamAccountName, SurName, Office, OfficePhone, Title

      if (-not $user)
      {
         $cFirstName     = $row.FirstName.substring(0,1)
         $cLastName      = RatifyName($row.LastName)
         $cLogonName     = $cFirstName+$cLastName
         $cLogonName     = $cLogonName.ToLower()

         $user = Get-ADUser -Filter "SamAccountName -eq '$cLogonName' -and EmployeeNumber -like '*'"  -Properties Department, DisplayName, EmployeeNumber, GivenName, Initials, SamAccountName, SurName, Office, OfficePhone, Title

         if (($user) -or ($NewSource | Where-Object -Property LogonName -EQ -Value $cLogonName))
         {
            $nInitialLogonNameDuplicateCount = $nInitialLogonNameDuplicateCount + 1
            $nRowIndex = $NewSource.IndexOf($row)
            $cLogonNameOld = $cLogonName

            $nRowNumber = $NewSource.IndexOf($row)
            $cFirstName  = $row.FirstName
            $cMiddleName = $row.MiddleName
            $cLastName   = $row.LastName
            logThis "Row#: $nRowNumber - Duplicate LogonName: $cLogonName, FirstName: $cFirstName, MiddleName: $cMiddleName, LastName: $cLastName"
            Write-Host "Row#: $nRowNumber - Duplicate LogonName: $cLogonName, FirstName: $cFirstName, MiddleName: $cMiddleName, LastName: $cLastName"

            if ($row.MiddleName.Length -GT 0)
            {
               $cFirstName     = $row.FirstName.substring(0,1)
               $cMiddleInitial = $row.MiddleName.substring(0,1)
               $cLastName      = RatifyName($row.LastName)
               $cLogonName     = $cFirstName+$cMiddleInitial+$cLastName
               $cLogonName     = $cLogonName.ToLower()
            }
            else
            {
               $cFirstName     = RatifyName($row.FirstName)
               $cMiddleInitial = ""
               $cLastName      = RatifyName($row.LastName)
               $cLogonName     = $cFirstName+$cLastName
               $cLogonName     = $cLogonName.ToLower()
            }

            $user = Get-ADUser -Filter "SamAccountName -eq '$cLogonName' -and EmployeeNumber -like '*'"  -Properties Department, DisplayName, EmployeeNumber, GivenName, Initials, SamAccountName, SurName, Office, OfficePhone, Title

            if (($user) -or ($NewSource | Where-Object -Property LogonName -EQ -Value $cLogonName))
            {
               $nRowNumber = $NewSource.IndexOf($row)
               $cFirstName  = $row.FirstName
               $cMiddleName = $row.MiddleName
               $cLastName   = $row.LastName
               logThis "Row#: $nRowNumber - Duplicate LogonName: $cLogonName, FirstName: $cFirstName, MiddleName: $cMiddleName, LastName: $cLastName"
               Write-Host "Row#: $nRowNumber - Duplicate LogonName: $cLogonName, FirstName: $cFirstName, MiddleName: $cMiddleName, LastName: $cLastName"

               $nInitialLogonNameDuplicateCount = $nInitialLogonNameDuplicateCount + 1
               $nRowIndex = $NewSource.IndexOf($row)
               $cLogonNameOld = $cLogonName

               $cFirstName     = RatifyName($cFirstName)
               $cLastName      = RatifyName($cLastName)

               $cLogonName = $cFirstName+$cMiddleInitial+$cLastName
               $cLogonName = $cLogonName.ToLower()

               logThis "Record#: $nRowIndex - Initial LogonName (Duplicate): $cLogonNameOld, creating new LogonName: $cLogonName"
            }

            $row.LogonName = $cLogonName
         }
         else
         {
            $row.LogonName = $cLogonName
         }
      }
      else
      {
         $row.LogonName = $user.SamAccountName
      }
   }

   Write-Host "Checking for duplicate logon names"

   # Check for duplicates of LogonName
   $UniqueArray = $NewSource | sort-object -unique -property LogonName
   $nTotalUnique = $UniqueArray.Count
   $nTotalDuplicates = 0

   if ($nTotalUnique -ne $nTotalCount)
   {
      $nTotalDuplicates = $nTotalCount-$nTotalUnique
      Write-Host "There are $nTotalDuplicates duplicate LogonNames" -ForegroundColor Red -BackgroundColor Yellow
      logThis "There are $nTotalDuplicates duplicate LogonNames"

      $GroupArray = $NewSource | group-object -property LogonName

      foreach ($row in $GroupArray)
      {
         $cName  = $row.Name
         $nCount = $row.Count
         if ($nCount -gt 1)
         {
            logThis "$nCount - Duplicate LogonName: $cName"
         }
      }
   }

   $nCount = 0
   Write-Host "Starting to process $nTotalUnique records..."

   logThis "<------------------------------->"

   # Parse Excel file line by line
   foreach ($row in $UniqueArray)
   {
      $nCount = $nCount + 1

      if (($nCount % 100) -eq 0) {Write-Host "Processed $nCount/$nTotalUnique"}

      $cLogonName = $row.LogonName
      $nEmployeeNumber = $row.Employee
      $lUserFound = $False

      $user = Get-ADUser -Filter "EmployeeNumber -eq '$nEmployeeNumber'"  -Properties Department, DisplayName, EmployeeNumber, GivenName, Initials, SurName, Office, OfficePhone, Title

      if (-not $user)
      {
         $user = Get-ADUser -Filter "SamAccountName -eq '$cLogonName'"  -Properties Department, DisplayName, EmployeeNumber, GivenName, Initials, SurName, Office, OfficePhone, Title
      }

      # If the user is found
      If ($user)
      {
         # Is the user enabled
         if ($user.Enabled)
         {
            $lChangedUser = $false
            $nFoundCount  = $nFoundCount + 1
            $cDiffString  = ""
            $cDiffString  = $cDiffString + $row
            if ($user.GivenName.ToLower() -ne $row.FirstName.ToLower()) {$cDiffString = $cDiffString + "|AD GivenName: ["+$user.GivenName+"] - CSV FirstName: ["+$row.FirstName+"]"}
            if ($user.SurName.ToLower() -ne $row.LastName.ToLower()) {$cDiffString = $cDiffString + "  AD SurName: ["+$user.SurName+"] - CSV SurName: ["+$row.LastName+"]"}
            if ($user.EmployeeNumber -ne $row.Employee) {$cDiffString = $cDiffString + "  AD Employee#: ["+$user.EmployeeNumber+"] - CSV Employee#: ["+$row.Employee+"]"}
            logThis "Found|$($row.LogonName)|$cDiffString"

            if ($lExecuteFound)
            {
               #Update the user's employee number, department, Office, and Title
               Write-Host "Employee logon name: $cLogonName" -ForegroundColor Yellow

               if ($user.EmployeeNumber -ne $row.Employee)
               {
                  $user.EmployeeNumber = $nEmployeeNumber
                  $lChangedUser = $true
                  Write-Host "   Updated Employee Number: $($row.Employee)" -ForegroundColor Yellow
               }
               if ($user.Department -ne $row.Dep)
               {
                  $user.Department = $row.Dep
                  $lChangedUser = $true
                  Write-Host "   Updated Department: $($row.Dep)" -ForegroundColor Yellow
               }
               if ($user.Office -ne $row.Facility)
               {
                  $user.Office = $row.Facility
                  $lChangedUser = $true
                  Write-Host "   Updated Office: $($row.Facility)" -ForegroundColor Yellow
               }
               if ($user.Title -ne $row.Position)
               {
                  $user.Title = $row.Position
                  $lChangedUser = $true
                  Write-Host "   Updated Title: $($row.Position)" -ForegroundColor Yellow
               }

               if ($lChangedUser)
               {
                  Set-ADUser -Instance $user
               }
            }
         }
         Else
         {
            $nDisabledCount = $nDisabledCount + 1
            $cDiffString  = ""
            $cDiffString  = $cDiffString + $row
            if ($user.GivenName.ToLower() -ne $row.FirstName.ToLower()) {$cDiffString = $cDiffString + "|AD GivenName: ["+$user.GivenName+"] - CSV FirstName: ["+$row.FirstName+"]"}
            if ($user.SurName.ToLower() -ne $row.LastName.ToLower()) {$cDiffString = $cDiffString + "  AD SurName: ["+$user.SurName+"] - CSV SurName: ["+$row.LastName+"]"}
            logThis "Disabled|$($row.LogonName)|$cDiffString"
         }
      }
      Else
      {
         $cDiffString  = ""
         $cDiffString  = $cDiffString + $row
         $nCreateCount = $nCreateCount + 1
         $logMsg = "New|$($row.LogonName)|$cDiffString"
         logThis "$logMsg"

         if ($lExecuteNew)
         {
            # Get user's information, OU location, and setup type based on position
            $cPosition   = $row.Position.ToLower()
            $cTitle      = $row.Position
            $cOffice     = $row.Facility
            $cDepartment = $row.Dep
            $cFirstName  = $row.Firstname
            $cMiddleName = $row.Middlename
            $cLastName   = $row.Lastname

            if ($cMiddleName -GT 0)
            {
               $cMiddleInitial = $cMiddleName.Substring(0,1)
            }
            else
            {
               $cMiddleInitial = ""
            }

            $cFullName            = $cFirstName+" "+$cLastname
            $cOUDistinguishedName = $oPositionOU.ou[$oPositionOU.position.tolower().indexof($cPosition)]
            $cUserType            = $oPositionOU.UserType[$oPositionOU.position.tolower().indexof($cPosition)]

            $cPasswordString      = "Care#"+$nEmployeeNumber+$cFirstName.Substring(0,1).ToUpper()+$cLastName.Substring(0,1).ToUpper()
            $cPassword            = ConvertTo-SecureString "$cPasswordString" -AsPlainText -Force

            $oOu = Get-OrganizationalUnit -identity $cOUDistinguishedName

            switch ($cUserType.ToLower())
            {
               "full"
               {
                  # Create full AD account
               }

               "email"
               {
                  # Create email only account

                  $oOU       = Get-OrganizationalUnit -identity $cOUDistinguishedName
                  $cDatabase = "New mailbox Database - Shep"
                  $cSecurePW = (ConvertTo-SecureString -String '$cPasswordString' -AsPlainText -Force)
                  $cuserPrincipalName = $cLogonName+"@shepherdscare.org"

                  $aParameters = @{Name = $cLogonName
                                   UserPrincipalName = $cUserPrincipalName
                                   Password = $cPassword
                                   Database = "New Mailbox Database - Shep"
                                   DisplayName = $cFullName
                                   FirstName = $cFirstName
                                   LastName = $cLastName
                                   Initials = $cMiddleInitial
                                   OrganizationalUnit = $oOu
                                   ResetPasswordOnNextLogon = $True
                                  }

                  Try
                  {
                     $oMailbox = New-Mailbox @aParameters
                  }
                  Catch
                  {
                     $logMsg = "Error creating new user/mailbox for: $cLogonName - Script aborted."
                     logThis "$logMsg"
                     Write-Host $logMsg -ForegroundColor Red
                     $lContinue = $False
                     Exit
                  }


                  Try
                  {
                     $oMailbox | Set-Mailbox -MaxReceiveSize 10MB -MaxSendSize 10MB
                  }
                  Catch
                  {
                     $logMsg = "Error setting send/receive limits for: $cLogonName - Script aborted."
                     logThis "$logMsg"
                     Write-Host $logMsg -ForegroundColor Red
                     $lContinue = $False
                     Exit
                  }


                  Try
                  {
                     $oCASMailbox = $oMailbox | Get-CASMailbox
                  }
                  Catch
                  {
                     $logMsg = "Error obtaining MailboxCAS object for new user/mailbox: $cLogonName - Script aborted."
                     logThis "$logMsg"
                     Write-Host $logMsg -ForegroundColor Red
                     $lContinue = $False
                     Exit
                  }

                  Try
                  {
                     $oADUser = Get-ADUser -Filter "DistinguishedName -eq '$($oMailbox.DistinguishedName)'" -Properties Department, DisplayName, EmployeeNumber, GivenName, Initials, SurName, Office, OfficePhone, Title
                  }
                  Catch
                  {
                     $logMsg = "Error obtaining AD object for new user/mailbox: $cLogonName - Script aborted."
                     logThis "$logMsg"
                     Write-Host $logMsg -ForegroundColor Red
                     $lContinue = $False
                     Exit
                  }

                  $oADUser.Department     = $cDepartment
                  $oADUser.EmployeeNumber = $nEmployeeNumber
                  $oADUser.Office         = $cOffice
                  $oADUser.Title          = $cTitle

                  Try
                  {
                     Set-ADUser -Instance $oADUser
                  }
                  Catch
                  {
                     $logMsg = "Error setting AD user properties for user: $cLogonName - Script aborted."
                     logThis "$logMsg"
                     Write-Host $logMsg -ForegroundColor Red
                     $lContinue = $False
                     Exit
                  }

                  Try
                  {
                     $oCASMailbox | Set-CASMailbox -ActiveSyncEnabled $False -EWSEnabled $False -OWAForDevicesEnabled $False
                  }
                  Catch
                  {
                     $logMsg = "Error setting CASMailbox properties for user: $cLogonName - Script aborted."
                     logThis "$logMsg"
                     Write-Host $logMsg -ForegroundColor Red
                     $lContinue = $False
                     Exit
                  }
               }

               default
               {
               }
            }

            $cEmailAddress = $oMailbox.PrimarySmtpAddress.Address
            $dDateTime = Get-Date -Format "yyyy-MM-dd-HH-mm"

            if ($lExportHeader)
            {
               #Write header information to new user export csv file
               NewUserExport "Employee" "Firstname" "Middlename" "Lastname" "LogonName" "Password" "EmailAddress" "UserType" "DateCreated"
               $lExportHeader = $False
            }

            # Log new user creation to file
            NewUserExport $nEmployeeNumber $cFirstName $cMiddleName $cLastName $cLogonName $cPasswordString $cEmailAddress $cUserType $dDateTime

            #Clear any objects before getting/creating next mailbox/user
            $oOu         = $Null
            $oMailbox    = $Null
            $oCASMailbox = $Null
            $oADUser     = $Null
         }
      }
   }
   logThis "<------------------------------->"

   Write-Host "Complete."
   Write-Host " "
   Write-Host "Disabled Users Count: $nDisabledCount"
   Write-Host "   Suspect New Users: $nSuspectCount"
   Write-Host " "
   logThis "Disabled Users Count: $nDisabledCount"
   logThis "   Suspect New Users: $nSuspectCount"
   logThis " "
   Write-Host " FoundCount=$nFoundCount"
   logThis " FoundCount=$nFoundCount"
   Write-Host "CreateCount=$nCreateCount"
   logThis "CreateCount=$nCreateCount"
   Write-Host " Duplicates=$nTotalDuplicates"
   logThis " Duplicates=$nTotalDuplicates"
   Write-Host "            ----"
   logThis "            ----"
   Write-Host " TotalCount=$nTotalCount"
   logThis " TotalCount=$nTotalCount"
   Write-Host "            ===="
   logThis "            ===="
   Write-Host " "
   logThis " "
   if ($nInitialLogonNameDuplicateCount)
   {
      Write-Host "Info: InitialLogonNameDuplicateCount=$nInitialLogonNameDuplicateCount"
      logThis "Info: InitialLogonNameDuplicateCount=$nInitialLogonNameDuplicateCount"
   }
   if ($nEmployeeNumberWrongCount)
   {
      Write-Host "ERROR: EmployeeNumberWrongCount=$nEmployeeNumberWrongCount" -ForegroundColor Red -BackgroundColor Yellow
      logThis "ERROR: EmployeeNumberWrongCount=$nEmployeeNumberWrongCount"
   }
}
$logMsg = "=== Finish script execution! consult file: $vPath\$logFile for detailed results."
logThis " "
logThis "=== Complete ==="

if ($lContinue)
{
   Write-Host $logMsg -ForegroundColor Green
}
Else
{
   Write-Host $logMsg -ForegroundColor Red
}


' Uspider v1.2.0 by jimmy19990
' ==========================
' With great might comes great responsibility. DO NOT BE EVIL.
' URL: https://github.com/jimmy19990/USpider.vbs
'
' -------------------
' Configurations
' -------------------
'
' Destination Folder
'
' This defines the destination folder where Uspider will store the copied files.
' Uspider will create subfolders named by Volume Serial Numbers to separate files from different devices.
destFolder = "D:\USpider"

' Xcopy Parameters
'
' You can set whatever parameters you want to use with xcopy.
' Execute "xcopy /?" in Command Prompt for more information.
xcopyParameters = "/e /r /y"

' Custom List
'
' Uspider allows you to create custom lists to include/exclude certain devices.
' 
' "isBlacklist" defines the type of the list.
' Set it to "true" if you want a Black List, so that ONLY files inside the listed devices WILL BE copied.
' Set it to "false" if you want a White List, so that files inside the listed devices will NOT be copied.
isBlackList = false

' "customList" is an array which stores the Volume Serial Number.
' "VolumeSerialNumber" is declared in "Win32_LogicalDisk" Class.
' You can use a simple script I created (getVolumeSN.vbs) to obtain Volume Serial Numbers for all of your devices.
' To learn more about "Win32_LogicalDisk", please visit: https://msdn.microsoft.com/en-us/library/aa394173(v=vs.85).aspx.
customList = array("")

'
' -------------------
' Main Script
' -------------------

' Initialize Objects
strComputer = "." 
Set objFileSystem = CreateObject("Scripting.FileSystemObject")
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set objWScriptShell = CreateObject("WScript.Shell")
Set colEvents = objWMIService.ExecNotificationQuery _
    ("Select * From __InstanceOperationEvent Within 10 Where " _
        & "TargetInstance isa 'Win32_LogicalDisk'")

' Record availability to avoid repeat copyings.
Dim isAvailable(26)
For i = 0 to 25
    isAvailable(i) = true
Next

' Initialize Destination Folder.
If objFileSystem.folderExists(destFolder) = false Then
    objFileSystem.CreateFolder destFolder
End If

Do While True
    Set objEvent = colEvents.NextEvent
    ' Check if the target device type is Removable Device (DriveType = 2).
    If objEvent.TargetInstance.DriveType = 2 Then
        Select Case objEvent.Path_.Class
            ' Insert
            Case "__InstanceCreationEvent"
                ' Ensure only copy once.
                If isAvailable(Asc(Left(objEvent.TargetInstance.DeviceId, 1))-65) = true Then
                    ' Check if the device is in custom list.
                    isExcluded = false
                    If VarType(customList) = 8204 Then
                        If InStr(Join(customList, "|"), objEvent.TargetInstance.VolumeSerialNumber) > 0 Then
                            isExcluded = true
                        End If
                    End If
                    
                    If isExcluded = isBlackList Then
                        ' Initialize Work Folder.
                        workFolder = destFolder + "\" + objEvent.TargetInstance.VolumeSerialNumber
                        If objFileSystem.folderExists(workFolder) = false Then
                            objFileSystem.CreateFolder workFolder
                        End If
                        ' Copy All Files.
                        c = "cmd.exe /c xcopy " + objEvent.TargetInstance.DeviceId + "\* " + workFolder + " " + xcopyParameters
                        objWScriptShell.Run(c), 0
                    End If
                        
                    ' Update availability.
                    isAvailable(Asc(Left(objEvent.TargetInstance.DeviceId, 1))-65) = false
                End If
            ' Eject
            Case "__InstanceDeletionEvent"
                ' Update availability.
                isAvailable(Asc(Left(objEvent.TargetInstance.DeviceId, 1))-65) = true
        End Select
    End If
Loop

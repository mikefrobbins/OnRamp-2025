﻿#region Presentation Info

<#
    Functions and script modules
    OnRamp track - PowerShell + DevOps Global Summit
    Author:  Mike F. Robbins
    Website: https://mikefrobbins.com/
#>

#endregion

#region Safety

# Prevent the entire script from running instead of a selection

# The throw keyword causes a terminating error. You can use the
# throw keyword to stop the process of a command, function, or script.
throw "You're not supposed to run the entire script"

#endregion

#region Presentation prep

# Locate the VS Code settings.json file
$macSettingsPath = "$HOME/Library/Application Support/Code/User/profiles/-12baa4e9/settings.json"
$windowsSettingsPath = "$env:APPDATA\Code\User\settings.json"
$linuxSettingsPath = "$HOME/.config/Code/User/settings.json"

switch ($true) {
    {Test-Path -Path $macSettingsPath -PathType Leaf} {$vsCodeSettingsPath = $macSettingsPath; break}
    {Test-Path -Path $windowsSettingsPath -PathType Leaf} {$vsCodeSettingsPath = $windowsSettingsPath; break}
    {Test-Path -Path $linuxSettingsPath -PathType Leaf} {$vsCodeSettingsPath = $linuxSettingsPath; break}
    default {Write-Warning -Message 'Unable to locate VS Code settings.json file'}
}

# Return the current color theme and zoom level for VS Code
$vsCodeSettings = Get-Content -Path $vsCodeSettingsPath
$vsCodeSettings | ConvertFrom-Json | Select-Object -Property 'workbench.colorTheme', 'window.zoomLevel'

# Update the color theme to ISE and zoom level to 2
if ($vsCodeSettings -match '"workbench.colorTheme": ".*",') {
    $vsCodeSettings = $vsCodeSettings -replace '"workbench.colorTheme": ".*",', '"workbench.colorTheme": "PowerShell ISE",'
}
if ($vsCodeSettings -match '"window.zoomLevel": \d,') {
    $vsCodeSettings = $vsCodeSettings -replace '"window.zoomLevel": \d,', '"window.zoomLevel": 2,'
}

# Apply the settings
$vsCodeSettings | Out-File -FilePath $vsCodeSettingsPath

# Clear the screen
Clear-Host

# Set location
$Path = 'C:\OnRamp'
if (-not(Test-Path -Path $Path -PathType Container)) {
    New-Item -Path $Path -ItemType Directory | Out-Null
}
Set-Location -Path $Path

#endregion

#region Dot-Sourcing functions

<#
    To avoid Scoping gotchas, test your functions from the PowerShell console
    or your terminal of choice instead of just inside VS Code.
#>

# Creating and dot-sourcing a function

# Define the script path
$scriptPath = "$Path\Get-MrComputerName.ps1"

# Create the file if it doesn't exist
New-Item -Path $scriptPath -ItemType File -Force

# Open the file in VS Code
code $scriptPath

# Add code for the Get-MrPSVersion function to the ps1 file
Set-Content -Path "$Path\Get-MrComputerName.ps1" -Value @'
function Get-MrComputerName {
    $env:COMPUTERNAME
}
'@

# Demonstrate running the the script. Why doesn't anything happen?
.\Get-MrComputerName.ps1

# Try to call the function
Get-MrComputerName

# Check to see if the function exists on the Function PSDrive
Get-PSDrive
Get-ChildItem -Path Function:\Get-MrComputerName

# The function needs to be dot-sourced to load it into the global scope
. .\Get-MrComputerName.ps1

# Try to call the function again
Get-MrComputerName

# Show that the function exists on the Function PS Drive
Get-ChildItem -Path Function:\Get-MrComputerName

# Remove the function from the Function PSDrive
Get-ChildItem -Path Function:\Get-MrComputerName | Remove-Item

# Show that the function no longer exists on the Function PS Drive
Get-ChildItem -Path Function:\Get-MrComputerName
Get-MrComputerName

#endregion

#region Parameter Naming

function Test-MrParameter {

    param (
        $ComputerName
    )

    Write-Output $ComputerName

}

Test-MrParameter -ComputerName Server01, Server02

<#
    Why did I use ComputerName instead of Computer, ServerName, or Host for my parameter
    name? Because I wanted my function standardized like the built-in cmdlets.
#>

function Get-MrParameterCount {
    param (
        [string[]]$ParameterName
    )

    foreach ($Parameter in $ParameterName) {
        $Results = Get-Command -ParameterName $Parameter -ErrorAction SilentlyContinue

        [pscustomobject]@{
            ParameterName   = $Parameter
            NumberOfCmdlets = $Results.Count
        }
    }
}

Get-MrParameterCount -ParameterName ComputerName, Computer, ServerName, Host, Machine
Get-MrParameterCount -ParameterName Path, FilePath

<#
    There are several built-in commands with a ComputerName parameter, but depending on what
    modules are loaded there are little to none with any of the other names that were tested.
#>

function Test-MrParameter {

    param (
        $ComputerName
    )

    Write-Output $ComputerName

}

<#
    This function doesn't have any common parameters. You can view all of the
    availble parameters with Get-Command.
#>

Get-Command -Name Test-MrParameter -Syntax
(Get-Command -Name Test-MrParameter).Parameters.Keys

#endregion

#region Advanced Functions

<#
    Adding CmdletBinding turns a function into an advanced function.
    CmdletBinding requires a param block, but the param block can be empty.
#>

function Test-MrCmdletBinding {

    [CmdletBinding()] #<<-- This turns a regular function into an advanced function
    param (
        $ComputerName
    )

    Write-Output $ComputerName

}

# There are now additional (common) parameters.
Get-Command -Name Test-MrCmdletBinding -Syntax
(Get-Command -Name Test-MrCmdletBinding).Parameters.Keys

#endregion

#region Parameter Validation

<#
    Validate input early on. Why allow your code to continue on a path
    when it's not possible to complete successfully without valid input?
#>

# Type Constraints

# Always type the variables that are being used for your parameters (specify a datatype).

function Test-MrParameterValidation {

    [CmdletBinding()]
    param (
        [string]$ComputerName
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation -ComputerName Server01
Test-MrParameterValidation -ComputerName Server01, Server02
Test-MrParameterValidation

<#
    Typing the ComputerName parameter as a string only allows one value to be specified.
    Specifying more than one value generates an error. The problem though, is this doesn't prevent
    someone from specifying a null or empty value for that parameter or omitting it altogether.
#>

# Mandatory Parameters

<#
    In order to make sure a value is specified for the ComputerName
    parameter, make it a mandatory parameter.
#>

function Test-MrParameterValidation {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation

<#
    Now when the ComputerName parameter isn't specified, it prompts for a
    value. Notice that it only prompts for one value since the Type is a string.
    When the ComputerName parameter is specified without a value, with a null
    value, or with an empty string as its value, an error is generated.

    More than one value can be accepted by the ComputerName parameter by
    Typing it as an array of strings.
#>

function Test-MrParameterValidation {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation

<#
    At least one value is required since the ComputerName parameter is
    mandatory. Now that it accepts an array of strings, it continues to
    prompt for values when the ComputerName parameter is omitted until
    no value is provided, followed by pressing <enter>.
#>


# Default Values

# Default values can NOT be used with mandatory parameters.

function Test-MrParameterValidation {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName = $env:COMPUTERNAME #<<-- This will not work with a mandatory parameter
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation

<#
    Notice that the default value wasn't used in the previous example when the
    ComputerName parameter was omitted. Instead, it prompted for a value.

    To use a default value, specify the ValidateNotNullOrEmpty parameter validation
    attribute instead of making the parameter mandatory.
#>

# ValidateNotNullOrEmpty parameter validation attribute

function Test-MrParameterValidation {

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation
Test-MrParameterValidation -ComputerName Server01, Server02

# Enumerations

# The following example demonstrates using an enumeration to validate parameter input.

function Test-MrConsoleColorValidation {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [System.ConsoleColor[]]$Color = [System.Enum]::GetValues([System.ConsoleColor])
    )
    Write-Output $Color
}

Test-MrConsoleColorValidation
Test-MrConsoleColorValidation -Color Blue, DarkBlue
Test-MrConsoleColorValidation -Color Pink

<#
    Notice that a error is returned when an invalid value is provided that
    doesn't exist in the enumeration.

    How do you find what enumerations are available? See the following
    command.
#>

[AppDomain]::CurrentDomain.GetAssemblies().Where({-not($_.IsDynamic)}).ForEach({
    $_.GetExportedTypes().Where({$_.IsPublic -and $_.IsEnum})
})

# Valid values for the DayOfWeek enumeration.

[System.Enum]::GetValues([System.DayOfWeek])

# Type Accelerators

<#
    How do you validate IP addresses in PowerShell? Maybe a complicated regular expression?
    Type accelerators make the process of validating both IPv4 and IPv6 addresses simple.
#>

function Test-MrIPAddress {
    [CmdletBinding()]
    param (
        [ipaddress]$IPAddress
    )
    Write-Output $IPAddress
}

Test-MrIPAddress -IPAddress 10.1.1.255
Test-MrIPAddress -IPAddress 10.1.1.256
Test-MrIPAddress -IPAddress 2001:db8::ff00:42:8329
Test-MrIPAddress -IPAddress 2001:db8:::ff00:42:8329

# How do you find Type Accelerators? With the following code.

[psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get |
    Sort-Object -Property Value

#endregion

#region Verbose Output

<#
    Inline comments should be used sparingly because no one other than someone looking
    through the code sees them.
#>

function Test-MrVerboseOutput {

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    foreach ($Computer in $ComputerName) {
        # Attempting to perform some action on $Computer
        # Don't use inline comments like this, use write verbose instead.
        Write-Output $Computer
    }

}

Test-MrVerboseOutput -ComputerName Server01, Server02 -Verbose

# Use Write-Verbose instead of inline comments.

function Test-MrVerboseOutput {

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    foreach ($Computer in $ComputerName) {
        Write-Verbose -Message "Attempting to perform some action on $Computer"
        Write-Output $Computer
    }

}

Test-MrVerboseOutput -ComputerName Server01, Server02
Test-MrVerboseOutput -ComputerName Server01, Server02 -Verbose

#endregion

#region Pipeline Input

# By Value

# Pipeline input By Value is what I call By Type.

function Test-MrPipelineInput {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline)]
        [string[]]$ComputerName
    )

    PROCESS {   
        Write-Output $ComputerName    
    }

}

'Server01', 'Server02' | Get-Member
'Server01', 'Server02' | Test-MrPipelineInput

<#
    When Pipeline input By Value is used, the Type that is specified for the parameter
    can be piped in.

    When a different type of object is piped in, it doesn't work.
#>

$Object = New-Object -TypeName PSObject -Property @{'ComputerName' = 'Server01', 'Server02'}
$Object
$Object | Get-Member
$Object | Test-MrPipelineInput


#Pipeline Input by Property Name

<#
    Pipeline input by property name is more straight forward as it looks for input
    that matches the actual property name such as ComputerName in the following example.
#>

function Test-MrPipelineInput {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {   
        Write-Output $ComputerName    
    }

}

'Server01', 'Server02' | Test-MrPipelineInput


$Object | Test-MrPipelineInput


#Pipeline Input by Value and by Property Name

<#
    Both By Value and By Property Name can both be added to the same parameter.
    By Value is always attempted first and By Property Name is only attempted
    if By Value doesn't work.
#>

function Test-MrPipelineInput {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {  
        Write-Output $ComputerName
    }

}

'Server01', 'Server02' | Test-MrPipelineInput
$Object | Test-MrPipelineInput

'Server01', 'Server02', $Object | Test-MrPipelineInput

#### Important Considerations when using Pipeline Input

# The begin block does not have access to the items that are piped to a command.

function Test-MrPipelineInput {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    BEGIN {
        Write-Output "Test $ComputerName"
    }

}

'Server01', 'Server02' | Test-MrPipelineInput
$Object | Test-MrPipelineInput

<#
    Notice that the actual computer name does not follow word Test in the output shown
    in the previous figure.
#>

#endregion

#region Error Handling

<#
    Use try / catch where you think an error may occur. Only terminating errors are
    caught. Turn a non-terminating error into a terminating one. Don't change
    $ErrorActionPreference unless absolutely necessary and change it back if you do.
    Use -ErrorAction on a per command basis instead.

    In the following example, an unhandled exception is generated when a computer
    cannot be contacted.
#>

function Test-MrErrorHandling {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {
        foreach ($Computer in $ComputerName) {
            Test-WSMan -ComputerName $Computer
        }
    }

}

Test-MrErrorHandling -ComputerName DoesNotExist

<#
    Adding a try/catch block still causes an unhandled exception to occur
    because the command doesn't generate a terminating error.
#>

function Test-MrErrorHandling {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {
        foreach ($Computer in $ComputerName) {
            try {
                Test-WSMan -ComputerName $Computer
            } catch {
                Write-Warning -Message "Unable to connect to Computer: $Computer"
            }
        }
    }

}

Test-MrErrorHandling -ComputerName DoesNotExist

<#
    Specifying the ErrorAction parameter with Stop as the value turns a non-terminating
    error into a terminating one.
#>

function Test-MrErrorHandling {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {
        foreach ($Computer in $ComputerName) {
            try {
                Test-WSMan -ComputerName $Computer -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "Unable to connect to Computer: $Computer"
            }
        }
    }

}

Test-MrErrorHandling -ComputerName DoesNotExist

#endregion

#region Comment Based Help

#The following example demonstrates how to add comment based help to your functions.

function Get-MrAutoStoppedService {

<#
.SYNOPSIS
    Returns a list of services that are set to start automatically, are not
    currently running, excluding the services that are set to delayed start.

.DESCRIPTION
    Get-MrAutoStoppedService is a function that returns a list of services from
    the specified remote computer(s) that are set to start automatically, are not
    currently running, and it excludes the services that are set to start automatically
    with a delayed startup.

.PARAMETER ComputerName
    The remote computer(s) to check the status of the services on.

.PARAMETER Credential
    Specifies a user account that has permission to perform this action. The default
    is the current user.

.EXAMPLE
     Get-MrAutoStoppedService -ComputerName 'Server1', 'Server2'

.EXAMPLE
     'Server1', 'Server2' | Get-MrAutoStoppedService

.EXAMPLE
     Get-MrAutoStoppedService -ComputerName 'Server1', 'Server2' -Credential (Get-Credential)

.INPUTS
    String

.OUTPUTS
    PSCustomObject

.NOTES
    Author:  Mike F. Robbins
    Website: https://mikefrobbins.com/
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (

    )

    #Function Body

}

<#
    This provides the users of your function with a consistent help experience with
    your functions that's just like using the default built-in cmdlets.
#>

help Get-MrAutoStoppedService

#endregion

#region Script Module

<#
    A script module in PowerShell is simply a file containing one or more
    functions that's saved as a PSM1 file instead of a PS1 file.

    How do you create a script module file? Not with the New-Module cmdlet.
#>

help New-Module -Online

# Create a directory for the script module
New-Item -Path $Path -Name OnRamp -ItemType Directory

# Create the script module (PSM1 file)
New-Item -Path "$Path\OnRamp" -Name OnRamp.psm1 -ItemType File

# Add the two previously used functions to our script module
Set-Content -Path "$Path\OnRamp\OnRamp.psm1" -Encoding UTF8 -Value @'
function Open-OnRampRepo {
    Start-Process https://github.com/devops-collective-inc/OnRamp-2025
}

function Get-OnRampBuddyPair {
<#
.SYNOPSIS
    Pairs attendees with buddies from two separate groups.

.DESCRIPTION
    Randomly pairs each attendee with a unique buddy from a separate list.
    If there are more attendees than buddies, unmatched attendees are still
    included with a null buddy value. Buddies are never assigned more than
    once. The pairing is randomized on each function call.

.PARAMETER Attendee
    A list of attendees to be paired. Each attendee will be matched with one
    buddy, if enough buddies are available.

.PARAMETER Buddy
    A list of buddies to be paired. Each buddy is matched with one attendee
    at most.

.EXAMPLE
    Get-OnRampBuddyPair -Attendee Alex, Jordan -Buddy Casey, Morgan

.OUTPUTS
    PSCustomObject

.NOTES
    Author:  Mike F. Robbins
    Website: https://mikefrobbins.com/
    Twitter: @mikefrobbins
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$Attendee,

        [Parameter(Mandatory)]
        [string[]]$Buddy
    )

    # Shuffle both lists independently
    $shuffledAttendee = $Attendee | Sort-Object {Get-Random}
    $shuffledBuddy = $Buddy | Sort-Object {Get-Random}

    # Pair attendees to buddies (only while we have buddies left)
    for ($i = 0; $i -lt $shuffledAttendee.Count; $i++) {
        if ($i -lt $shuffledBuddy.Count) {
            [PSCustomObject]@{
                Attendee = $shuffledAttendee[$i]
                Buddy    = $shuffledBuddy[$i]
            }
        }
        else {
            # No buddy available — still return attendee with $null buddy
            [PSCustomObject]@{
                Attendee = $shuffledAttendee[$i]
                Buddy    = $null
            }
        }
    }

}
'@

# Open the new script module file in VS Code
code $Path\OnRamp\OnRamp.psm1

# Try to call one of the functions
Open-OnRampRepo

<#
    In order to take advantage of module autoloading, a script module needs
    to be saved in a folder with the same base name as the PSM1
    file and in a location specified in $env:PSModulePath.
#>

# Show the PSModulePath on my computer
$env:PSModulePath -split ';'

#******************************************************************
#Close out of all open script and/or module files
#******************************************************************

# Move our newly created module to a location that exist in $env:PSModulePath
Move-Item -Path $Path\OnRamp -Destination $env:USERPROFILE\Documents\PowerShell\Modules

# Try to call one of the functions
Open-OnRampRepo

#endregion

#region Module Manifests

<#
    All script modules should have a module manifest which is a PSD1 file that
    contains meta data about the module itself. New-ModuleManifest is used to
    create a module manifest. Path is the only value that's required. However,
    the module won't work if root module is not specified. It's a good idea to
    specify Author and Description because they are required if you decide to
    upload your module to a Nuget repository with PowerShellGet.

    The version of a module without a manifest is 0.0 (This is a dead givaway
    that the module doesn't have a manifest).
#>

Get-Module -Name OnRamp -ListAvailable

<#
    The module manifest can be initially created with all this information
    instead of updating it. You don't really want to recreate the manifest once
    it's created because the GUID will change
#>

$manifestPath = "$env:USERPROFILE\Documents\PowerShell\Modules\OnRamp\OnRamp.psd1"

$ManifestParams = @{
    Path = $manifestPath
    RootModule = 'OnRamp'
    Author = 'Mike F. Robbins'
    Description = 'OnRamp'
    CompanyName = 'mikefrobbins.com'
}

New-ModuleManifest @ManifestParams

#Check to see if any commands are exported
Import-Module -Name OnRamp -Force
Get-Command -Module OnRamp
Get-Module -Name OnRamp

# View the module manifest
code $manifestPath

# Update the module manifest
Update-ModuleManifest -Path $manifestPath -FunctionsToExport 'Open-OnRampRepo', 'Get-OnRampBuddyPair'

#endregion

#region Publish to the PowerShell gallery

$psGalleryApiKey = Get-Secret -Name PSGalleryApiKey | ConvertFrom-SecureString -AsPlainText
Publish-Module -Name OnRamp -Repository PSGallery -NuGetApiKey $psGalleryApiKey

Find-Module -Name OnRamp
Start-Process https://www.powershellgallery.com/

#endregion

#region Cleanup

#Reset the settings changes for this presentation

$macSettingsPath = "$HOME/Library/Application Support/Code/User/profiles/-12baa4e9/settings.json"
$windowsSettingsPath = "$env:APPDATA\Code\User\settings.json"
$linuxSettingsPath = "$HOME/.config/Code/User/settings.json"

switch ($true) {
    {Test-Path -Path $macSettingsPath -PathType Leaf} {$vsCodeSettingsPath = $macSettingsPath; break}
    {Test-Path -Path $windowsSettingsPath -PathType Leaf} {$vsCodeSettingsPath = $windowsSettingsPath; break}
    {Test-Path -Path $linuxSettingsPath -PathType Leaf} {$vsCodeSettingsPath = $linuxSettingsPath; break}
    default {Write-Warning -Message 'Unable to locate VS Code settings.json file'}
}
  
$vsCodeSettings = Get-Content -Path $vsCodeSettingsPath
$vsCodeSettings | ConvertFrom-Json | Select-Object -Property 'workbench.colorTheme', 'window.zoomLevel'

if ($vsCodeSettings -match '"workbench.colorTheme": ".*",') {
    $vsCodeSettings = $vsCodeSettings -replace '"workbench.colorTheme": ".*",', '"workbench.colorTheme": "Visual Studio Dark",'
}
if ($vsCodeSettings -match '"window.zoomLevel": \d,') {
    $vsCodeSettings = $vsCodeSettings -replace '"window.zoomLevel": \d,', '"window.zoomLevel": 0,'
}

$vsCodeSettings | Out-File -FilePath $vsCodeSettingsPath

Get-ChildItem -Path $env:USERPROFILE\Documents\PowerShell\Modules\OnRamp -Recurse | Remove-Item -Confirm:$false
Get-ChildItem -Path C:\OnRamp -Recurse | Remove-Item -Confirm:$false
Get-ChildItem -Path Function:\Open-OnRampRepo, Function:\Get-OnRampBuddyPair -ErrorAction SilentlyContinue | Remove-Item

#endregion

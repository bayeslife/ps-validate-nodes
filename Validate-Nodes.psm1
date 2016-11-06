# This is intended to download a test script on multiple destination hosts and runs it.
#Requires -Version 3.0


# TestConfig = {
#  Hosts: [ 'host': 'host name where to execute test', 'creds':'credentials for the host' ]   
#}
function Validate-Nodes {

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$moduleToTest
    )

    if(Test-Path ENV:\TestConfig){ 
        $TestConfig = $ENV:TestConfig | ConvertFrom-Json
    }else {
        throw "The environment variable TestConfig should define hosts"        
    }    

    foreach ($Host in $TestConfig.Hosts) {
    
        Write-Host($Host.host);
        $h = $Host.host
        
        $RemoteSession = INewPSSession($Host.host,$Host.creds)
        
        $executeTest = {
            param($testContentUri)  
            $c = IRetrieveTestContent -content $testContentUri            
            return $c.content | Invoke-Expression
        }
       
        $Result = IInvokeCommand -remoteSession $RemoteSession -executionTest $executeTest -Content $moduleToTest
    
        $Json = $Result | ConvertTo-Json
        Set-Content -Path "/tmp/Test.$h.json" -Value $Json         
        IRemovePSSession ‐Session $RemoteSession
    }

}

# Create a remote session. Separated as a function to be able to mock it out
function INewPSSession($RemoteHost, $RemoteHostCreds) {
     return New‐PSSession ‐ComputerName $RemoteHost ‐Credential $RemoteHostCreds     
}

# Removes a session.  Separated as a function to be able to mock it out
function IRemovePSSession($RemoteSession) {
     return Remove‐PSSession ‐Session $RemoteSession     
}

#Mechanism to retrieve the test content from the node where the test is run.
#Separated as a function to be able to mock it out
function IRetrieveTestContent{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String]$content    
    )
    return Invoke-WebRequest -URI $content
}

#Runs the command on the remote host
function IInvokeCommand{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ScriptBlock]$executionTest,

        [Parameter(Mandatory)]
        $remoteSession,

        [Parameter(Mandatory)]
        $content
    )
    return { Invoke-Command -Session $remoteSession -ScriptBlock $executeTest -ArgumentList $content }
}
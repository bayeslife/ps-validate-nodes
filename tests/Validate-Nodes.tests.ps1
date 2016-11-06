 

$path = (Get-Item -Path ".\" -Verbose).FullName

Remove-Module Validate-Nodes -Force
Import-Module $path/Validate-Nodes.psm1


InModuleScope Validate-Nodes {

    # function MockTest{
    #     Write-Host "Mock Test Ran"
    # }
    #$mockTest =  "& (Get-Item 'Function:MockTest')"

    $mockTest = { Write-host "Mock Test Ran"}  

    $shouldThrow = {
            Try {
                Validate-Nodes  -module "http://localhost:1080/doesntmatter" 
                "An exception is expected" | Should be $false
            } Catch {                
                Write-Host $_.Exception.Message
            }
        }

    $shouldNotThrow = {
            Try {
                Validate-Nodes  -module "http://localhost:1080/doesntmatter"             
            } Catch {                
                "An exception is not expected" | Should be $false
            }
        }

    Describe "Checking " {
        Context "ENV Test Configuration" {        
            It "should throw an exception when the TestConfig environment variable is not defined" {     
                Mock INewPSSession { return "MockedSession"}    
                Mock IRemovePSSession { return "Removed MockedSession"}   
                & $shouldThrow
            }
            It "should fail if there is no exception throw" { #This tests the test itself                
                Mock Validate-Nodes { "donothing" }            
                & $shouldNotThrow
            }
        }
        Context "Iteration" {
            It "should throw exception when bad TestConfig" {
                $Env:TestConfig = "{"
                & $shouldThrow
            }
            It "should do nothing when the TestConfig has no hosts property" {
                $Env:TestConfig = "{}"
                & $shouldNotThrow
            }
            It "should do nothing when the TestConfig has no hosts" {
                $Env:TestConfig = "{ 'Hosts': [] }"
                & $shouldNotThrow
            }
             It "should iterate twice" {
                $Env:TestConfig = "{ 'Hosts': [ { 'host': 'node1', 'cred': 'cred1' },{ 'host': 'node2', 'cred': 'cred2' } ] }"
                Mock INewPSSession { return "MockedSession"}
                Mock IRemovePSSession { return "Removed MockedSession"}
                Mock IRetrieveTestContent { return @{ content="{}" }  }
                Mock IInvokeCommand { "do nothing"}
                & $shouldNotThrow
                Assert-MockCalled IInvokeCommand 2            
             }
        }
        
        Context "InvokeCommand" {
            It "should not be empty" {
                $Env:TestConfig = "{ 'Hosts': [ { 'host': 'node1', 'cred': 'cred1' } ] }"
                
                Mock  INewPSSession { return "MockedSession"}
                Mock  IRemovePSSession { return "Removed MockedSession"}
                            
                Mock  IRetrieveTestContent {                                                                            
                    return @{ content=$mockTest }
                }

                Mock IInvokeCommand { 
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
                    
                    Write-Host "Remote Session:" $remoteSession
                    Invoke-Command -ScriptBlock $executionTest -ArgumentList $content
                    
                }

                Validate-Nodes  -module "http://localhost:1080/doesnotmatter"                                                
            }
        }
    }
}
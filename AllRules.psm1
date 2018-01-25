function StopUsingWriteHost {
    <#
    .DESCRIPTION
        Do not use Write-Host.
    #>

    param (
        [System.Management.Automation.Language.CommandAst]$someAst
    )

    if ($someAst.GetCommandName() -eq 'Write-Host') {
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            RuleName             = $myinvocation.InvocationName
            Message              = 'Please do not use Write-Host'
            Extent               = $someAst.Extent
        }
    }
}

function NoMoreTicks {
    <#
    .DESCRIPTION
        Do not use tick to continue lines.
    #>

    param (
        [System.Management.Automation.Language.Token[]]$token
    )

    $token | Where-Object Kind -eq 'LineContinuation' | ForEach-Object {
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            RuleName             = $myinvocation.InvocationName
            Message              = 'Do not use tick for line continuation'
            Extent               = $_.Extent
        }
    }
}

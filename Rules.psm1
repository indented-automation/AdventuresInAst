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

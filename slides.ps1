{ ## Accessing the AST
$scriptBlock = {
    Write-Host 'Hello world'
}
$scriptBlock.Ast
}
{ ## AST from a string
$script = "Write-Host 'Hello world'"
$tokens = @()
$errors = @()
[System.Management.Automation.Language.Parser]::ParseInput(
    $script,
    [Ref]$tokens,
    [Ref]$errors
)
}
{ ## AST from a file
Set-Content -Path script.ps1 -Value "Write-Host 'Hello world'"
$tokens = @()
$errors = @()
[System.Management.Automation.Language.Parser]::ParseFile(
    (Get-Item script.ps1).FullName,
    [Ref]$tokens,
    [Ref]$errors
)
}
{ ## ParseInput: fileName argument
$script = "Write-Host 'Hello world'"
Set-Content -Path script.ps1 -Value "Write-Host 'Goodbye'"
$tokens = @()
$errors = @()
$ast = [System.Management.Automation.Language.Parser]::ParseInput(
    $script,
    (Get-Item script.ps1).FullName,
    [Ref]$tokens,
    [Ref]$errors
)
$ast.Extent.Text         # Taken from the variable, $script
$ast.Extent.File         # Just a path
Get-Content script.ps1   # The mis-matched content of the file
}
{ ## Getting at comments
$script = "
   # This is a comment
   Write-Host 'Hello world'
"
}
{ ## With PSParser
$errors = @()
$tokens = [System.Management.Automation.PSParser]::Tokenize(
    $script,
    [Ref]$errors
)
$tokens[1]
}
{ ## With Language.Parser
$errors = @()
$tokens = @()
[System.Management.Automation.Language.Parser]::ParseInput(
    $script,
    [Ref]$tokens,
    [Ref]$errors
)
$tokens[1]
}
{ ## Syntax testing with ParseInput
$script = '
    if ($value -eq $true)) {
        Set-Something
    }
'

$errors = @()
$tokens = @()
$ast = [System.Management.Automation.Language.Parser]::ParseInput(
    $script,
    [Ref]$tokens,
    [Ref]$errors
)
$errors
}
{ ## AST types
[PowerShell].Assembly.GetTypes().Where{
    $_.IsPublic -and 
    $_.IsSubclassOf([System.Management.Automation.Language.Ast])
}
}
{ ## Finding the AST type name
$scriptBlock = {
    'Hello world' | Write-Host
}
$scriptBlock.Ast.EndBlock.Statements.PipelineElements
}
{ ## An AST can be searched
{}.Ast.Find.OverloadDefinitions
}
{ ## An AST can be searched
{}.Ast.FindAll.OverloadDefinitions
}
{ ## Writing a predicate
$predicate = { $args[0] -is [System.Management.Automation.Language.CommandAst] }
{ Write-Host 'Hello world' }.Ast.Find(
    $predicate,
    $true
)
}
{ ## Writing a predicate
$predicate = {
    param (
        $ast
    )
    
    $ast -is [System.Management.Automation.Language.CommandAst]
}

{ Write-Host 'Hello world' }.Ast.Find(
    $predicate,
    $true
)
}
{ ## Using Find
$predicate = {
    param (
        $ast
    )
    
    $ast -is [System.Management.Automation.Language.CommandAst]
}

{
    Write-Host 'Hello world'
    Get-Command Write-Host
}.Ast.Find(
    $predicate,
    $true
)
}
{ ## Using FindAll
$predicate = {
    param (
        $ast
    )
    
    $ast -is [System.Management.Automation.Language.CommandAst]
}

{
    Write-Host 'Hello world'
    Get-Command Write-Host
}.Ast.FindAll(
    $predicate,
    $true
)
}
{ ## Search scope
$predicate = { param ( $ast ) $ast -is [System.Management.Automation.Language.CommandAst] }

{
    Write-Host 'Hello world'
    # This is a nested script block
    {
        Write-Host 'Hello again'
    }
}.Ast.FindAll(
    $predicate,
    $false
)
}
{ ## Nested script block with ForEach-Object
$predicate = { param ( $ast ) $ast -is [System.Management.Automation.Language.CommandAst] }
{
    1..10 | ForEach-Object {
        Write-Host 'Hello world'
    }
}.Ast.FindAll(
    $predicate,
    $false
)
}
{ ## Language keywords
$predicate = { param ( $ast ) $ast -is [System.Management.Automation.Language.CommandAst] }
{
    foreach ($i in 1..10) {
        Write-Host 'Hello world'
    }
}.Ast.FindAll(
    $predicate,
    $false
)
}
{ ## Implementing a search for single character variables
{ $a = 'something' }.Ast.EndBlock.Statements[0].GetType()
}
{ ## Creating the search
$script = {
    $a = Get-Something
    foreach ($x in $a) {
        Set-Something
    }
    for ($i = 0; $i -lt 10; $i += 2) {
        $i
    }
}
$predicate = {
    param ( $ast )

    $ast -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $ast.Left.VariablePath.UserPath.Length -eq 1
}
$script.Ast.FindAll($predicate, $true)
}
{ ## Allowing counters
$script = {
    $a = Get-Something
    foreach ($x in $a) {
        Set-Something
    }
    for ($i = 0; $i -lt 10; $i += 2) {
        $i
    }
}
$predicate = {
    param ( $ast )

    $ast -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $ast.Left.VariablePath.UserPath.Length -eq 1 -and
    -not (
        $ast.Right -is [System.Management.Automation.Language.CommandExpressionAst] -and
        $ast.Right.Expression.StaticType.Name -match '^U?Int'
    )
}
$script.Ast.FindAll($predicate, $true)
}
{ ## Rule description
Set-Content Rules.psm1 -Value '
function MyRule {
    <#
    .DESCRIPTION
        This is the rule description.
    #>

    param (
        [System.Management.Automation.Language.ScriptBlockAst]$someAst
    )
}'

Get-ScriptAnalyzerRule -CustomRulePath Rules.psm1
}
{ ## A simple rule
@'
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
'@ | Set-Content Rules.psm1
}
{ ## Testing the AST based rule
$script = '
Write-Host "Oh, the grand old duke of york;"
Write-Host "He had ten thousand men;"
Write-Host "He marched them up to the top of the hill,"
Write-Host "and he marched them down again."
'

Import-Module PSScriptAnalyzer

Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath .\Rules.psm1
}
{ ## Building token based rules
@'
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
'@ | Set-Content Rules.psm1
}
{ ## Testing the token based rule
$script = @'
Get-Process | Select-Object `
    Name, `
    ProcessId
'@

Import-Module PSScriptAnalyzer

Invoke-ScriptAnalyzer -ScriptDefinition $script -CustomRulePath .\Rules.psm1
}

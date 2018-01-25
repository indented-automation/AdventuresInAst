param (
    [String]$Path = 'slides.ps1',

    [Int]$CharSleep = 10
)

function Get-DemoCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$Path
    )

    $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)

    $tokens = $errors = @()

    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [Ref]$tokens,
        [Ref]$errors
    )

    foreach ($statement in $ast.EndBlock.Statements) {
        if ($statement.PipelineElements -and $statement.PipelineElements[0].Expression -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
            $statement.PipelineElements[0].Expression.ScriptBlock.GetScriptBlock()
        } else {
            $statement.Extent.Text
        }
    }

    if ($errors.Count -gt 0) {
        $errors | Write-Error
        
        throw 'Demo script has errors!'
    }
}

function Type-DemoCommand {
    param (
        [Parameter(ValueFromPipeline)]
        [Object]$Command,

        [Int]$Sleep
    )

    begin {
        $width = $host.UI.RawUI.WindowSize.Width - 3
    }

    process {
        $commandString = $Command.ToString().Trim()
        if ($commandString.StartsWith('##')) {
            $header = $commandString.Split("`r`n")[0].TrimStart('# ')
            $commandString = $commandString.Substring($commandString.IndexOf("`n") + 1)
        }

        if ($header) {
            $border = ('+' + ('=' * $width) + '+'),
                      ('|' + (' ' * $width) + '|')
            $border | Write-Host -ForegroundColor Green

            $padLeft = [Math]::Ceiling(($width - $header.Length) / 2)
            $padRight = [Math]::Floor(($width - $header.Length) / 2)

            Write-Host ('|' + (' ' * $padLeft)) -ForegroundColor Green -NoNewline
            Write-Host $header -NoNewline
            Write-Host ((' ' * $padRight) + '|') -ForegroundColor Green

            [Array]::Reverse($border)
            $border | Write-Host -ForegroundColor Green
            Write-Host
            Write-Host
        }

        Write-Host 'PS> ' -NoNewLine

        foreach ($char in $commandString.ToCharArray()) {
            if ($char -eq "`r") {
                # Discard always
            } elseif ($char -eq "`n") {
                Write-Host
                Write-Host '>> ' -NoNewline
            } else {
                Write-Host $char -NoNewLine
                Start-Sleep -Milliseconds $Sleep
            }
        }

        Write-Host
        Write-Host

        $Command
    }
}

filter Invoke-DemoCommand {
    param (
        [Parameter(ValueFromPipeline)]
        [Object]$Command
    )

    if ($Command -is [String]) {
        Invoke-Expression $Command | Out-String | Write-Host
    } elseif ($Command -is [ScriptBlock]) {
        & $Command | Out-String | Write-Host
    }

    Write-Host
}

Clear-Host

$commands = Get-DemoCommand $Path
for ($i = 0; $i -lt $commands.Count; $i++) {
    # Input handler goes here
    $commands[$i] | Type-DemoCommand -Sleep $CharSleep | Invoke-DemoCommand

    pause
    Clear-Host
}

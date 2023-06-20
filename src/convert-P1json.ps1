<#
.SYNOPSIS
    Parses serial input data from a smart power meter using the HAN / H1 / P1 port
.DESCRIPTION
    Built to be used as a flow in node red.
.NOTES
    2023-06-20 Klas.Pihl@gmail.com

.EXAMPLE
    convertto-P1json.ps1 -data 'b"/ELL5\x5c253833635_A\r\n\r\n"
    b"0-0:1.0.0(210217184019W)\r\n"
    b"1-0:1.8.0(00006678.394*kWh)\r\n"
    b"1-0:2.8.0(00000000.000*kWh)\r\n"
    b"1-0:3.8.0(00000021.988*kvarh)\r\n"
    b"1-0:4.8.0(00001020.971*kvarh)\r\n"
    b"1-0:1.7.0(0001.727*kW)\r\n"
    b"1-0:2.7.0(0000.000*kW)\r\n"
    b"1-0:3.7.0(0000.000*kvar)\r\n"
    b"1-0:4.7.0(0000.309*kvar)\r\n"
    b"1-0:21.7.0(0001.023*kW)\r\n"
    b"1-0:41.7.0(0000.350*kW)\r\n"
    b"1-0:61.7.0(0000.353*kW)\r\n"
    b"1-0:22.7.0(0000.000*kW)\r\n"
    b"1-0:42.7.0(0000.000*kW)\r\n"
    b"1-0:62.7.0(0000.000*kW)\r\n"
    b"1-0:23.7.0(0000.000*kvar)\r\n"
    b"1-0:43.7.0(0000.000*kvar)\r\n"
    b"1-0:63.7.0(0000.000*kvar)\r\n"
    b"1-0:24.7.0(0000.009*kvar)\r\n"
    b"1-0:44.7.0(0000.161*kvar)\r\n"
    b"1-0:64.7.0(0000.138*kvar)\r\n"
    b"1-0:32.7.0(240.3*V)\r\n"
    b"1-0:52.7.0(240.1*V)\r\n"
    b"1-0:72.7.0(241.3*V)\r\n"
    b"1-0:31.7.0(004.2*A)\r\n"
    b"1-0:51.7.0(001.6*A)\r\n"
    b"1-0:71.7.0(001.7*A)\r\n!""
    '
#>


param (
    $data
)
 $data = $data.Split([Environment]::NewLine)
 $Map =
    "metric,register,value,suffix
        Measure,1-0:1.8.0
        Effekt,1-0:1.7.0
        L1,1-0:21.7.0
        L2,1-0:41.7.0
        L3,1-0:61.7.0
        L1A,1-0:31.7.0
        L2A,1-0:51.7.0
        L3A,1-0:71.7.0
    " | ConvertFrom-Csv



    foreach ($Register in $Map) {
        $Match = $data | Where-Object {$PSitem -match $Register.register} | Select-Object -Last 1
        if($Match) {
            $Value,$Suffix = $Match.Replace($Register.register,'').Split('*').trim('(',')')
            $Register.value = $Value
            $Register.suffix = $Suffix.Split(')') | Select-Object -First 1
        }

    }
    $Ouput = 
    [PSCustomObject]@{
        p1 = foreach ($Register in $Map) {
            [PSCustomObject]@{
                $Register.metric = [PSCustomObject]@{
                    reading = $Register.value
                    unit = $Register.suffix
                }
            }

        }
    }
        

    Write-Output ($Ouput | ConvertTo-Json -Depth 3)
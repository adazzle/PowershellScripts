## Convert Fahrenheit to Celcius
function Convert-FToC([double] $fahrenheit)
{
    $celcius = $fahrenheit - 32
    $celcius = $celcius / 1.8
    $celcius
}

## Convert Celcius to Fahrenheit
function Convert-CToF([double] $celcius)
{
    $fahrenheit = $celcius * 1.8
    $fahrenheit = $fahrenheit + 32
    $fahrenheit
}

Export-ModuleMember -Function Convert-FToC,Convert-CToF

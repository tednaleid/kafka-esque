import strformat, strutils, system/widestrs

#[
The JVM String.hashCode [algorithm](https://docs.oracle.com/javase/6/docs/api/java/lang/String.html#hashCode())
    
Returns a hash code for this string. The hash code for a String object is computed as

    s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]

using int arithmetic, where s[i] is the ith character of the string, 
n is the length of the string, and ^ indicates exponentiation. 
(The hash value of the empty string is zero.) 

JVM strings are UTF-16, not UTF-8 string that nim uses
]#
proc jvmStringHash*(str: string): int32 =
    let widestring = newWideCString(str) # UTF-8 -> UTF-16
    var
        hashTotal: int32 = 0
        charAt = widestring.len - 1
        baseToPower = 1

    while charAt >= 0:
        let thisChar: int32 = (ord(widestring[charAt])).int32
        charAt.dec
        # +%, -%, *%, and casting to an int32 will all truncate safely without overflow
        hashTotal = hashTotal +% cast[int32](thisChar *% baseToPower)
        baseToPower = baseToPower shl 5 -%
                baseToPower # same as * 31 -> shl 5 is * 32, then take one value away

    return hashTotal

when isMainModule:
    proc checkHash(str: string, expected: int) =
        echo fmt"{jvmStringHash(str)} == {$expected} <- {str}"

    checkHash("", 0)
    checkHash("A", 65)
    checkHash("AA", 2080)
    checkHash("AAA", 64545)
    checkHash("AAAA", 2000960)
    checkHash("AAAAA", 62029825)
    checkHash("AAAAAA", 1922924640)
    checkHash("AAAAAAA", -518878239)
    checkHash("ABC", 64578)
    checkHash("supercalifragilisticexpialidocious", 1077910243)
    checkHash("ñ", 241)
    checkHash("ô", 244)
    checkHash("æ", 230)
    checkHash("“", 8220)
    checkHash("“Iñtërnâtiônàlizætiøn”", 220967235)
    checkHash("Ἀριστοτέλης", -444401857)

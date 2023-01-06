module Maths exposing (sign)


sign : Int -> Int
sign x =
    if x < 0 then
        -1

    else if x == 0 then
        0

    else
        1
module ParserHelpers exposing
    ( basicString
    , betterInt
    , maybe
    , notSpace
    , oneOrMore
    , orElse
    , runOnList
    , string
    , zeroOrMore
    )

import Debug exposing (..)
import Parser exposing (..)


type alias ParserResult a =
    Result (List DeadEnd) a


runOnList : Parser a -> List String -> List a
runOnList parser list =
    list
        |> List.map (Parser.run parser)
        |> withoutErrors


withoutErrors : List (Result (List DeadEnd) a) -> List a
withoutErrors parserResults =
    withoutErrorsHelp [] parserResults


withoutErrorsHelp : List a -> List (Result (List DeadEnd) a) -> List a
withoutErrorsHelp items parserResults =
    case parserResults of
        [] ->
            items

        result :: remainingParserResults ->
            case result of
                Ok item ->
                    withoutErrorsHelp
                        (items ++ [ item ])
                        remainingParserResults

                Err err ->
                    let
                        _ =
                            err |> log "!!! ERROR !!!"
                    in
                    withoutErrorsHelp items remainingParserResults


{-| parse zeroOrMore characters
companyIdParser : Parser Field
companyIdParser =
succeed CompanyId
|. symbol "<cid:">
|= oneOrMore "cid" notSpace
-}
zeroOrMore : (Char -> Bool) -> Parser String
zeroOrMore isOk =
    succeed ()
        |. chompWhile isOk
        |> getChompedString


{-| parse oneOrMore characters
eyeColorParser : Parser Field
eyeColorParser =
succeed toEyeColor
|. symbol "ecl:"
|= maybe (oneOrMore "eye color alpha" Char.isAlpha)
|. zeroOrMore notSpace
-}
oneOrMore : String -> (Char -> Bool) -> Parser String
oneOrMore label isOk =
    succeed ()
        |. oneOf
            [ chompIf isOk
            , problem ("I was expected at least one " ++ label)
            ]
        |. chompWhile isOk
        |> getChompedString


{-| Maybe parse something.

This is great for Maybe values you're filling.

    eyeColorParser : Parser Field
    eyeColorParser =
        succeed toEyeColor
            |. symbol "ecl:"
            |= maybe (oneOrMore "eye color alpha" Char.isAlpha)
            |. zeroOrMore notSpace

-}
maybe : Parser String -> Parser (Maybe String)
maybe parser =
    oneOf
        [ succeed Just
            |= parser
        , succeed Nothing
            |. zeroOrMore notSpace
        ]


notSpace : Char -> Bool
notSpace c =
    c /= ' '


string : Parser String
string =
    zeroOrMore (\c -> notSpace c && c /= '\n')


basicString : Parser String
basicString =
    zeroOrMore (\c -> Char.isAlphaNum c)


betterInt : Parser Int
betterInt =
    oneOf
        [ succeed negate
            |. symbol "-"
            |= int
        , int
        ]


orElse : Maybe a -> Maybe a -> Maybe a
orElse x y =
    case y of
        Nothing ->
            x

        jst ->
            jst

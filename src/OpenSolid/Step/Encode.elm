module OpenSolid.Step.Encode
    exposing
        ( file
        , entity
        , referenceTo
        , default
        , null
        , int
        , float
        , string
        , enum
        , binary
        , list
        , intAs
        , floatAs
        , stringAs
        , enumAs
        , binaryAs
        , listAs
        )

{-| Functions for encoding data in STEP format.


# Files

@docs file


# Entities

@docs entity


# Attributes

@docs referenceTo, default, null, int, float, string, enum, binary, list


## Typed attributes

Typed attributes are sometimes needed when dealing with SELECT types.

@docs intAs, floatAs, stringAs, enumAs, binaryAs, listAs

-}

import OpenSolid.Step as Step
import OpenSolid.Step.Types as Types
import OpenSolid.Step.EntityMap as EntityMap exposing (EntityMap)
import OpenSolid.Step.Format as Format


{-| Create a STEP-encoded string that can be written out to a file.
-}
file : Step.Header -> List Step.Entity -> String
file header entities =
    String.join "\n"
        [ "ISO-10303-21;"
        , "HEADER;"
        , headerString header
        , "ENDSEC;"
        , "DATA;"
        , entitiesString entities
        , "ENDSEC;"
        , "END-ISO-10303-21;\n"
        ]


headerString : Step.Header -> String
headerString header =
    let
        fileDescriptionEntity =
            entity "FILE_DESCRIPTION"
                [ list (List.map string header.fileDescription)
                , string "2;1"
                ]

        fileNameEntity =
            entity "FILE_NAME"
                [ string header.fileName
                , string (Format.date header.timeStamp)
                , list (List.map string header.author)
                , list (List.map string header.organization)
                , string header.preprocessorVersion
                , string header.originatingSystem
                , string header.authorization
                ]

        fileSchemaEntity =
            entity "FILE_SCHEMA"
                [ list (List.map string header.schemaIdentifiers)
                ]

        entityMap =
            EntityMap.empty
                |> addEntity fileDescriptionEntity
                |> Tuple.second
                |> addEntity fileNameEntity
                |> Tuple.second
                |> addEntity fileSchemaEntity
                |> Tuple.second
    in
        EntityMap.toList entityMap
            |> List.map Tuple.second
            |> String.join "\n"


entitiesString : List Step.Entity -> String
entitiesString entities =
    let
        entityMap =
            List.foldl
                (\entity accumulatedMap ->
                    addEntity entity accumulatedMap |> Tuple.second
                )
                EntityMap.empty
                entities
    in
        EntityMap.toList entityMap
            |> List.map (\( id, string ) -> Format.id id ++ "=" ++ string)
            |> String.join "\n"


addEntity : Step.Entity -> EntityMap -> ( Int, EntityMap )
addEntity (Types.Entity typeName attributes) entityMap =
    let
        ( attributeValues, mapWithAttributes ) =
            addAttributes attributes entityMap

        entityString =
            Format.entity typeName attributeValues
    in
        EntityMap.add entityString mapWithAttributes


addAttributes : List Step.Attribute -> EntityMap -> ( List Types.AttributeValue, EntityMap )
addAttributes attributes entityMap =
    List.foldl
        (\attribute ( accumulatedAttributeValues, accumulatedMap ) ->
            let
                ( attributeValue, mapWithAttribute ) =
                    addAttribute attribute accumulatedMap
            in
                ( attributeValue :: accumulatedAttributeValues
                , mapWithAttribute
                )
        )
        ( [], entityMap )
        attributes
        |> Tuple.mapFirst List.reverse


addAttribute : Step.Attribute -> EntityMap -> ( Types.AttributeValue, EntityMap )
addAttribute attribute entityMap =
    case attribute of
        Types.DefaultAttribute ->
            ( Format.defaultAttribute, entityMap )

        Types.NullAttribute ->
            ( Format.nullAttribute, entityMap )

        Types.IntAttribute int ->
            ( Format.intAttribute int, entityMap )

        Types.FloatAttribute float ->
            ( Format.floatAttribute float, entityMap )

        Types.StringAttribute string ->
            ( Format.stringAttribute string, entityMap )

        Types.BinaryAttribute string ->
            ( Format.binaryAttribute string, entityMap )

        Types.EnumAttribute enumName ->
            ( Format.enumAttribute enumName, entityMap )

        Types.ReferenceTo entity ->
            let
                ( entityId, updatedMap ) =
                    addEntity entity entityMap
            in
                ( Format.referenceTo entityId, updatedMap )

        Types.TypedAttribute typeName attribute ->
            let
                ( attributeValue, updatedMap ) =
                    addAttribute attribute entityMap
            in
                ( Format.typedAttribute typeName attributeValue, updatedMap )

        Types.AttributeList attributes ->
            let
                ( attributeValues, mapWithAttributes ) =
                    addAttributes attributes entityMap
            in
                ( Format.listAttribute attributeValues, mapWithAttributes )


{-| Construct a single STEP entity from a type name and list of attributes.
-}
entity : String -> List Step.Attribute -> Step.Entity
entity typeName attributes =
    Types.Entity (Format.typeName typeName) attributes


{-| Construct a reference to another STEP entity.
-}
referenceTo : Step.Entity -> Step.Attribute
referenceTo entity =
    Types.ReferenceTo entity


{-| The special 'default value' attribute.
-}
default : Step.Attribute
default =
    Types.DefaultAttribute


{-| The special 'null value' attribute.
-}
null : Step.Attribute
null =
    Types.NullAttribute


{-| Construct an integer-valued attribute.
-}
int : Int -> Step.Attribute
int value =
    Types.IntAttribute value


{-| Construct a real-valued attribute.
-}
float : Float -> Step.Attribute
float value =
    Types.FloatAttribute value


{-| Construct a string-valued attribute.
-}
string : String -> Step.Attribute
string value =
    Types.StringAttribute value


{-| Construct an attribute that refers to an enumeration value defined in an
EXPRESS schema. Enumeration values are always encoded as all-caps with leading
and trailing periods, like `.STEEL.`; this function will capitalize and add
periods if necessary.
-}
enum : String -> Step.Attribute
enum value =
    Types.EnumAttribute (Format.enumName value)


{-| Construct a binary-valued attribute. The provided string is assumed to
already be hex encoded as required by the STEP standard (i.e., every four bits
are represented by one hexadecimal character).
-}
binary : String -> Step.Attribute
binary value =
    Types.BinaryAttribute value


{-| Construct an attribute which is itself a list of other attributes.
-}
list : List Step.Attribute -> Step.Attribute
list attributes =
    Types.AttributeList attributes


{-| Construct a type-tagged integer-valued attribute.
-}
intAs : String -> Int -> Step.Attribute
intAs typeName value =
    typedAttribute typeName (int value)


{-| Construct a type-tagged float-valued attribute.
-}
floatAs : String -> Float -> Step.Attribute
floatAs typeName value =
    typedAttribute typeName (float value)


{-| Construct a type-tagged string-valued attribute.
-}
stringAs : String -> String -> Step.Attribute
stringAs typeName value =
    typedAttribute typeName (string value)


{-| Construct a type-tagged enumeration attribute.
-}
enumAs : String -> String -> Step.Attribute
enumAs typeName value =
    typedAttribute typeName (enum value)


{-| Construct a type-tagged binary-valued attribute.
-}
binaryAs : String -> String -> Step.Attribute
binaryAs typeName value =
    typedAttribute typeName (binary value)


{-| Construct a type-tagged list attribute.
-}
listAs : String -> List Step.Attribute -> Step.Attribute
listAs typeName attributes =
    typedAttribute typeName (list attributes)


typedAttribute : String -> Step.Attribute -> Step.Attribute
typedAttribute typeName attribute =
    Types.TypedAttribute (Format.typeName typeName) attribute

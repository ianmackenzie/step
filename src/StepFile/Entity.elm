module StepFile.Entity
    exposing
        ( Entity
        , attributes
        , hasType
        , ofType
        , typeName
        )

{-| Accessors for `Entity` values. Usually you will not need this module,
instead using the `Decode` module to decode entities directly, but it may come
in handy in weird cases.

@docs Entity, ofType, typeName, hasType, attributes

-}

import StepFile.Attribute as Attribute exposing (Attribute)
import StepFile.Format as Format
import StepFile.Types as Types


{-| Represents a single entity storied in the data section of a STEP file, such
as a point, curve, assembly or entire building.
-}
type alias Entity =
    Types.Entity


{-| Construct a single STEP entity from a type and list of attributes. The type
name will be capitalized if necessary.
-}
ofType : String -> List Attribute -> Entity
ofType givenTypeName givenAttributes =
    Types.Entity (Format.typeName givenTypeName) givenAttributes


{-| Get the type of an entity. This will always be all caps, for example
`"IFCWALL"` or `"PRODUCT_CONTEXT"`.
-}
typeName : Entity -> String
typeName (Types.Entity (Types.TypeName string) _) =
    string


{-| Check if an entity has the given type. It is preferred to use

    Entity.hasType someType someEntity

over

    Entity.typeName someEntity == someType

since in the first case the comparison is done in a case-insensitive way while
in the second case will only work if you ensure that the `someType` string is in
all caps.

-}
hasType : String -> Entity -> Bool
hasType givenTypeName =
    let
        (Types.TypeName formattedTypeName) =
            Format.typeName givenTypeName
    in
    \entity -> typeName entity == formattedTypeName


{-| Get the attributes of an entity.
-}
attributes : Entity -> List Attribute
attributes (Types.Entity _ attributes_) =
    attributes_

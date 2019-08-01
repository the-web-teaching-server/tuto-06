port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode


port userlistPort : (Value -> msg) -> Sub msg


type alias Model =
    { posts : List Post, users : List User, post : String }


type alias Post =
    { authorName : String
    , content : String
    , date : String
    }


type alias User =
    { name : String
    , status : UserStatus
    , rowid : Int
    }


type UserStatus
    = Disconnected
    | Available


type Msg
    = GotUserlist (List User)
    | GotPosts (List Post)
    | DecodeError Decode.Error
    | PostUpdated String
    | PostSubmitted
    | NoOp

userDecoder : Decoder User
userDecoder =
    Decode.map3 User
        (Decode.field "name" Decode.string)
        (Decode.field "status" userStatusDecoder)
        (Decode.field "rowid" Decode.int)


userStatusDecoder : Decoder UserStatus
userStatusDecoder =
    Decode.string
        |> Decode.andThen
            (\status ->
                case status of
                    "DISCONNECTED" ->
                        Decode.succeed Disconnected

                    "AVAILABLE" ->
                        Decode.succeed Available

                    _ ->
                        Decode.fail ("unknown status " ++ status)
            )


postDecoder : Decoder Post
postDecoder =
    Decode.map3 Post
        (Decode.field "author_name" Decode.string)
        (Decode.field "content" Decode.string)
        (Decode.field "date" Decode.string)


decodeExternalUserlist : Value -> Msg
decodeExternalUserlist val =
    case Decode.decodeValue (Decode.list userDecoder) val of
        Ok userlist ->
            GotUserlist userlist

        Err err ->
            DecodeError err


initialModel : Model
initialModel =
    { posts = []
    , users = []
    , post = ""
    }





update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUserlist users ->
            ( { model | users = users }, Cmd.none )

        GotPosts posts ->
            ( { model | posts = posts }, Cmd.none )

        PostUpdated post ->
            ( { model | post = post }, Cmd.none )

        PostSubmitted ->
            if model.post == "" then
                ( model, Cmd.none )

            else
                ( { model | post = "" }
                , Http.post
                    { url = "/posts/"
                    , expect = Http.expectWhatever (\_ -> NoOp)
                    , body = Http.jsonBody <| Encode.object [ ( "content", Encode.string model.post ) ]
                    }
                )

        DecodeError err ->
            let
                _ =
                    Debug.log "Decode error" err
            in
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    main_ [ id "main-content" ]
        [ section [ id "user-list" ]
            [ header []
                [ text "List of users  " ]
            , ul []
                (List.map viewUser model.users)
            ]
        , section [ id "posts" ]
            [ Html.form [ action "/posts/", id "post-form", method "POST", onSubmit PostSubmitted ]
                [ input
                    [ name "content"
                    , placeholder "Say something nice!"
                    , value model.post
                    , type_ "text"
                    , onInput PostUpdated
                    ]
                    []
                , input [ type_ "submit", value "Share!" ] []
                ]
            , ul [ id "post-list" ]
                (List.map viewPost model.posts)
            ]
        ]


viewPost : Post -> Html Msg
viewPost post =
    li [ class "post" ]
        [ div [ class "post-header" ]
            [ span [ class "post-author" ]
                [ text post.authorName ]
            , span [ class "post-date" ] [ text <| "at " ++ post.date ]
            ]
        , div [ class "post-content" ] [ text post.content ]
        ]


viewUser : User -> Html Msg
viewUser user =
    li []
        [ text <|
            (case user.status of
                Available ->
                    "🔴 "

                Disconnected ->
                    "⚪ "
            )
                ++ user.name
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ userlistPort decodeExternalUserlist ]


main : Program () Model Msg
main =
    Browser.element
        { init = \() -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

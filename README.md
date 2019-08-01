# Tuto 6: websockets and Elm ports

This glitch is almost the same than the previous one. I've only added
(dis)connection handling with websocket and used a Elm interface in order to 
display the userlist.

# Explore the code

## Server code

Look at `server.py`. 
1. We use a global `CONNECTED_USERS` dictionary: the keys are the "rowid" of the users, 
  the value are instances of the `UserConnected` class (look `models/users.py`).
  The "rowid" is a SQLite notion: each row in a SQLite table has a unique "rowid", we
  will using this rowid to identify users instead of the email (we don't want to disclose the
  email of our users).
  
  We will use `CONNECTER_USERS` to check if a user is connected or not.
1. What fields do `UserConnected` objects contain?
1. In the `server.py` file, `@io.on('connect')` indicates that the following function will handle
  the websocket connections, in the same way `@app.route('/index/')` handles HTTP request,
  except that WS messages do not need response.
  
  This handler performs two main actions. What are they?
  
  *Note*: the `current_user` is read from the cookies, but WS connection do not have
  such a notion. Thus, the "cookies" you are reading from are the one sended when the
  ws connection has been requested.

1. How is handled the deconnection?
1. Note that:
    * `io` is defined at the begining of the file
    * the launching command is now `io.run(app)` instead of
      `app.run()`
    * the HTTP `posts` handler only store the post in the DB
      and anything else.
 

## Client code (`front/Main.elm`)

The best way to quickly understand an Elm code is to look the `Model` and `Msg` types.

1. Look at the `update` function and describe the effect of each message.
1. What is the role of the `post` and `posts` fields in `Model`?
1. Where and when are fired the  `PostUpdated`, `PostSubmitted` messages?
1. At the top of the file, there is a `port userlistPort : (Value -> msg) -> Sub msg` declaration. It enables
   JavaScript code to send messages to the Elm application. As indicated in the type, we have to provide
   a `Value -> msg` function. In our application we use the `decodeExternalUserlist`. What technique
   is used in this function?
1. Where and when is fired the `GetUserlist` message?
1. Is `GotPosts` message actually fired?
1. Look at the `templates/index.html` file. 
  * Where is instantiate the websocket connection?
  * How do we transfer the message from the websocket to the Elm application?

# Load the posts

In this part, we will display the posts on the screen of all connected users.


1. [`server.py`] Create a `broadcast_post_list` function, similar to the `broadcast_userlist` one in
   order to broadcast the posts list to all the users. 
   
   Each post should contain the `content`, `date` and `author_name` fields. For the date, you
   can you use: `post.date.strftime("%m/%d/%Y, %H:%M:%S")`.
1. [`server.py`] Add a call to this function add the end of the HTTP `posts` handler, before it returns.
1. [`front/Main.elm`] Add a `postlist` port and a `decodeExternalPostlist` and set all up in order to handle
   messages from Javascript.
1. [`templates/index.html`] Add a subscription to the `postlist` (or whatever you have called this in
   `server.broadcast_post_list`) websocket channel and transfer all the messages to the Elm application.
1. Test it! When you submit a post, you should see it on the wall. Test with in a private window (`Ctrl+Shift+P` on
   Firefox, `Ctrl+Shift+N` on Chrome) with another user: you should see the post withou refreshing the page!
1. [`server.py`] Currently, the user does not see the posts whe he log in, until somone write a post.
   Write a `send_post_list(cur, user)` function that send a websocket message to only one user and call
   this function at the end of the `connect` WS handler.
   
   *Hints:*
   * so far, we have used `io.emit(<channel-name>, <payload>, broadcast=True)` to broadcast a 
     payload to all users. You can use: `io.emit(<channel-name>, <payload>, room=<socketid>)`
     where `<socketid>` is given in `request.sid`. Note we are storing in the `ConnectedUser` 
     objects.
   * you can either do a nasty "copy-paste" of `broadcast_post_list` to write `send_post_list`
     (it is only once, so it would be fine), or create a `get_posts(cur)` function returning
     the list of all the posts and then use this function in `broadcast_post_list` 
     and `send_post_list`.
  
# Challenge!

We will give the opportunity for user challenge other users. The game for the challenge is
the famous "Papper, Scissor, Rock" (if you are boring, you can use [the variant from 
"Big Bang Theory"](https://www.youtube.com/watch?v=x5Q6-wMx-K8) ).

1. [`front/Main.elm`] In the `viewUser` function, add a "Challenge" button after the name of
   the user. This button should be `disabled` if the user's status is not `Available` (you can
   use the `disabled : Bool -> Attribute msg` function from the `Html.Attributes` module).
   
   Give the class `challenge-button` to this button to style it nicely (look at the 
   `static/wall.css`, there are styles defined)
1. [`front/Main.elm`] 
   * Add an outgoing port: `port invite : Int -> Cmd msg`. 
   * Add also a variant of the `Msg` type: `Invited Int`. The `Int` paramater of this variant will be the
    "rowid" of the user.
   * Fire the the previous message when the "Challenge" button is clicked.
   * In th update function, handle this new message kind with:
     ```elm
     Invited rowid ->
         (model, invite rowid)
     ```
     This way, we are sending a message to the Javascript code.
1. [`templates/index.html`] Add the following subscription in the
   Javascript code:
   ```javascript
    app.ports.invite.subscribe(function(rowid){
        socket.emit('invite', rowid);
    });
    ```
1. [`server.py`] Create a `invite` WS handler:
   ```python
   @io.on('invite')
   def invite(rowid):
   ```
   * Check if the rowid in paramater is different from the rowid from 
     the current user (you can get
     the current user rowid with `flask_login.current_user.rowid`).
     If so, return immediately, doing nothing.
     
   * Retrieve the two `UserConneted` objects involved in this invitation
     from `CONNECTED_USERS`:
     the one in parameter (via his rowid), and the current user.
     
     If one of the status user is not `"AVAILABLE"`, return immediately.
     
     Otherwise, set their `status` field to `"PLAYING"`.
   * Broadcast the userlist.
1. [`front/Main.elm`] Add a `Playing` variant to the `UserStatus` type.
   Adapt the related decoder and the `viewUser` function. You can
   use the following Emoji for the `Playing` status: 🎲 (copy-paste it,
   it is normal text!)
1. Test it! You will need to login with two different accounts (use
   a private window or ask to a friend).


# Lauch the game and quit!

1. [`models/game.py`] We will manage the state of the game with the class
   `Game`.
    * Describe the role of each method.
    * How is handled the game logic? What would you need to change to
      play with the Big Bang Theory variation:
      ![bbt paper scissor rock](https://cdn.glitch.com/7757692a-eb4d-409c-8cb3-e17be611b4ca%2Fimage.png?v=1564604842925)
      Compare to what you would need if you were using a naive "if"-based approached 
      [like the one proposed here](https://thehelloworldprogram.com/python/python-game-rock-paper-scissors/).
      
      Optional part: make this change!
1. [`server.py`] In the `invite` WS handler, create a game instance. Do we need to handle the
   status directly in this handler?
   
   When the game is created, send a message to the two players via the channel `new-game`.
   The payload should include the opponent's name.
1. [`front/Main.elm`] 
   * Create  `port newGame: (String -> msg) -> Sub msg`, an incoming port.
   * Create also a `GameStarted String` variant in `Msg` (the string parameter will be the
     name of the opponent).
   * Create a type:
     ```elm
     type GameStatus
         = NotPlaying
         | PlayingAgainst String
     ```
     and a `gameStatus : GameStatus` field to the `Model` record.
   * Bundle all this stuff to make the compiler happy!
1. [`front/Main.elm`] If the `gameStatus` is not `NotPlaying`,
   add a `section` tag in the view, after the userlist and the posts.
   Write someting like "You are playing against Arthur".
   
   Give it the `id` "game", the `style/wall.css` will style it for you!
   Note that `style/wall.css` is using the grid layout.
1. [`templates/index.html`] Connect the `new-game` websocket channel with the
   `newGame` Elm port.
1. Test it! Challenge a friend (or yourself in a private window), you both should see a pink rectangle at the bottom right of your screen.
1. [`front/Main.elm`] Add a "leave the game" button in the game view, a corresponding
   variant of `Msg` and outgoing port. Make the connection in `templates/index.html`.
1. [`server.py`] Add a `leave-game` WS handler. It should:
   * call the `quit` method of the involved game,
   * send an empty payload via the `game-ended` channel to the two players,
   * broadcast the userlist (since now, those users are available).
1. [`front/Main.elm`] Handle this new channel in the Elm code by:
   * creating an incoming port,
   * creating an appropriate message.
1. Test it! Challenge a friend, close the game, the game sould be closed in the two browsers!

# Play!

Complete the game, here are the big steps:
* [`front/Main.elm`] the players choose their move,
* [`server.py`] when the server receive a move, it checks if the game is over.
  If so, it sends the result to the players. If it is a tie, it resets the
  game. If not, it quits the game after sending the result.
* [`front/Main.elm`] when the Elm application receive the
  game result, it handles it properly (take into account the
  tie case, you should propose to replay!). Here is a possible
  type for the game status

```elm
type GameStatus
    = NoGame
    | GameStarted { opponent : String }
    | GameWaitingOpponentMove{ opponent : String, move : Move }
    | GameTie { opponent : String }
    | GameEnded { opponent : String, win : Bool }
```

# Optional parts

* Use a more elaborate challenging system, based upon four states: `AVAILABLE`, 
  `INVITATION SENT`, `INVITATION RECEIVED` and `PLAYING`. Allow a user to
  decline an invitation.
* Handle unexpected disconnections (forfeit the game if the user is playing).
* Allow playing many games simultaneously.
* Currently, the Elm application is not aware of the current user. Use the 
  [flags](https://guide.elm-lang.org/interop/flags.html) in order to have at least
  the user rowid. This way, you will be able to not display the "challenge button"
  for the current user.
  
  **Warning**: be careful about XSS injection, don't write Javascript code thanks to
  the template engine.
  You could do something like:
  ```html
  <main id="main-content" data-userrowid="{{ user.rowid }}"></main>

  <script type="text/javascript" charset="utf-8">
  var mainNode = document.querySelector('#main-content');
  var app = Elm.Main.init({
    node: mainNode,
    flags: { 
      'userRowid': parseInt(node.dataset.userrowid)
    }
  });
  </script>

* We already mentioned that using global variables is fragile. In a real-world scenario,
  where server is distributed on many cores, global memory is not even an option.
  
  Instead of using global variable, you can use a database, for example an SQL one.
  However this is not the most efficient and practical solution.
  
  An in-memory NoSQL system, such as Redis, is more apt to the task.
  Replace global variables with a Redis database. You will have to go through the Redis manuals and the docs of the 
  [flask-redis](https://pypi.org/project/flask-redis/) module.

  Redis is not available on Glitch. You can either develop localy or use
  an external redis hosting like [Redis lab](https://redislabs.com/).

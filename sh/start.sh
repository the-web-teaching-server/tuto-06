elm_build="elm make front/Register.elm front/Main.elm --output static/elm.js --debug"
launch_python="python3 server.py"


$elm_build && PYTHONUNBUFFERED=true $launch_python
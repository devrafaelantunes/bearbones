## BearBones

A 2D multiplayer game where you control a hero. With your hero, you can move freely through the map and attack other players. If you die, you'll respawn in 5 seconds.

*Try it out in: http://barebones.rafaelantun.es*

- Created by: Rafael Antunes.

## How to run the application

- clone the repository

*Backend*
- `mix deps.get`
- `iex -S mix`
- The API will listen to port `4040` and will serve `/game` endpoint.

*Frontend*
- Access the `frontend/index.html` file

## How to run unit tests

- use `mix test`

## How to play the game

- Choose your hero's name
- Move using the buttons on the upper left corner
- Attack players when they are 1 block away from your hero
- Have fun :) 

## Future Improvements

- Add a ping system to check if the player's browser is open and the player is active. If the ping is not successfully the player is removed.

- Add a system to prevent multiple players from controlling the same hero, by entering with the same name.

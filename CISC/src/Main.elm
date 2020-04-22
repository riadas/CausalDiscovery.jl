module Main exposing (..)

import Render exposing (..)
import Engine exposing (..)
import Color
import Update exposing (..)


-- Car Example

car = Box (1, 1) 3 4 Color.yellow
tank = Box (2, 2) 1 2 Color.red
scene : Scene
scene = [ObjectTag tank, ObjectTag car]
gasPumpPos = (1, 1)
-- gasPumpPressed computer = computer == gasPumpPos
gasPumpPressed computer = computer.mouse.click
maxGas = 3

moveObject object x y =
  case object of
    Box (x_, y_) width height color -> Box (x + x_, y + y_) width height color
    Circle -> Circle

move entity x y = 
  case entity of
    ObjectTag object -> ObjectTag (moveObject object x y)
    FieldTag field -> FieldTag field
    ParticlesTag particles -> ParticlesTag particles

type alias Model = {objects : List Entity, latent : Int}
update : Computer -> Model -> Model
update computer {objects, latent} = 
  let
    tankLevel = latent
    newTank = if gasPumpPressed computer then maxGas else tankLevel - 1
    moveObjects = if tankLevel > 0 then List.map (\o -> move o 1 1) objects else objects
  in
  { 
    objects = moveObjects,
    latent = newTank
  }
  
main = pomdp {objects = scene, latent = maxGas} update


-- Haven't figured out messages
-- I want to visuals to change as a function of the tank
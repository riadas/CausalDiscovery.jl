include("singletimestepsolution.jl");

function synthesize_program(model_name::String; 
                            singlecell = false
                            )
  observations, user_events, grid_size = generate_observations(model_name)
  matrix, unformatted_matrix, object_decomposition, prev_used_rules = singletimestepsolution_matrix(observations, user_events, grid_size, singlecell=singlecell)
  solutions = generate_on_clauses(matrix, unformatted_matrix, object_decomposition, user_events, grid_size)
  program_strings = []
  for solution in solutions 
    if solution[1] != [] 
      on_clauses, new_object_decomposition, global_var_dict = solution
      program = full_program_given_on_clauses(on_clauses, new_object_decomposition, global_var_dict, grid_size)
      push!(program_strings, program)
    end
  end
  program_strings
end

function synthesis_program_pedro(observations::AbstractArray)

end

function generate_observations(model_name::String)
  program_expr = compiletojulia(parseautumn(programs[model_name]))
  m = eval(program_expr)
  if model_name == "particles"
    observations, user_events, grid_size = generate_observations_particles(m)
  elseif model_name == "ants"
    observations, user_events, grid_size = generate_observations_ants(m)
  elseif model_name == "lights"
    observations, user_events, grid_size = generate_observations_lights(m)
  elseif model_name == "water_plug"
    observations, user_events, grid_size = generate_observations_water_plug(m)
  elseif model_name == "ice"
    observations, user_events, grid_size = generate_observations_ice(m)
  elseif model_name == "tetris"
    observations, user_events, grid_size = generate_observations_tetris(m)
  elseif model_name == "snake"
    observations, user_events, grid_size = generate_observations_snake(m)
  elseif model_name == "magnets_i"
    observations, user_events, grid_size = generate_observations_magnets_i(m)
  elseif model_name == "magnets_ii"
    observations, user_events, grid_size = generate_observations_magnets_ii(m)
  elseif model_name == "magnets_iii"
    observations, user_events, grid_size = generate_observations_magnets_iii(m)
  elseif model_name == "disease"
    observations, user_events, grid_size = generate_observations_disease(m)
  elseif model_name == "space_invaders"
    observations, user_events, grid_size = generate_observations_space_invaders(m)
  elseif model_name == "gol"
    observations, user_events, grid_size = generate_observations_gol(m)
  elseif model_name == "sokoban_i"
    observations, user_events, grid_size = generate_observations_sokoban(m)
  elseif model_name == "sokoban_ii"
    observations, user_events, grid_size = generate_observations_sokoban_ii(m)
  elseif model_name == "grow"
    observations, user_events, grid_size = generate_observations_grow(m)
  elseif model_name == "mario"
    observations, user_events, grid_size = generate_observations_mario(m)
  elseif model_name == "sand"
    observations, user_events, grid_size = generate_observations_sand_simple(m)
  elseif model_name == "gravity_i"
    observations, user_events, grid_size = generate_observations_gravity(m)
  elseif model_name == "gravity_ii"
    observations, user_events, grid_size = generate_observations_gravity2(m)
  elseif model_name == "gravity_iii"
    observations, user_events, grid_size = generate_observations_gravity3(m)
  elseif model_name == "egg"
    observations, user_events, grid_size = generate_observations_egg(m)
  elseif model_name == "balloon"
    observations, user_events, grid_size = generate_observations_balloon(m)
  elseif model_name == "wind"
    observations, user_events, grid_size = generate_observations_wind(m)
  elseif model_name == "paint"
    observations, user_events, grid_size = generate_observations_paint(m)
  elseif model_name == "chase"
    observations, user_events, grid_size = generate_observations_chase(m)
  else
    error("model $(model_name) does not exist")
  end
end

programs = Dict("particles"                                 => """(program
                                                                  (= GRID_SIZE 16)

                                                                  (object Particle (Cell 0 0 "blue"))

                                                                  (: particles (List Particle))
                                                                  (= particles 
                                                                    (initnext (list) 
                                                                              (updateObj (prev particles) (--> obj (uniformChoice (list (moveLeft obj) (moveRight obj) (moveDown obj) (moveUp obj)) ))))) 

                                                                  (on clicked (= particles (addObj (prev particles) (Particle (Position (.. click x) (.. click y))))))
                                                                  )""",
                "chase"                                      => """(program
                                                                    (= GRID_SIZE 16)
                                                                    
                                                                    (object Ant (Cell 0 0 "red"))
                                                                    (object Agent (Cell 0 0 "green"))
                                                                  
                                                                    (: ants (List Ant))
                                                                    (= ants (initnext (list (Ant (Position 6 9)) ) 
                                                                                      (prev ants)))
                                                                  
                                                                    (: agent Agent)
                                                                    (= agent (initnext (Agent (Position 7 5)) (prev agent))) 
                                                                                                                                                                                    
                                                                    (: time Int)
                                                                    (= time (initnext 0 (+ (prev time) 1)))                                                                                                                   
                                                                                                    
                                                                    (on true (= ants (updateObj (prev ants) (--> obj (move obj (unitVector obj (closest obj Agent)))) )))
                                                                    (on (== (% time 4) 2) (= ants (addObj ants (map Ant (randomPositions GRID_SIZE 1)))))
                                                                    
                                                                    (on left (= agent (moveLeft (prev agent))))
                                                                    (on right (= agent (moveRight (prev agent))))
                                                                    (on up (= agent (moveUp (prev agent))))
                                                                    (on down (= agent (moveDown (prev agent))))
                                                                            
                                                                    (on (intersects (prev agent) (prev ants)) (= agent (removeObj (prev agent))))                                                                                                                   
                                                                  )""",
                "lights"                                    => """(program
                                                                  (= GRID_SIZE 10)
                                                                
                                                                  (object Light (: on Bool) (Cell 0 0 (if on then "yellow" else "white")))
                                                                
                                                                  (: lights (List Light))
                                                                  (= lights (initnext (map (--> pos (Light false pos)) (filter (--> pos (== (.. pos x) (.. pos y))) (allPositions GRID_SIZE))) 
                                                                                      (prev lights)))
                                                                
                                                                  (on clicked (= lights (updateObj lights (--> obj (updateObj obj "on" (! (.. obj on)))))))
                                                                )""",
                "water_plug"                                => """(program
                                                                  (= GRID_SIZE 16)
                                                                
                                                                  (object Button (: color String) (Cell 0 0 color))
                                                                  (object Vessel (Cell 0 0 "purple"))
                                                                  (object Plug (Cell 0 0 "orange"))
                                                                  (object Water (Cell 0 0 "blue"))
                                                                
                                                                  (: vesselButton Button)
                                                                  (= vesselButton (Button "purple" (Position 2 0)))
                                                                  (: plugButton Button)
                                                                  (= plugButton (Button "orange" (Position 5 0)))
                                                                  (: waterButton Button)
                                                                  (= waterButton (Button "blue" (Position 8 0)))
                                                                  (: removeButton Button)
                                                                  (= removeButton (Button "black" (Position 11 0)))
                                                                  (: clearButton Button)
                                                                  (= clearButton (Button "red" (Position 14 0)))
                                                                
                                                                  (: vessels (List Vessel))
                                                                  (= vessels (initnext (list (Vessel (Position 6 15)) (Vessel (Position 6 14)) (Vessel (Position 6 13)) (Vessel (Position 5 12)) (Vessel (Position 4 11)) (Vessel (Position 3 10)) (Vessel (Position 9 15)) (Vessel (Position 9 14)) (Vessel (Position 9 13)) (Vessel (Position 10 12)) (Vessel (Position 11 11)) (Vessel (Position 12 10))) (prev vessels)))
                                                                  (: plugs (List Plug))
                                                                  (= plugs (initnext (list (Plug (Position 7 15)) (Plug (Position 8 15)) (Plug (Position 7 14)) (Plug (Position 8 14)) (Plug (Position 7 13)) (Plug (Position 8 13))) (prev plugs)))
                                                                  (: water (List Water))
                                                                  (= water (initnext (list) (updateObj (prev water) nextLiquid)))
                                                                
                                                                  (= currentParticle (initnext "vessel" (prev currentParticle)))
                                                                
                                                                  (on (& clicked (& (isFree click) (== currentParticle "vessel"))) (= vessels (addObj (prev vessels) (Vessel (Position (.. click x) (.. click y))))))
                                                                  (on (& clicked (& (isFree click) (== currentParticle "plug"))) (= plugs (addObj (prev plugs) (Plug (Position (.. click x) (.. click y))))))
                                                                  (on (& clicked (& (isFree click) (== currentParticle "water"))) (= water (addObj (prev water) (Water (Position (.. click x) (.. click y))))))
                                                                  (on (clicked vesselButton) (= currentParticle "vessel"))
                                                                  (on (clicked plugButton) (= currentParticle "plug"))
                                                                  (on (clicked waterButton) (= currentParticle "water"))
                                                                  (on (clicked removeButton) (= plugs (removeObj plugs (--> obj true))))
                                                                  (on (clicked clearButton) (let ((= vessels (removeObj vessels (--> obj true))) (= plugs (removeObj plugs (--> obj true))) (= water (removeObj water (--> obj true))))))  
                                                                )""",
                "ice"                                       => """(program
                                                                  (= GRID_SIZE 8)
                                                                  (object CelestialBody (: day Bool) (list (Cell 0 0 (if day then "gold" else "gray"))
                                                                                                          (Cell 0 1 (if day then "gold" else "gray"))
                                                                                                          (Cell 1 0 (if day then "gold" else "gray"))
                                                                                                          (Cell 1 1 (if day then "gold" else "gray"))))
                                                                  (object Cloud (list (Cell -1 0 "gray")
                                                                                      (Cell 0 0 "gray")
                                                                                      (Cell 1 0 "gray")))
                                                                  
                                                                  (object Water (: liquid Bool) (Cell 0 0 (if liquid then "blue" else "lightblue")))
                                                                  
                                                                  (: celestialBody CelestialBody)
                                                                  (= celestialBody (initnext (CelestialBody true (Position 0 0)) (prev celestialBody)))
                                                                
                                                                  (: cloud Cloud)
                                                                  (= cloud (initnext (Cloud (Position 4 0)) (prev cloud)))
                                                                  
                                                                  (: water (List Water))
                                                                  (= water (initnext (list) (updateObj (prev water) nextWater)))
                                                                  
                                                                  (on left (= cloud (nextCloud cloud (Position -1 0))))
                                                                  (on right (= cloud (nextCloud cloud (Position 1 0))))
                                                                  (on down (= water (addObj water (Water (.. celestialBody day) (move (.. cloud origin) (Position 0 1))))))
                                                                  (on clicked (let ((= celestialBody (updateObj celestialBody "day" (! (.. celestialBody day)))) (= water (updateObj water (--> drop (updateObj drop "liquid" (! (.. drop liquid)))))))))
                                                                
                                                                  (= nextWater (fn (drop) 
                                                                                  (if (.. drop liquid)
                                                                                    then (nextLiquid drop)
                                                                                    else (nextSolid drop))))
                                                                  
                                                                  (= nextCloud (fn (cloud position)
                                                                                  (if (isWithinBounds (move cloud position)) 
                                                                                    then (move cloud position)
                                                                                    else cloud)))
                                                                )""",
                "tetris" => ""
                ,"snake" => ""
                ,"magnets_i" => ""
                ,"magnets_ii" => ""
                ,"magnets_iii" => ""
                ,"disease"                                    => """(program
                                                                (= GRID_SIZE 8)
                                                                
                                                                (object Particle (: health Bool) (Cell 0 0 (if health then "gray" else "darkgreen")))
                                                      
                                                                (: inactiveParticles (List Particle))
                                                                (= inactiveParticles (initnext (list (Particle true (Position 5 3)) (Particle true (Position 2 1)) (Particle true (Position 4 4)) (Particle true (Position 1 3)) )  
                                                                                    (updateObj (prev inactiveParticles) (--> obj (if (! (.. activeParticle health))
                                                                                                                                  then (updateObj obj "health" false)
                                                                                                                                  else obj)) 
                                                                                                                                                                                (--> obj (adjacent (.. obj origin) (.. (prev activeParticle) origin))))))   
                                                      
                                                                (: activeParticle Particle)
                                                                (= activeParticle (initnext (Particle false (Position 0 0)) (prev activeParticle))) 
                                                      
                                                                (on (!= (length (filter (--> obj (! (.. obj health))) (adjacentObjs activeParticle))) 0) (= activeParticle (updateObj (prev activeParticle) "health" false)))
                                                                (on (clicked (prev inactiveParticles)) 
                                                                    (let ((= inactiveParticles (addObj (prev inactiveParticles) (prev activeParticle))) 
                                                                          (= activeParticle (objClicked click (prev inactiveParticles)))
                                                                          (= inactiveParticles (removeObj inactiveParticles (objClicked click (prev inactiveParticles))))
                                                                        )))
                                                                (on left (= activeParticle (moveNoCollision (prev activeParticle) -1 0)))
                                                                (on right (= activeParticle (moveNoCollision (prev activeParticle) 1 0)))
                                                                (on up (= activeParticle (moveNoCollision (prev activeParticle) 0 -1)))
                                                                (on down (= activeParticle (moveNoCollision (prev activeParticle) 0 1)))
                                                              )"""
                ,"space_invaders" => ""
                ,"gol" => ""
                ,"sokoban_i" =>                               """(program
                                                                  (= GRID_SIZE 8)
                                                                  
                                                                  (object Agent (Cell 0 0 "blue"))
                                                                  (object Box (Cell 0 0 "black"))
                                                                  (object Goal (Cell 0 0 "red"))
                                                                  
                                                                  (: agent Agent)
                                                                  (= agent (initnext (Agent (Position 7 4)) (prev agent)))
                                                                    
                                                                  (: boxes (List Box))
                                                                  (= boxes (initnext (list (Box (Position 1 2)) (Box (Position 0 4)) (Box (Position 4 4))) (prev boxes)))
                                                                
                                                                  (: goal Goal)
                                                                  (= goal (initnext (Goal (Position 0 0)) (prev goal)))
                                                                  
                                                                  (on left (let ((= boxes (moveBoxes (prev boxes) (prev agent) (prev goal) -1 0)) 
                                                                                (= agent (moveAgent (prev agent) (prev boxes) (prev goal) -1 0))))) 
                                                                
                                                                  (on right (let ((= boxes (moveBoxes (prev boxes) (prev agent) (prev goal) 1 0)) 
                                                                                  (= agent (moveAgent (prev agent) (prev boxes) (prev goal) 1 0))))) 
                                                                
                                                                  (on up (let ((= boxes (moveBoxes (prev boxes) (prev agent) (prev goal) 0 -1)) 
                                                                              (= agent (moveAgent (prev agent) (prev boxes) (prev goal) 0 -1))))) 
                                                                
                                                                  (on down (let ((= boxes (moveBoxes (prev boxes) (prev agent) (prev goal) 0 1)) 
                                                                                (= agent (moveAgent (prev agent) (prev boxes) (prev goal) 0 1))))) 
                                                                  
                                                                  (on (& clicked (isFree click)) (= boxes (addObj boxes (Box (Position (.. click x) (.. click y))))))
                                                                
                                                                  (: moveBoxes (-> (List Box) Agent Goal Int Int (List Box)))
                                                                  (= moveBoxes (fn (boxes agent goal x y) 
                                                                                  (updateObj boxes 
                                                                                    (--> obj (if (intersects (move obj x y) goal) then (removeObj obj) else (moveNoCollision obj x y))) 
                                                                                    (--> obj (== (displacement (.. obj origin) (.. agent origin)) (Position (- 0 x) (- 0 y)))))))
                                                                
                                                                  (: moveAgent (-> Agent (List Box) Goal Int Int Agent))
                                                                  (= moveAgent (fn (agent boxes goal x y) 
                                                                                  (if (| (intersects (list (move agent x y)) (moveBoxes boxes agent goal x y)) 
                                                                                          (! (isWithinBounds (move agent x y)))) 
                                                                                    then agent 
                                                                                    else (move agent x y))))
                                                                )"""
                ,"sokoban_ii" => ""
                ,"grow"                                      => """(program
                                                                  (= GRID_SIZE 8)
                                                                  
                                                                  (object Water (Cell 0 0 "blue"))
                                                                  (object Leaf (: color String) (Cell 0 0 color))
                                                                  (object Cloud (list (Cell -1 0 "gray") (Cell 0 0 "gray") (Cell 1 0 "gray")
                                                                                      (Cell -1 1 "gray") (Cell 0 1 "gray") (Cell 1 1 "gray")))
                                                                  
                                                                  (object Sun (: movingLeft Bool) (list (Cell 0 0 "gold")
                                                                                                (Cell 0 1 "gold")
                                                                                                (Cell 1 0 "gold")
                                                                                                (Cell 1 1 "gold")))
                                                                
                                                                  (: sun Sun)
                                                                  (= sun (initnext (Sun false (Position 0 0)) (prev sun)))
                                                                
                                                                  (: water (List Water))
                                                                  (= water (initnext (list) (updateObj (prev water) (--> obj (if (! (isWithinBounds obj)) then (removeObj obj) else (moveDown obj))))))
                                                                  
                                                                  (: cloud Cloud)
                                                                  (= cloud (initnext (Cloud (Position 6 0)) (prev cloud)))
                                                                  
                                                                  (: leaves (List Leaf))
                                                                  (= leaves (initnext (list (Leaf "green" (Position 1 7) ) (Leaf "green" (Position 3 7)) (Leaf "green" (Position 5 7)) ) (prev leaves)))
                                                                                                                                      
                                                                  (on (intersects (map (--> obj (moveDown obj)) (prev water) ) (prev leaves))
                                                                    (= water (removeObj (prev water) (--> obj (intersects (moveDown obj) (prev leaves))) ) ) )
                                                                
                                                                  (on (& (intersects (map (--> obj (moveDown obj)) (prev water)) (filter (--> obj (== (.. obj color) "green")) (prev leaves))) (! (intersects (prev sun) (prev cloud))))
                                                                    (= leaves (addObj (prev leaves) (map (--> obj (Leaf (if (== (.. (.. (moveUp obj) origin) y) 4) then "mediumpurple" else "green") (.. (moveUp obj) origin))) (filter (--> obj (intersects (moveUp obj) (prev water))) (prev leaves))))))

                                                                  (on down
                                                                    (= water (addObj water (Water (.. (moveDown (prev cloud)) origin)))))
                                                                    
                                                                  (on left (= cloud (moveLeft (prev cloud))))
                                                                  (on right (= cloud (moveRight (prev cloud))))
                                                                
                                                                  (on (== (.. (.. (prev sun) origin) x) 0) (= sun (updateObj (prev sun) "movingLeft" false)))
                                                                  (on (== (.. (.. (prev sun) origin) x) 6) (= sun (updateObj (prev sun) "movingLeft" true)))
                                                                
                                                                  (on (clicked (prev sun)) (= sun (if (.. (prev sun) movingLeft) then (moveLeft (prev sun)) else (moveRight (prev sun)))))
                                                                )"""
                ,"mario" => ""
                ,"sand"                                      => """(program
                                                                  (= GRID_SIZE 10)
                                                                  
                                                                  (object Button (: color String) (Cell 0 0 color))
                                                                  (object Sand (: liquid Bool) (Cell 0 0 (if liquid then "sandybrown" else "tan")))
                                                                  (object Water (Cell 0 0 "skyblue"))
                                                                  
                                                                  (: sandButton Button)
                                                                  (= sandButton (initnext (Button "tan" (Position 2 0)) (prev sandButton)))
                                                                  
                                                                  (: waterButton Button)
                                                                  (= waterButton (initnext (Button "skyblue" (Position 7 0)) (prev waterButton)))
                                                                  
                                                                  (: sand (List Sand))
                                                                  (= sand (initnext (list) 
                                                                            (updateObj (prev sand) (--> obj (if (.. obj liquid) 
                                                                                      then (nextLiquid obj)
                                                                                      else (nextSolid obj))))))
                                                                  
                                                                  (: water (List Water))
                                                                  (= water (initnext (list) (updateObj (prev water) (--> obj (nextLiquid obj)))))
                                                                  
                                                                    
                                                                  (: clickType String)
                                                                  (= clickType (initnext "sand" (prev clickType)))
                                                                  
                                                                  (on true (= sand (updateObj (prev sand) (--> obj (updateObj obj "liquid" true)) (--> obj (& (! (.. obj liquid)) (intersects (adjacentObjs obj) (prev water)))))))
                                                                  
                                                                  (on (clicked sandButton) (= clickType "sand"))
                                                                  (on (clicked waterButton) (= clickType "water"))
                                                                  (on (& (& clicked (isFree click)) (== clickType "sand"))  (= sand (addObj sand (Sand false (Position (.. click x) (.. click y))))))
                                                                  (on (& (& clicked (isFree click)) (== clickType "water")) (= water (addObj water (Water (Position (.. click x) (.. click y))))))
                                                                
                                                                )"""
                ,"gravity_i"                                 => """(program
                                                                  (= GRID_SIZE 16)
                                                                    
                                                                  (object Button (: color String) (Cell 0 0 color))
                                                                  (object Blob (list (Cell 0 -1 "blue") (Cell 0 0 "blue") (Cell 1 -1 "blue") (Cell 1 0 "blue")))
                                                        
                                                                  (: leftButton Button)
                                                                  (= leftButton (initnext (Button "red" (Position 0 7)) (prev leftButton)))
                                                                  
                                                                  (: rightButton Button)
                                                                  (= rightButton (initnext (Button "darkorange" (Position 15 7)) (prev rightButton)))
                                                                    
                                                                  (: upButton Button)
                                                                  (= upButton (initnext (Button "gold" (Position 7 0)) (prev upButton)))
                                                                  
                                                                  (: downButton Button)
                                                                  (= downButton (initnext (Button "green" (Position 7 15)) (prev downButton)))
                                                                  
                                                                  (: blobs (List Blob))
                                                                  (= blobs (initnext (list) (prev blobs)))
                                                                  
                                                                  (: gravity String)
                                                                  (= gravity (initnext "down" (prev gravity)))
                                                                  
                                                                  (on (== gravity "left") (= blobs (updateObj blobs (--> obj (moveLeftNoCollision obj)))))
                                                                  (on (== gravity "right") (= blobs (updateObj blobs (--> obj (moveRightNoCollision obj)))))
                                                                  (on (== gravity "up") (= blobs (updateObj blobs (--> obj (moveUpNoCollision obj)))))
                                                                  (on (== gravity "down") (= blobs (updateObj blobs (--> obj (moveDownNoCollision obj)))))
                                                                  
                                                                  (on (& clicked (isFree click)) (= blobs (addObj blobs (Blob (Position (.. click x) (.. click y))))) )
                                                                  
                                                                  (on (clicked leftButton) (= gravity "left"))
                                                        
                                                                  (on (clicked rightButton) (= gravity "right"))
                                                        
                                                                  (on (clicked upButton) (= gravity "up"))
                                                        
                                                                  (on (clicked downButton) (= gravity "down"))
                                                                )"""
                ,"gravity_ii"                                => """(program
                                                                    (= GRID_SIZE 30)
                                                                      
                                                                    (object Button (: color String) (Cell 0 0 color))
                                                                    (object Blob (: color String) (list (Cell 0 -1 color) (Cell 0 0 color) (Cell 1 -1 color) (Cell 1 0 color)))
                                                                  
                                                                    (: leftButton Button)
                                                                    (= leftButton (initnext (Button "red" (Position 0 14)) (prev leftButton)))
                                                                    
                                                                    (: rightButton Button)
                                                                    (= rightButton (initnext (Button "darkorange" (Position 29 14)) (prev rightButton)))
                                                                      
                                                                    (: upButton Button)
                                                                    (= upButton (initnext (Button "gold" (Position 14 0)) (prev upButton)))
                                                                    
                                                                    (: downButton Button)
                                                                    (= downButton (initnext (Button "green" (Position 14 29)) (prev downButton)))
                                                                    
                                                                    (: blobs (List Blob))
                                                                    (= blobs (initnext (list) (prev blobs)))
                                                                    
                                                                    (: gravity String)
                                                                    (= gravity (initnext "down" (prev gravity)))
                                                                    
                                                                    (: blobColor Int)
                                                                    (= blobColor (initnext 0 (prev blobColor)))
                                                                    
                                                                    (on (== gravity "left") (= blobs (updateObj (prev blobs) (--> obj (moveLeftNoCollision obj)))))
                                                                    (on (== gravity "right") (= blobs (updateObj (prev blobs) (--> obj (moveRightNoCollision obj)))))
                                                                    (on (== gravity "up") (= blobs (updateObj (prev blobs) (--> obj (moveUpNoCollision obj)))))
                                                                    (on (== gravity "down") (= blobs (updateObj (prev blobs) (--> obj (moveDownNoCollision obj)))))
                                                                    
                                                                    (on (& clicked (isFree click)) (= blobColor (% (+ (prev blobColor) 1) 3)))
                                                                    (on (& (& clicked (isFree click)) (== blobColor 0)) (= blobs (addObj blobs (Blob "blue" (Position (.. click x) (.. click y))))))
                                                                    (on (& (& clicked (isFree click)) (== blobColor 1)) (= blobs (addObj blobs (Blob "mediumpurple" (Position (.. click x) (.. click y))))))
                                                                    (on (& (& clicked (isFree click)) (== blobColor 2)) (= blobs (addObj blobs (Blob "magenta" (Position (.. click x) (.. click y))))))
                                                                    
                                                                    (on (clicked leftButton) (= gravity "left"))
                                                                  
                                                                    (on (clicked rightButton) (= gravity "right"))
                                                                  
                                                                    (on (clicked upButton) (= gravity "up"))
                                                                  
                                                                    (on (clicked downButton) (= gravity "down"))
                                                                  )"""
                ,"gravity_iii"                                 => """(program
                                                                    (= GRID_SIZE 19)
                                                                    (= background "black")
                                                                      
                                                                    (object Button (: color String) (Cell 0 0 color))
                                                                    (object Blob (list (Cell 0 0 "blue")))
                                                                    
                                                                    (: blobs (List Blob))
                                                                    (= blobs (initnext (list (Blob (Position 9 9))) (prev blobs)))
                                                                    
                                                                    (: xVel Int)
                                                                    (= xVel (initnext 0 (prev xVel)))
                                                                    
                                                                    (: yVel Int)
                                                                    (= yVel (initnext 0 (prev yVel)))
                                                                              
                                                                    (on (& clicked (isFree click)) (= blobs (addObj blobs (Blob (Position (.. click x) (.. click y))))))
                                                                    
                                                                    (on (& left (!= (prev xVel) -1)) (= xVel (- (prev xVel) 1)))
                                                                    (on (& right (!= (prev xVel) 1)) (= xVel (+ (prev xVel) 1)))
                                                                  
                                                                    (on (& up (!= (prev yVel) -1)) (= yVel (- (prev yVel) 1)))
                                                                    (on (& down (!= (prev yVel) 1)) (= yVel (+ (prev yVel) 1)))
                                                                  
                                                                    (on true (= blobs (updateObj blobs (--> obj (moveNoCollision obj (Position xVel yVel))))))
                                                                  )"""
                ,"egg"                                         => """(program
                                                                    (= GRID_SIZE 16)
                                                                    (= background "black")
                                                                    
                                                                    (object Button (: color String) (Cell 0 0 color))
                                                                    (object Piece (Cell 0 0 "gold"))
                                                                    (object Egg (list (Cell -1 -2 "tan") (Cell 0 -2 "tan") (Cell 1 -2 "tan")  
                                                                                      (Cell -2 -1 "tan") (Cell -1 -1 "tan") (Cell 0 -1 "tan") (Cell 1 -1 "tan") (Cell 2 -1 "tan")
                                                                                      (Cell -2 0 "tan") (Cell -1 0 "tan") (Cell 0 0 "tan") (Cell 1 0 "tan") (Cell 2 0 "tan") 
                                                                                      (Cell -2 1 "tan") (Cell -1 1 "tan") (Cell 0 1 "tan") (Cell 1 1 "tan") (Cell 2 1 "tan") 
                                                                                    (Cell -1 2 "tan") (Cell 0 2 "tan") (Cell 1 2 "tan")))
                                                                  
                                                                    (: egg Egg)
                                                                    (= egg (initnext (Egg (Position 7 13)) (prev egg)))
                                                                    
                                                                    (: pieces (List Piece))
                                                                    (= pieces (initnext (list) (updateObj (prev pieces) (--> obj (nextLiquid obj)))))
                                                                    
                                                                    (: button Button)
                                                                    (= button (initnext (Button "red" (Position 0 0)) (updateObj (prev button) "color" (if gravity then "pink" else "red"))))
                                                                    
                                                                    (: gravity Bool)
                                                                    (= gravity (initnext false (prev gravity)))
                                                                  
                                                                    (: height Int)
                                                                    (= height (initnext 15 (prev height)))
                                                                    
                                                                    (on gravity (= egg (moveDownNoCollision (prev egg))))
                                                                      
                                                                    (on (& left (! gravity)) (= egg (moveLeftNoCollision (prev egg))))
                                                                    (on (& right (! gravity)) (= egg (moveRightNoCollision (prev egg))))
                                                                    (on (& up (! gravity)) (= egg (moveUpNoCollision (prev egg))))
                                                                    (on (& down (! gravity)) (= egg (moveDownNoCollision (prev egg))))
                                                                  
                                                                    (on (clicked (prev button)) 
                                                                      (let ((= gravity (! (prev gravity)))
                                                                            (= height (.. (.. (prev egg) origin) y)))))
                                                                  
                                                                    (on (& (< height 7) (== (.. (.. egg origin) y) 13)) 
                                                                      (let ((= egg (removeObj egg)) 
                                                                            (= pieces (addObj (prev pieces) (map (--> obj (Piece (Position (.. (.. obj position) x) (+ 1 (.. (.. obj position) y))))) (render (prev egg))))))))
                                                                  
                                                                  )"""
                ,"balloon" => ""
              ,"wind"                                          => """(program
                                                                      (= GRID_SIZE 17)
                                                                      (= background "darkblue")
                                                            
                                                                      (object Water (Cell 0 0 "lightblue"))
                                                                      (object Cloud (map (--> pos (Cell (.. pos x) (.. pos y) "gray")) (rect (Position 0 0) (Position 16 1))) (prev cloud))
                                                                      
                                                                      (: water (List Water))
                                                                      (= water (initnext (list) (prev water))) 
                                                                           
                                                                      (: cloud Cloud)
                                                                      (= cloud (initnext (Cloud (Position 0 0)) (prev cloud)))
                                                            
                                                                      (: wind Int)
                                                                      (= wind (initnext 0 (prev wind)))
                                                                      
                                                                      (: time Int)
                                                                      (= time (initnext 0 (+ (prev time) 1)))
                                                                      
                                                                      (on (== wind 0) (= water (updateObj (prev water) (--> obj (moveDown obj)))))
                                                                      (on (== wind 1) (= water (updateObj (prev water) (--> obj (moveRight (moveDown obj))))))
                                                                      (on (== wind -1) (= water (updateObj (prev water) (--> obj (moveLeft (moveDown obj))))))
                                                                    
                                                                      (on left (= wind (if (== (prev wind) -1) then (prev wind) else (- (prev wind) 1))))
                                                                      (on right (= wind (if (== (prev wind) 1) then (prev wind) else (+ (prev wind) 1))))
                                                                      
                                                                      
                                                                      (on (== (% time 5) 2) 
                                                                        (= water (addObj 
                                                                                  water 
                                                                                  (map (--> pos (Water pos)) (list (Position 2 2)
                                                                                                                    
                                                                                                                        (Position 6 2)
                                                                                                                    
                                                                                                                        (Position 10 2)
                                                                                                                        
                                                                                                                        (Position 14 2)))))))"""
                ,"paint"                                         => """(program
                                                                      (= GRID_SIZE 16)
                                                                      
                                                                      (object Particle (: color String) (Cell 0 0 color))
                                                                    
                                                                      (: particles (List Particle))
                                                                      (= particles (initnext (list) (prev particles)))
                                                                      
                                                                      (: currColor String)
                                                                      (= currColor (initnext "red" (prev currColor)))
                                                                      
                                                                      (on (& clicked (isFree click)) (= particles (addObj (prev particles) (Particle currColor (Position (.. click x) (.. click y))))))
                                                                      (on (& up (== (prev currColor) "red")) (= currColor "gold"))
                                                                      (on (& up (== (prev currColor) "gold")) (= currColor "green"))
                                                                      (on (& up (== (prev currColor) "green")) (= currColor "blue"))
                                                                      (on (& up (== (prev currColor) "blue")) (= currColor "purple"))
                                                                      (on (& up (== (prev currColor) "purple")) (= currColor "red"))
                                                                    )"""
                ,"ants" =>                                        """(program
                                                                      (= GRID_SIZE 16)
                                                                      
                                                                      (object Ant (Cell 0 0 "gray"))
                                                                      (object Food (Cell 0 0 "red"))
                                                                    
                                                                      (: ants (List Ant))
                                                                      (= ants (initnext (map Ant (randomPositions GRID_SIZE 1)) (prev ants)))
                                                                    
                                                                      (: foods (List Food))
                                                                      (= foods (initnext (list) (prev foods)))
                                                                      
                                                                      (on true (= ants (updateObj (prev ants) (--> obj (move obj (unitVector obj (closest obj Food)))))))
                                                                      (on true (= foods (updateObj (prev foods) (--> obj (if (intersects obj (prev ants))
                                                                                                                           then (removeObj obj)
                                                                                                                           else obj)))))
                                                                    
                                                                      (on clicked (= foods (addObj foods (map Food (randomPositions GRID_SIZE 4)))))
                                                                    )"""
                )
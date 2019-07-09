%% --------------------------------------------
%% BW domain
%% Translation from Action Language Description
%% of the domain layout including some of the 
%% available object & agent properties, actions, 
%% a simple planning module, affordance relations
%% and their corresponding executability conditions. 
%%
%% This Script includes some affordance relations
%% similar to the previous versions of the program.
%% The representation of these has been altered to 
%% include several simple affordances in a single
%% executability condition. Some relations from the
%% previous program version have been discarded.
%% 
%% --------------------------------------------

#const n=4.

sorts

#area = {room, corridor}.
#exit = {door}.

#box = {box1, box2, box3, box4, box5}.
#other = {apple}.
#agent = {robot}.  %, human}.
#fixed_element = {floor, door}.
#object = #box + #other.
#thing = #object + #agent.

#obj_w_zloc = #thing + #fixed_element.
#surf = #box+{floor}.

#vertsz = 0..15.
#step = 0..n.
#id = 10..30.


#substance = {paper, cardboard, wood, bio}.
#power = {weak, strong}.
#weight = {light, medium, heavy}.

%%--------
%% Fluents
%%--------

#inertial_fluent = on(#thing(X), #surf(Y)):X!=Y +
		   z_loc(#obj_w_zloc, #vertsz) + 
		   location(#thing, #area) + 
		   in_hand(#agent, #object).

#defined_fluent = in_range(#obj_w_zloc, #obj_w_zloc, #vertsz) + 
		  can_support(#surf, #thing).

#fluent = #inertial_fluent + #defined_fluent.

%%--------
%% Actions 
%%--------

#action = go_to(#agent, #surf) +
          move_to(#agent, #object(X), #surf(Y)):X!=Y +
          go_through(#agent, #exit, #area) +
          pick_up(#agent, #object). 
          
          
%%-----------
%% Predicates
%%-----------

predicates

holds(#fluent, #step).
occurs(#action, #step).

height(#obj_w_zloc, #vertsz).
has_power(#agent, #power).
has_weight(#thing, #weight).
material(#surf, #substance).

has_exit(#area, #exit). 

% affordance predicates
affordance_permits(#action, #step, #id).
affordance_forbids(#action, #step, #id).



% planning: not in the original AL description.
success().
goal(#step). 
something_happened(#step).


%%-----------------------------------------------------------
%%                         Rules
%%-----------------------------------------------------------

rules

%%---------------
%% I Causal Laws
%%---------------

% 1.
holds(on(A, S), I+1) :- occurs(go_to(A, S), I).

% 2. 
holds(on(O, S), I+1) :- occurs(move_to(A, O, S), I).

% 3. 
-holds(in_hand(A, O), I+1) :- occurs(move_to(A, O, S), I).

% 4. 
holds(z_loc(A, Z+H), I+1) :- occurs(go_to(A, S), I),
			     height(A, H), 
			     holds(z_loc(S, Z), I). 

% 5. 
holds(location(A, L), I+1) :- occurs(go_through(A, D, L), I).

% 6. 
holds(z_loc(O, Z+H), I+1) :- occurs(move_to(A, O, S), I),  
			     holds(z_loc(S, Z), I), 
			     height(O, H).

% 7.
holds(in_hand(A, O), I+1) :- occurs(pick_up(A, O), I).

% 8.
-holds(on(O, S), I+1) :- occurs(pick_up(A, O), I),
			 holds(on(O, S), I).

% 9. 
-holds(z_loc(O, Z), I+1) :- occurs(pick_up(A, O), I), 
			    holds(z_loc(O, Z), I).

% 10.
-holds(on(A, S), I+1) :- occurs(go_to(A, S2), I),
			 holds(on(A, S), I). 

% 11.
-holds(z_loc(A, Z), I+1) :- occurs(go_to(A, S), I), 
			    holds(z_loc(A, Z), I),
			    holds(on(A, S1), I),
			    holds(z_loc(S1, ZS1),I), 
			    holds(z_loc(S, ZS), I),
			    ZS!=ZS1.



%%---------------------
%% II State Constraints
%% --------------------

% 1. 
-holds(on(O, S), I) :- holds(on(O2, S), I), O!=O2, #box(S).

% 2. 
holds(z_loc(O, Z+H), I) :- holds(on(O, S), I), 
			   holds(z_loc(S, Z), I), 
			   height(O, H).

% 3.
-holds(on(O, S), I) :- holds(on(O, S2), I), 
		       #thing(O), 
		       S!=S2.
 
% 4.
-height(O, H2) :- height(O, H), H!=H2.

% 5.
-holds(location(O, L), I) :- holds(location(O, L2), I), L!=L2.

% 6.
holds(in_range(Ob1, Ob2, X), I) :- holds(z_loc(Ob1, Z1), I), 
				   holds(z_loc(Ob2, Z2), I),
				   height(Ob1, H1),
				   height(Ob2, H2),
				   Z1 - H1 >= Z2 - H2, 
				   X = (Z1 - H1) - (Z2 - H2).
				   
% 7.
holds(can_support(S, O), I) :- has_weight(O, light),
                               material(S, bio).
                               
% 8. 
holds(can_support(S, O), I) :- not has_weight(O, heavy), 
                               material(S, cardboard).

% 9. 
holds(can_support(S, O), I) :- not has_weight(O, heavy),
                               material(S, paper).

% 10. 
holds(can_support(S, O), I) :- material(S, wood).

% 11.				  
-holds(can_support(S, O), I) :- holds(on(S, S2), I), 
                                not holds(can_support(S2, O), I).


%% ----------------------------
%% III Executability Conditions
%%-----------------------------

% 1.
-occurs(pick_up(A, O), I) :- holds(in_hand(A, O2), I).

% 2.
-occurs(move_to(A, O, S), I) :- not holds(in_hand(A, O), I).

% 3.
-occurs(go_to(A, S), I) :- holds(on(A, S), I).

% 4.
-occurs(pick_up(A, O), I) :- holds(on(O2, O), I).

% 5.
-occurs(go_to(A, S), I) :- holds(on(O, S), I), #box(S). 

% 6.
-occurs(move_to(A, O, S), I) :- holds(on(O2, S), I), #box(S).

% 7.
-occurs(go_through(A, D, Loc2), I) :- not holds(location(A, Loc1), I),
				      not has_exit(Loc1, D),
				      not has_exit(Loc2, D).

% 8.
-occurs(go_to(A, S), I) :- holds(in_hand(A2, S), I).

% 9. 
-occurs(go_to(A, S), I) :- holds(z_loc(S, Z), I), 
                           holds(z_loc(A, Z2), I),
                           height(A, H),
                           Z2 - H = BASE, 
                           Z < BASE - 1.

% 10. 
-occurs(go_to(A, S), I) :- holds(z_loc(S, Z), I), 
                           holds(z_loc(A, Z2), I), 
                           height(A, H), 
                           Z2 - H = BASE, 
                           Z > BASE + 1. 
                           
%% ------------------------------
%% Exec. conditions + affordances
%% ------------------------------                   

% 1. 
-occurs(A, I) :- affordance_forbids(A, I, ID).

% 2.
% pick_up impossible if object is not within agents' reach
-occurs(pick_up(A, O), I) :- not affordance_permits(pick_up(A, O), I, 11).


% 3.
% pick_up impossible for medium and heavy objects, unless
% the agent is strong.  
-occurs(pick_up(A, O), I) :- has_weight(O, medium), 
                             not affordance_permits(pick_up(A, O), I, 10).

% 4.
-occurs(pick_up(A, O), I) :- has_weight(O, heavy), 
                             not affordance_permits(pick_up(A, O), I, 10).

% 5.
% move_to impossible if target surface cannot support the obj. + 
% target surface is out of agents' reach. 
% potentially, agent being able to lift the object can be added
% as a clause, but would that be helpful? 
-occurs(move_to(A, O, S), I) :- not affordance_permits(move_to(A, O, S), I, 12), 
                                not affordance_permits(move_to(A, O, S), I, 13).
                            
                           
% 6. 
% go_to impossible unless target surface is within agents'
% movement range, and can support the agents' weight.
-occurs(go_to(A, S), I) :- not affordance_permits(go_to(A, S), I, 14), 
                           not affordance_permits(go_to(A, S), I, 15),
                           not affordance_permits(go_to(A, S), I, 16).

% 7. 
% go_through impossible unless there's a surface within range
% of the opening + agents' height allows them to fit through
% the opening. 
% N.B. this should have an additional constraint: the surface
% should be able to support the agent. However, I don't see a 
% way to include this variable in the head of the rule. 
-occurs(go_through(A, E, L), I) :- not affordance_permits(go_through(A, E, L), I, 17), 
                                   not affordance_permits(go_through(A, E, L), I, 18), 
                                   not affordance_permits(go_through(A, E, L), I, 19), 
                                   not affordance_permits(go_through(A, E, L), I, 20),
                                   not affordance_permits(go_through(A, E, L), I, 21).
                                   
% 8.
% Alternative to 8. go_through impossible, unless a surface 
% exists within appropriate range of the opening + 
% the surface can support the agent
% the agent can fit through the door.
%-occurs(go_through(A, Opening, L), I) :- not affordance_permits(go_to(A, S), I, 16), 
%                                         not holds(in_range(Opening, S, X), I),
%                                         not holds(in_range(S, Opening, Y), I), 
%                                         X<=1, 0<=X, Y<=1, 0<=Y,
%                                         not affordance_permits(go_through(A, E, L), I, 19).
                                         
% 9. 
% go_through impossible unless the opening is within agents' movement range (reach). 
% 26 remains the same as it was in the previous verison of the program. 
-occurs(go_through(A, D, R), I) :- not affordance_permits(go_through(A, D, R), I, 26).



% I think I don't see a way for me to make complex affordances in this domain  - the ones I had before were 
% all I could come up with in the end, and they had a problem of doing the planning 
% instead of the panning module itself. 
% this is the issue with having multi-step plans, which involve the same objects and actions several times. 
% i.e. I can't think of a legit compl. aff. in this scen. unless 

% 5 - combine 10+11
% trivial
% 8 
                             

%%---------------------------------------------------------
%%                   Inertia Axiom + CWA
%%---------------------------------------------------------


% Inertial fluents
holds(F, I+1) :- #inertial_fluent(F),
		holds(F, I),
		not -holds(F, I+1).

-holds(F, I+1) :- #inertial_fluent(F),
		 -holds(F, I),
		 not holds(F, I+1). 


% CWA for Defined fluents
-holds(F,I) :- not holds(F,I), #defined_fluent(F).


% CWA for actions
-occurs(A, I) :- not occurs(A, I).


%%---------------------------------------------------------
%%                         Planning
%%---------------------------------------------------------


success :- goal(I),
           I <= n. 
:- not success.

% an action must occur at each step
occurs(A,I) | -occurs(A,I) :- not goal(I).

% do not allow concurrent actions
:- occurs(A1, I),
   occurs(A2, I),
   A1!=A2.

% forbid agents from procrastinating
something_happened(I) :- occurs(A,I).

:- not something_happened(I),
   something_happened(I+1).

:- goal(I), goal(I-1),
   J < I,
   not something_happened(J).
   
   
%% ------------------------------------------------------------
%%                   Affordance Relations
%% ------------------------------------------------------------

% 1. 
% ID #10 
affordance_permits(pick_up(A, O), I, 10) :- has_power(A, strong).

% 2. 
% Aff. permits picking up objects, if they are in the agents reach.
affordance_permits(pick_up(A, O), I, 11) :- height(A, H), height(O, HO), 
                                            holds(in_range(O, A, X), I),
                                            X < H,
                                            X >=0.


% 3. Aff. permits moving objects, is the surface supports them.
affordance_permits(move_to(A, O, S), I, 12) :- holds(can_support(S, O), I).

% 3. Aff. permits moving objects, if the target surface is within range of agents' reach (assumed to be the span of the agents body). 
affordance_permits(move_to(A, O, S), I, 13) :- holds(in_range(S, A, X), I),
                                               height(A, H), #vertsz(X),
                                               X < H, 
                                               X >= 0.

% 4. Aff. permits going to surfaces, if they're not too high for the agent.
affordance_permits(go_to(A, S), I, 14) :- holds(z_loc(S, Z), I), 
                                          holds(z_loc(A, Z2), I), 
                                          height(A, H), 
                                          Z2 - H = BASE, 
                                          Z <= BASE + 1. 

% 5. Aff. permits going to surfaces, if they're not too low for the agent.
affordance_permits(go_to(A, S), I, 15) :- holds(z_loc(S, Z), I), 
                                          holds(z_loc(A, Z2), I),
                                          height(A, H),
                                          Z2 - H = BASE, 
                                          Z >= BASE - 1.

% 6. Aff. permits going to surfaces, if they can support the agent.
affordance_permits(go_to(A, S), I, 16) :- holds(can_support(S, A), I).

% 7 & 8. Aff. permits going through an opening if there's a surface within 1 unit of the opening. 
affordance_permits(go_through(A, Opening, L), I, 17) :- holds(in_range(Opening, S, X), I), 
                                                        #surf(S),
                                                        X<=1, 0<=X. 

affordance_permits(go_through(A, Opening, L), I, 18) :- holds(in_range(S, Opening, X), I), 
                                                        #surf(S),
                                                        X<=1, 0<=X. 

% 9. Aff. permits going through openings that the agent can fit through.
affordance_permits(go_through(A, E, L), I, 19) :- height(A, H), 
                                                  height(E, H_exit),
                                                  H <= H_exit.

% 10.
% ID #26
affordance_permits(go_through(A, D, L), I, 26) :- holds(on(A, S), I),
                                                  height(A, HA),
                                                  height(D, HD),
                                                  height(S, HS),
                                                  holds(in_range(D, S, X), I), 
                                                  HS + HA > X,
                                                  HS < X + HD.
                                                  



                                                  
% 11.
% ID #20
affordance_permits(go_through(A, D, L), I, 20) :- holds(in_range(D, A, X), I),
                                                  X <= 1. 

affordance_permits(go_through(A, D, L), I, 21) :- holds(in_range(A, D, X), I),
                                                  X <= 1.                                                  
                                                  

%%------------------
%% Initial Condition
%%------------------

has_exit(room, door).
has_exit(corridor, door).

material(box1, paper).
material(box2, wood).
material(box3, wood).
material(box4, wood).
material(floor, wood).

has_weight(box1, light).
has_weight(box2, medium).
has_weight(box3, medium).
has_weight(box4, heavy).
has_weight(robot, medium). 

has_power(robot, strong). 


height(robot, 2).
height(floor, 0).

height(box1, 1). 
height(box2, 1). 
height(box3, 1).
height(box4, 3).

height(door, 3).
height(apple, 1).


holds(z_loc(floor,0),0).
holds(z_loc(door,7),0).


holds(on(box1,box3),0). 
holds(on(box2,floor),0). 
holds(on(box3,floor),0).
holds(on(box4, floor),0). 
%holds(on(apple, box4),0).
holds(on(robot, floor),0).

holds(location(robot, room),0).


% Queries:


% Goals:
%goal(I) :- holds(z_loc(robot, 6), I).
%goal(I) :- holds(z_loc(box2, 3), I).
goal(I) :- holds(location(robot, corridor), I).
%goal(I) :- holds(on(box3, box1), I).


display

goal.
occurs.
%holds.



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

#const n=9.

sorts

%&%& Sorts:

#area = {room, corridor}. 
#exit = {door}. 

#agent = {robot}.  %, human}.
#fixed_element = {floor, door}.
#object = {box1, box2, box3, box4, box5, box6, cup}. %chair, cup}.
#thing = #object + #agent.

#obj_w_zloc = #thing + #fixed_element.

#vertsz = 0..15.
#step = 0..n.
#id = 10..40.
#bool = {true, false}.

%% VARIABLE PARAMETERS
#substance = {paper, cardboard, wood, glass}.
#power = {weak, strong}.
#weight = {light, medium, heavy}.

#skill_level = {poor, average, good}.
#limb = {arm, leg}.


%&%& Sorts: end

%%--------
%% Fluents
%%--------

#inertial_fluent = on(#thing(X), #obj_w_zloc(Y)):X!=Y +
		   z_loc(#obj_w_zloc(X), #vertsz(Z)) + 
		   location(#thing(X), #area(A)) + 
		   in_hand(#agent(A), #object(O)).

#defined_fluent = in_range(#obj_w_zloc(X), #obj_w_zloc(Y), #vertsz):X!=Y + 
		  can_support(#obj_w_zloc(X), #thing(Y)):X!=Y.

#fluent = #inertial_fluent + #defined_fluent.

%%--------
%% Actions 
%%--------


#action = go_to(#agent(A), #obj_w_zloc(S)) +
          put_down(#agent(A), #object(X), #obj_w_zloc(Y)):X!=Y +
          go_through(#agent(A), #exit(E), #area(Ar)) +
          pick_up(#agent(A), #object(O)).   
          
%%-----------
%% Predicates
%%-----------

predicates

holds(#fluent, #step).
occurs(#action, #step).

height(#obj_w_zloc, #vertsz).
has_power(#agent, #power).
has_weight(#thing, #weight).
has_surf(#obj_w_zloc, #bool).
material(#obj_w_zloc, #substance).

joint_mobility(#agent, #limb, #skill_level).
limb_strength(#agent, #limb, #skill_level).

has_exit(#area, #exit). 

% affordance predicates
affordance_permits(#action, #step, #id).
affordance_forbids(#action, #step, #id).

% planning: not in the original AL description.
success().
goal(#step). 
something_happened(#step).
plan_length(#step).

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
holds(on(O, S), I+1) :- occurs(put_down(A, O, S), I).

% 3. 
-holds(in_hand(A, O), I+1) :- occurs(put_down(A, O, S), I).

% 4. 
holds(z_loc(A, Z+H), I+1) :- occurs(go_to(A, S), I),
			     height(A, H), 
			     holds(z_loc(S, Z), I). 

% 5. 
holds(location(A, L), I+1) :- occurs(go_through(A, D, L), I).

% 6. 
% Assume agent ends up on the floor if location is changed
holds(on(A, floor), I+1) :- occurs(go_through(A, D, L), I).

% 7. 
holds(z_loc(O, Z+H), I+1) :- occurs(put_down(A, O, S), I),  
			     holds(z_loc(S, Z), I), 
			     height(O, H).

% 8.
holds(in_hand(A, O), I+1) :- occurs(pick_up(A, O), I).

% 9.
-holds(on(O, S), I+1) :- occurs(pick_up(A, O), I),
			 holds(on(O, S), I).

% 10. 
-holds(z_loc(O, Z), I+1) :- occurs(pick_up(A, O), I), 
			    holds(z_loc(O, Z), I).

% 11.
-holds(on(A, S), I+1) :- occurs(go_to(A, S2), I),
			 holds(on(A, S), I). 

% 12. go_to cancels z_loc, if the target surface is at a different height than starting surface
-holds(z_loc(A, Z), I+1) :- occurs(go_to(A, S), I), 
			    holds(z_loc(S, Z), I),
			    holds(on(A,S2),I),
			    holds(z_loc(S2,Z2),I),
			    Z2!=Z.

% 13. Go thorugh removes the agent from the surface they were standing on.
-holds(on(A, S), I+1) :- occurs(go_through(A, D, L), I),
			 holds(on(A,S),I).

% go through causes NOT location
%-holds(location(A, L), I+1) :- occurs(go_through(A, D, L2), I), holds(location(A,L),I), L2!=L.

%%---------------------
%% II State Constraints
%% --------------------

% 1. 
-holds(on(O, S), I) :- holds(on(O2, S), I), O!=O2, #object(S).

% 2. 
holds(z_loc(O, Z+H), I) :- holds(on(O, S), I), 
			   holds(z_loc(S, Z), I), 
			   height(O, H).
% 3.
-holds(on(O, S), I) :- holds(on(O, S2), I), 
		       #thing(O), 
		       S!=S2.
 
% 4. height and weight have unique values
-height(O, H2) :- height(O, H), H!=H2.
-has_weight(O,W) :- has_weight(O,W2), W!=W2.
-limb_strength(A,L,V) :- limb_strength(A,L,V2), V!=V2.

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
                               material(S, glass).
                               
% 8. 
holds(can_support(S, O), I) :- not has_weight(O, heavy), 
                               material(S, cardboard).

% 9. 
holds(can_support(S, O), I) :- has_weight(O, light),
                               material(S, paper).

% 10. 
holds(can_support(S, O), I) :- material(S, wood).

% 11.				  
-holds(can_support(S, O), I) :- holds(on(S, S2), I), 
                                not holds(can_support(S2, O), I).


% 12. impossible to be on something that doesn't have a surface
-holds(on(X, Y),I) :- not has_surf(Y, true). 


%% ----------------------------
%% III Executability Conditions
%%-----------------------------

% 1.
-occurs(pick_up(A, O), I) :- holds(in_hand(A, O2), I).

% 2.
-occurs(put_down(A, O, S), I) :- not holds(in_hand(A, O), I).

% 3.
-occurs(go_to(A, S), I) :- holds(on(A, S), I).

% 4.
-occurs(pick_up(A, O), I) :- holds(on(O2, O), I).

% 5.
-occurs(go_to(A, S), I) :- holds(on(O, S), I), #object(S). 

% 6.
-occurs(put_down(A, O, S), I) :- holds(on(O2, S), I), #object(S).

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
                           
% 11. 
% forbid the agent from going to the same place
-occurs(go_through(A, D, Loc2), I) :- holds(location(A, Loc1), I),
				      Loc1=Loc2.        
% 12.
-occurs(go_to(A,S),I) :- holds(on(A,S2),I),
			 S=S2.
				      
% 13. can't go to objects in other rooms 
-occurs(go_to(A, S), I) :- holds(location(A, Loc1), I),
                           holds(location(S, Loc2), I),
                           Loc1 != Loc2.

% 14. can't put objects on surfaces in other rooms
-occurs(put_down(A, O, S), I) :- holds(location(A, Loc1), I),
                              holds(location(S, Loc2), I),
                              Loc1 != Loc2, #object(S).

% 15. can't pick up objects in other rooms
-occurs(pick_up(A, O), I) :- holds(location(A, Loc1), I),
                             holds(location(O, Loc2), I),
                             Loc1 != Loc2.
% 16. can't go to agents
-occurs(go_to(A,S),I) :- #agent(S).

% 17. can't pick up objects larger than oneself
%-occurs(pick_up(A,O),I) :- height(A,H), height(O,HO), HO>=H.				                         
                           
%% ------------------------------
%% Exec. conditions + affordances
%% ------------------------------                   
%&%& E.c.:
% 1. 
-occurs(A, I) :- affordance_forbids(A, I, ID).
-occurs(go_to(A,S),I) :- not holds(can_support(S,A),I).

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
% put_down impossible if target surface cannot support the obj. + 
% target surface is out of agents' reach. 
-occurs(put_down(A, O, S), I) :- not affordance_permits(put_down(A, O, S), I, 12), 
                                not affordance_permits(put_down(A, O, S), I, 13).
                                                      
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
-occurs(go_through(A, E, L), I) :- not affordance_permits(go_through(A, E, L), I, 17), 
                                   not affordance_permits(go_through(A, E, L), I, 18), 
                                   not affordance_permits(go_through(A, E, L), I, 19).
                                   
% 8.
% Alternative to 7 and 9. go_through impossible, unless a surface 
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
                                   %not affordance_permits(go_through(A, E, L), I, 19).
                             
%% AFFORDANCE AXIOMS END



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
occurs(A,I) :+ #action(A).

% do not allow concurrent actions
-occurs(A2, I) :- occurs(A1, I),
   		  A1!=A2.

% forbid agents from procrastinating
something_happened(I) :- occurs(A,I).

:- not something_happened(I),
   not goal(I),
   something_happened(I+1).

plan_length(I) :- not goal(I-1), goal(I).

%% ------------------------------------------------------------
%%                   Affordance Relations
%% ------------------------------------------------------------
%&%& A.R.:
% 1. 
% ID #10 
affordance_permits(pick_up(A, O), I, 10) :- has_power(A, strong).

% 2. 
% Aff. permits picking up objects, if they are in the agents reach.
affordance_permits(pick_up(A, O), I, 11) :- height(A, H), height(O, HO), 
                                            holds(in_range(O, A, X), I),
                                            X < H,
                                            X >=0.


% 3.
% Aff. permits moving objects, if the target surface supports them.
affordance_permits(put_down(A, O, S), I, 12) :- holds(can_support(S, O), I).

% 4. 
% Aff. permits moving objects, if the target surface is within range of agents' reach (assumed to be the span of the agents body). 
affordance_permits(put_down(A, O, S), I, 13) :- holds(z_loc(S,Z),I), holds(z_loc(A,Z2),I), 
						in_range(S, A, X), I),
                                               height(A, H), #vertsz(X),
                                               X < H, 
                                               X >= 0.

% 5. 
%Aff. permits going to surfaces, if they're not too high for the agent.
affordance_permits(go_to(A, S), I, 14) :- holds(z_loc(S, Z), I), 
                                          holds(z_loc(A, Z2), I), 
                                          height(A, H), 
                                          Z2 - H = BASE, 
                                          Z <= BASE + 1. 

% 6. 
% Aff. permits going to surfaces, if they're not too low for the agent.
affordance_permits(go_to(A, S), I, 15) :- holds(z_loc(S, Z), I), 
                                          holds(z_loc(A, Z2), I),
                                          height(A, H),
                                          Z2 - H = BASE, 
                                          Z >= BASE - 1.

% 7. 
% Aff. permits going to surfaces, if they can support the agent.
affordance_permits(go_to(A, S), I, 16) :- has_surf(S,true).

% 8.
% (8 & 9) 
% Aff. permits going through an opening if there's a surface within 1 unit of the opening. 
affordance_permits(go_through(A, Opening, L), I, 17) :- holds(in_range(Opening, S, X), I), 
                                                        has_surf(S, true),
                                                        X<=1, 0<=X. 

affordance_permits(go_through(A, Opening, L), I, 18) :- holds(in_range(S, Opening, X), I), X>0,
							holds(z_loc(Opening,Z),I), holds(z_loc(S,ZS),I), holds(on(A,S),I), 
height(A,H), Z-ZS>=H.
                                                        has_surf(S,
 true),
                                                        X<=1, 0<=X. 

% 10. Aff. permits going through openings that the agent can fit through.
affordance_permits(go_through(A, E, L), I, 19) :- height(A, H), 
                                                  height(E, H_exit),
                                                  H <= H_exit.

% 11.
% ID #26 Aff. permits going through openings that are within agents' movement range (assumed to be equal to agents' height).
affordance_permits(go_through(A, D, L), I, 26) :- holds(on(A, S), I),
                                                  height(A, HA),
                                                  height(D, HD),
                                                  height(S, HS),
                                                  holds(in_range(D, S, X), I), 
                                                  HS + HA > X,
                                                  HS < X + HD.
                                                  %affordance_permits(go_to(A, S), I, 16)                                    

%&%& A.R. end

%%------------------
%% Initial Condition
%%------------------

has_exit(room, door).
has_exit(corridor, door).
%has_exit(corridor, window).
%has_exit(foyer, window).

has_surf(box1, true).
has_surf(box2, true).
has_surf(box3, true).
has_surf(box4, true).
has_surf(box5, true).
has_surf(box6, true).
has_surf(floor, true).
has_surf(cup, false).
has_surf(door, false).

material(box1, paper).
material(box2, wood).
material(box3, wood).
material(box4, wood).
material(box5, wood).
material(floor, wood).
material(box6,wood).
material(cup, glass).
has_power(robot, strong). 

has_weight(box1, light).
has_weight(box2, medium).
has_weight(box3, medium).
has_weight(box4, heavy).
has_weight(box5, medium).
has_weight(box6, light).
has_weight(robot, heavy). 
has_weight(cup, light).

height(box1, 1). 
height(box2, 1). 
height(box3, 1).
height(box4, 3).
height(box5, 2).
height(box6, 2).
height(cup, 1).
height(floor, 0).
height(door, 3).
height(robot, 3).

holds(on(box1,floor),0). 
holds(on(box2,floor),0). 
holds(on(box3,floor),0).
holds(on(box4,floor),0). 
holds(on(box5,floor),0).
holds(on(box6,floor),0).
holds(on(robot,floor),0).
holds(on(cup, box5), 0).

holds(z_loc(floor,0),0).
holds(z_loc(door,6),0).
holds(z_loc(box4,3),0).
holds(z_loc(box1,1),0).
holds(z_loc(box2,1),0).
holds(z_loc(box3,1),0).
holds(z_loc(box5,2),0).
holds(z_loc(box6,2),0).
%&%& Received initial condition:

holds(location(robot, room),0).
holds(location(box1, room), 0).
holds(location(box2, room), 0).
holds(location(box3, room), 0).
holds(location(box6, room), 0).
holds(location(box4, room), 0).
holds(location(box5, corridor), 0).
holds(location(cup, corridor), 0).

%&%& End of starting state

% Goals:
%goal(I) :- holds(z_loc(robot, 6), I).
%goal(I) :- holds(z_loc(box2, 3), I).
%goal(I) :- holds(location(robot, corridor), I).
%goal(I) :- holds(on(box3, box1), I).
goal(I) :- holds(on(robot, box4), I).
% Execution Goal%
%goal(I) :- holds(in_hand(robot, box5), I).
%goal(I) :- holds(in_hand(robot, cup), I).

display

plan_length.
goal.
occurs.
%affordance_permits. 
%holds.



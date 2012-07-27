% ############ Primitive control actions ############

primitive_action(action_moveForward(Robot,T)).
primitive_action(action_turnLeft(Robot,T)).
primitive_action(action_turnRight(Robot,T)).
primitive_action(action_stop(Robot,T)).

%primitive_action(action_pickUp(Robot,Garbage,T)).
%primitive_action(action_drop(Robot,Garbage,T)).

% ############ Preconditions for primitive actions ############

poss(action_moveForward(Robot,T), S).
poss(action_turnLeft(Robot,T), S).
poss(action_turnRight(Robot,T), S).
poss(action_stop(Robot,T), S).

%poss(action_pickUp(Robot,T), S) :- robot_movement_stopped(Robot, S).
%poss(action_drop(Robot,T), S) :- robot_movement_stopped(Robot, S).
		
% ############ Successor state axioms ############

robot_movement_forward(Robot, do(A,S)) :- A = action_moveForward(Robot,T).
											
robot_movement_turning_left(Robot, do(A,S)) :- A = action_turnLeft(Robot,T).
											
robot_movement_turning_right(Robot, do(A,S)) :- A = action_turnRight(Robot,T).
											
robot_movement_stopped(Robot, do(A,S)) :- A = action_stop(Robot,T).

% stepwise turning
robot_heading(Robot, T, NewHeading, do(A,S)) :- A = action_Stop(Robot,T), OldHeading is NewHeading, robot_heading(Robot, T, OldHeading, S);
												A = action_moveForward(Robot,T), OldHeading is NewHeading, robot_heading(Robot, T, OldHeading, S);
												A = action_turnLeft(Robot,T), OldHeading is mod((NewHeading + 1), 4), robot_heading(Robot, T, OldHeading, S); % TODO: 1 -> DeltaTime
												A = action_turnRight(Robot,T), OldHeading is mod((NewHeading - 1), 4), robot_heading(Robot, T, OldHeading, S).

% continuous turning
% robot_heading_acc(Robot, T, Heading, S) :- last_action_time(LastActionTime, S), robot_heading_acc(Robot, LastTime, Heading, S).									
%robot_heading_acc_old(Robot, T, NewHeading, do(A,S)) :- 
													% in case the robot was moving forward
													%robot_movement_forward(Robot,S), last_action_time(LastActionTime, S), robot_heading_acc(Robot, LastActionTime, NewHeading, S);
%													robot_movement_forward(Robot,S);
													% robot was stopped
													%robot_movement_stopped(Robot,S), last_action_time(LastActionTime, S), robot_heading_acc(Robot, LastActionTime, NewHeading, S);
%													robot_movement_stopped(Robot,S);
													% robot is turning left
%													robot_movement_turning_left(Robot, S),
%													last_action_time(LastActionTime, S), % TODO: if other actions than movement can occur, this is no more correct
%													DeltaTime is (T - LastActionTime),
%													OldHeading is mod((NewHeading + DeltaTime), 4),
%													robot_heading_acc_old(Robot, LastActionTime, OldHeading, S);
													% robot is turning right
%													robot_movement_turning_right(Robot, S),
%													last_action_time(LastActionTime, S), % TODO: if other actions than movement can occur, this is no more correct
%													DeltaTime is (T - LastActionTime),
%													OldHeading is mod((NewHeading - DeltaTime), 4),
%													robot_heading_acc_old(Robot, LastActionTime, OldHeading, S).
													
robot_heading_acc(Robot, T, Heading, do(A,S)) :- last_action_time(PT, do(A,S)), PreviousTime is PT,
													robot_heading_acc(Robot, PreviousTime, PreviousHeading, do(A,S)),
													(
														robot_movement_turning_left(Robot, do(A,S)), turn_left_for_duration(PreviousHeading, T - PreviousTime, NewHeading), Heading is NewHeading;
														robot_movement_turning_right(Robot, do(A,S)), turn_right_for_duration(PreviousHeading, T - PreviousTime, NewHeading), Heading is NewHeading;
														(
															robot_movement_forward(Robot, do(A,S));
															robot_movement_stopped(Robot, do(A,S))
														), Heading is PreviousHeading
													).

% TODO: if other actions than movement can occur, this has to be refactored to be used with robot_heading_acc												
last_action_time(T, do(A,S)) :- time(A, ActionTime), (ActionTime = T), T is ActionTime. 
	
% ############ The time of an action occurrence is its last argument ############

time(action_moveForward(Robot,T),T).
time(action_turnLeft(Robot,T),T).
time(action_turnRight(Robot,T),T).
time(action_stop(Robot,T),T).

%time(action_pickUp(Robot,Garbage,T),T).
%time(action_drop(Robot,Garbage,T),T).

% ############ Restore situation arguments to fluents. ############

%restoreSitArg(location_of(Object),S,location_of(Object,S)).
%restoreSitArg(battery_level(Robot,T),S,battery_level(Robot,T,S)).

restoreSitArg(robot_heading(Robot,T,Heading),S,robot_heading(Robot,T,Heading,S)).
%restoreSitArg(robot_heading_acc_old(Robot,T,Heading),S,robot_heading_acc_old(Robot,T,Heading,S)).
restoreSitArg(robot_heading_acc(Robot,T,Heading),S,robot_heading_acc(Robot,T,Heading,S)).

restoreSitArg(robot_movement_forward(Robot),S,robot_movement_forward(Robot,S)).
restoreSitArg(robot_movement_turning_left(Robot),S,robot_movement_turning_left(Robot,S)).
restoreSitArg(robot_movement_turning_right(Robot),S,robot_movement_turning_right(Robot,S)).
restoreSitArg(robot_movement_stopped(Robot),S,robot_movement_stopped(Robot,S)).

%restoreSitArg(robot_loaded(Robot,Garbage),S,robot_loaded(Robot,Garbage,S)).

restoreSitArg(last_action_time(T), S, last_action_time(T, S)).

% ############ Auxiliary definititions  ############

turn_left_for_duration(StartHeading, Duration, EndHeading) :- EndHeading is mod((StartHeading - Duration), 4).
turn_right_for_duration(StartHeading, Duration, EndHeading) :- EndHeading is mod((StartHeading + Duration), 4).

% ############ Initial situation ############

robot_movement_stopped(r,s0).
robot_heading(r,0,0,s0).
robot_heading_acc(r,0,0,s0).
last_action_time(0,s0).
start(s0,0).

% ############ Utilities ############

prettyPrintSituation(S) :- makeActionList(S,Alist), nl, write(Alist), nl. 
 
makeActionList(s0,[]).
makeActionList(do(A,S), L) :- makeActionList(S,L1), append(L1, [A], L).

move_1 :- do(action_moveForward(r,1),s0,S), prettyPrintSituation(S).

holds_init_0 :- holds(robot_movement_stopped(r), s0), holds(robot_heading_acc(r,0,0), s0).
holds_init_1 :- holds(robot_movement_stopped(r), s0), holds(robot_heading_acc(r,0,0), s0), holds(robot_movement_forward(r), s0).  % false
holds_init_2 :- holds(robot_heading_acc(r,0,0), s0).
holds_init_3 :- holds(robot_heading_acc(r,0,1), s0).

holds_action_time_0 :- holds(last_action_time(0),  do(action_turnRight(r,0),s0)).
holds_action_time_1 :- holds(last_action_time(1),  do(action_turnRight(r,0),s0)). % false
holds_action_time_2 :- holds(last_action_time(1),  do(action_turnRight(r,1),s0)).
holds_action_time_3 :- holds(last_action_time(0),  do(action_turnRight(r,1),s0)). % false

holds_heading_0 :- holds(robot_heading(r,0,3), do(action_turnRight(r,0),s0)). % false
holds_heading_1 :- holds(robot_heading(r,0,1), do(action_turnRight(r,0),s0)).
holds_heading_2 :- holds(robot_heading(r,0,0), do(action_moveForward(r,0),s0)).
holds_heading_3 :- holds(robot_heading(r,0,1), do(action_moveForward(r,0),s0)). % false
holds_heading_4 :- holds(robot_heading(r,0,3), do(action_turnLeft(r,0),s0)).
holds_heading_5 :- holds(robot_heading(r,0,1), do(action_turnLeft(r,0),s0)). % false
holds_heading_6 :- holds(robot_heading(r,0,0), do(action_turnLeft(r,0),s0)). % false
holds_heading_7 :- holds(robot_heading(r,0,2), do(action_turnLeft(r,0),do(action_turnLeft(r,0),s0))).
holds_heading_8 :- holds(robot_heading(r,0,0), do(action_turnLeft(r,0),do(action_turnLeft(r,0),do(action_turnLeft(r,0),do(action_turnLeft(r,0),s0))))).

holds_heading_acc_0 :- holds(robot_heading_acc(r,0,0), s0).
holds_heading_acc_1 :- holds(robot_heading_acc(r,0,1), s0). % false
holds_heading_acc_2 :- holds(robot_heading_acc(r,2,3), do(action_turnLeft(r,1),s0)).
holds_heading_acc_3 :- holds(robot_heading_acc(r,3,2), do(action_turnLeft(r,1),s0)).
holds_heading_acc_4 :- holds(robot_heading_acc(r,4,1), do(action_turnLeft(r,1),s0)).
holds_heading_acc_5 :- holds(robot_heading_acc(r,5,0), do(action_turnLeft(r,1),s0)).
holds_heading_acc_6 :- holds(robot_heading_acc(r,1,1), do(action_turnRight(r,0),s0)).
holds_heading_acc_7 :- holds(robot_heading_acc(r,2,2), do(action_turnRight(r,0),s0)).
holds_heading_acc_8 :- holds(robot_heading_acc(r,3,3), do(action_turnRight(r,0),s0)).
holds_heading_acc_9 :- holds(robot_heading_acc(r,4,0), do(action_turnRight(r,0),s0)).
holds_heading_acc_10 :- holds(robot_heading_acc(r,4,0), do(action_stop(r, 2), s0)).
holds_heading_acc_11 :- holds(robot_heading_acc(r,3,2), do(action_stop(r,2), do(action_turnLeft(r,0), s0))).
holds_heading_acc_12 :- holds(robot_heading_acc(r,4,2), do(action_stop(r,2), do(action_turnLeft(r,0), s0))).
holds_heading_acc_13 :- holds(robot_heading_acc(r,4,3), do(action_turnRight(r,3), do(action_stop(r,2), do(action_turnLeft(r,0), s0)))).
holds_heading_acc_14 :- holds(robot_heading_acc(r,5,0), do(action_turnRight(r,3), do(action_stop(r,2), do(action_turnLeft(r,0), s0)))).
% TODO: these don't work yet
holds_heading_acc_15 :- holds(robot_heading_acc(r,1,0), s0). % should be true
holds_heading_acc_16 :- holds(robot_heading_acc(r,7,3), do(action_turnRight(r,3), do(action_stop(r,2), do(action_turnLeft(r,0), s0)))). % should be false


holds_1 :- holds(robot_movement_forward(r), do(action_moveForward(r,1), s0)).
holds_2 :- holds(robot_movement_forward(r), do(action_turnLeft(r,1), s0)). % false
holds_3 :- holds(robot_movement_turning_left(r), do(action_turnLeft(r,0), s0)).
holds_4 :- do(action_moveForward(r,1),s0,S), prettyPrintSituation(S), holds(robot_movement_forward(r), S).
holds_5 :- holds(robot_movement_turning_left(r), do(action_turnLeft(r,1), do(action_moveForward(r,1), s0))).
holds_6 :- holds(robot_movement_forward(r), do(action_turnLeft(r,1), do(action_moveForward(r,1), s0))).
holds_7 :- do(action_turnLeft(r,1),s0,S), prettyPrintSituation(S), holds(robot_movement_turning_left(r), S).

% TODO: these don't work yet
holds_f_1 :- do(action_stop(r,1), do(action_moveForward(r,1), s0), S), holds(robot_movement_stopped(r), S). % should be true
holds_f_2 :- do(action_moveForward(r,2), do(action_moveForward(r,1), s0), S), holds(robot_movement_forward(r), S). % should be true

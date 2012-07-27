% Declare nature's choices.

choice(moveForward(Robot), Choice) :- Choice = moveForwardS(Robot) ; Choice = moveForwardF(Robot).
choice(turnLeft(Robot), Choice) :- Choice = turnLeftS(Robot) ; Choice = turnLeftF(Robot).
choice(turnRight(Robot), Choice) :- Choice = turnRightS(Robot) ; Choice = turnRightF(Robot).
choice(stop(Robot), Choice) :- Choice = stopS(Robot) ; Choice = stopF(Robot).

choice(pickUp(Robot, Item), Choice) :- Choice = pickUpS(Robot, Item) ; Choice = pickUpF(Robot, Item).
choice(drop(Robot, Item), Choice) :- Choice = dropS(Robot, Item) ; Choice = dropF(Robot, Item).

% Action precondition axioms.

poss(moveForwardS(Robot), Situation).
poss(moveForwardF(Robot), Situation).

poss(turnLeftS(Robot), Situation).
poss(turnLeftF(Robot), Situation).

poss(turnRightS(Robot), Situation).
poss(turnRightF(Robot), Situation).

poss(stopS(Robot), Situation).
poss(stopF(Robot), Situation).

poss(pickUpS(Robot, Item), Situation).
poss(pickUpF(Robot, Item), Situation).

poss(dropS(Robot, Item), Situation).
poss(dropF(Robot, Item), Situation).

% Successor state axioms.

% Heading is element of {north = 0, east = 1, south = 2, west = 3}.
robotHeading(Robot, Heading, do(Action, Situation)) :- Action = turnLeftS(Robot), robotHeading(Robot, OldHeading, Situation), Heading is mod(OldHeading - 1, 4)
													   ;
													   Action = turnRightS(Robot), robotHeading(Robot, OldHeading, Situation), Heading is mod(OldHeading + 1, 4)
													   ;
													   not((Action = turnLeftS(Robot);
																Action = turnRightS(Robot))),
																	robotHeading(Robot, Heading, Situation)
													   .

% X, Y are elements of [0, ...,9].
robotLocation(Robot, X, Y, do(Action, Situation)) :- 	Action = moveForwardS(Robot), robotLocation(Robot, OldX, OldY, Situation),
															(robotHeading(Robot, 0, Situation), (OldY > 0 -> Y is OldY - 1; Y is OldY), X is OldX;
																robotHeading(Robot, 1, Situation), (OldX < 9 -> X is OldX + 1; X is OldX), Y is OldY;
																robotHeading(Robot, 2, Situation), (OldY < 9 -> Y is OldY + 1; Y is OldY), X is OldX;
																robotHeading(Robot, 3, Situation), (OldX > 0 -> X is OldX - 1; X is OldX), Y is OldY)
													 	;
														not(Action = moveForwardS(Robot)),
															robotLocation(Robot, X, Y, Situation)
													 	.

itemLocation(Item, X, Y, do(Action, Situation)) :- 	not(robotItemLoad(Robot, Item, do(Action, Situation))),
														itemLocation(Item, X, Y, Situation)
													;
												 	robotItemLoad(Robot, Item, do(Action, Situation)),
												 		robotLocation(Robot, RobotX, RobotY, do(Action, Situation)),
												 		X is RobotX, Y is RobotY
												 	.

robotItemLoad(Robot, Item, do(Action, Situation)) :- 	robotItemLoad(Robot, Item, Situation),
															not(Action = dropS(Robot, Item))
														;
													 	not(robotItemLoad(Robot, Item, Situation)),
															Action = pickUpS(Robot, Item),
															robotLocation(Robot, X, Y, Situation),
															itemLocation(Item, X, Y, Situation)
														.

% Probabilities.

prob0(moveForwardS(Robot), moveForward(Robot), Situation, Probability) :- Probability = 0.9 .
prob0(moveForwardF(Robot), moveForward(Robot), Situation, Probability) :- Probability = 0.1 .

prob0(turnLeftS(Robot), turnLeft(Robot), Situation, Probability) :- Probability = 0.9 .
prob0(turnLeftF(Robot), turnLeft(Robot), Situation, Probability) :- Probability = 0.1 .

prob0(turnRightS(Robot), turnRight(Robot), Situation, Probability) :- Probability = 0.9 .
prob0(turnRightF(Robot), turnRight(Robot), Situation, Probability) :- Probability = 0.1 .

prob0(stopS(Robot), stop(Robot), Situation, Probability) :- Probability = 0.9 .
prob0(stopF(Robot), stop(Robot), Situation, Probability) :- Probability = 0.1 .

prob0(pickUpS(Robot, Item), pickUp(Robot, Item), Situation, Probability) :- Probability = 0.9 .
prob0(pickUpF(Robot, Item), pickUp(Robot, Item), Situation, Probability) :- Probability = 0.1 .

prob0(dropS(Robot, Item), drop(Robot, Item), Situation, Probability) :- Probability = 0.9 .
prob0(dropF(Robot, Item), drop(Robot, Item), Situation, Probability) :- Probability = 0.1 .

% Uncertain initial database.

init(S) :- S = s0.

% Initial Database #1
robotHeading(robot0, 0, s0).
robotHeading(robot1, 0, s0).
robotLocation(robot0, 0, 0, s0).
robotLocation(robot1, 9, 9, s0).
itemLocation(item0, 0, 0, s0).
itemLocation(item1, 8, 8, s0).

initProb(s0,P) :- P is 1 .

% Initial state value.

initValue(S, 0.0) :- init(S).

% Rewards and costs.

cost(moveForwardS(Robot), Situation, Cost) :- Cost = 0 .
cost(moveForwardF(Robot), Situation, Cost) :- Cost = 0 .

cost(turnLeftS(Robot), Situation, Cost) :- Cost = 0 .
cost(turnLeftF(Robot), Situation, Cost) :- Cost = 0 .

cost(turnRightS(Robot), Situation, Cost) :- Cost = 0 .
cost(turnRightF(Robot), Situation, Cost) :- Cost = 0 .

cost(stopS(Robot), Situation, Cost) :- Cost = 0 .
cost(stopF(Robot), Situation, Cost) :- Cost = 0 .

cost(pickUpS(Robot, Item), Situation, Cost) :- Cost = 0 .
cost(pickUpF(Robot, Item), Situation, Cost) :- Cost = 0 .

cost(dropS(Robot, Item), Situation, Cost) :- Cost = 0 .
cost(dropF(Robot, Item), Situation, Cost) :- Cost = 0 .

reward(moveForwardS(Robot), Situation, Reward) :- Reward = 0 .
reward(moveForwardF(Robot), Situation, Reward) :- Reward = 0 .

reward(turnLeftS(Robot), Situation, Reward) :- Reward = 0 .
reward(turnLeftF(Robot), Situation, Reward) :- Reward = 0 .

reward(turnRightS(Robot), Situation, Reward) :- Reward = 0 .
reward(turnRightF(Robot), Situation, Reward) :- Reward = 0 .

reward(stopS(Robot), Situation, Reward) :- Reward = 0 .
reward(stopF(Robot), Situation, Reward) :- Reward = 0 .

reward(pickUpS(Robot, Item), Situation, Reward) :- Reward = 0 .
reward(pickUpF(Robot, Item), Situation, Reward) :- Reward = 0 .

reward(dropS(Robot, Item), Situation, Reward) :- Reward = 1, itemLocation(Item, 1, 0, Situation) ; Reward = 0 .
reward(dropF(Robot, Item), Situation, Reward) :- Reward = 0 .

% Golog implementation stuff.

restoreSitArg(robotHeading(Robot, Heading), Situation, robotHeading(Robot, Heading, Situation)).
restoreSitArg(robotLocation(Robot, X, Y), Situation, robotLocation(Robot, X, Y, Situation)).
restoreSitArg(itemLocation(Item, X, Y), Situation, itemLocation(Item, X, Y, Situation)).
restoreSitArg(robotItemLoad(Robot, Item), Situation, robotItemLoad(Robot, Item, Situation)).

% Test programs.

collect_0(Probability, Situation) :-  stDo(moveForward(robot0) : nil, Probability, s0, Situation).
collect_1(Probability, Situation) :-  stDo(moveForward(robot0) : turnLeft(robot0) : moveForward(robot1) : stop(robot0) : stop(robot1) : nil, Probability, s0, Situation).

% test robotHeading
holds_one_robot_3(Probability, Situation) :- stDo(turnLeft(robot0) : nil, Probability, s0, Situation),
									holds(robotHeading(robot0, 3, Situation), Situation).
holds_one_robot_4(Probability, Situation) :- stDo(turnLeft(robot0) : turnLeft(robot0) : moveForward(robot0) : turnRight(robot0) : nil, Probability, s0, Situation),
									holds(robotHeading(robot0, 3, Situation), Situation).
holds_one_robot_5(Probability, Situation) :- stDo(turnRight(robot0) : turnRight(robot0) : turnRight(robot0) : turnRight(robot0) : nil, Probability, s0, Situation),
									holds(robotHeading(robot0, 0, Situation), Situation).
holds_one_robot_6(Probability, Situation) :- stDo(turnRight(robot0) : turnRight(robot0) : turnRight(robot0) : turnRight(robot0) : nil, Probability, s0, Situation),
									holds((robotHeading(robot0, 0, Situation),
											not(robotHeading(robot0, 1, Situation)),
											not(robotHeading(robot0, 2, Situation)),
											not(robotHeading(robot0, 3, Situation))),
											Situation).

% test robotLocation
holds_one_robot_7(Probability, Situation) :- stDo(moveForward(robot0) : nil, Probability, s0, Situation),
												holds(robotHeading(robot0, 0, Situation), Situation),
												holds(robotLocation(robot0, 0, 0, Situation), Situation).
holds_one_robot_8(Probability, Situation) :- stDo(turnRight(robot0) : moveForward(robot0) : nil, Probability, s0, Situation),
												holds(robotHeading(robot0, 1, Situation), Situation),
												holds(robotLocation(robot0, 1, 0, Situation), Situation).
holds_one_robot_9(X, Y, Heading, Probability, Situation) :- stDo(turnRight(robot0) : turnRight(robot0) : moveForward(robot0) : nil, Probability, s0, Situation),
												holds(robotHeading(robot0, Heading, Situation), Situation),
												holds(robotLocation(robot0, X, Y, Situation), Situation).

% test robotItemLoad
holds_one_robot_10(Probability, Situation) :- stDo(pickUp(robot0, item0) : drop(robot0, item0) : nil, Probability, s0, Situation),
												holds(robotItemLoad(robot0, item0, Situation), Situation).
holds_one_robot_11_0(Probability, Situation) :- stDo(turnRight(robot0) : moveForward(robot0) : turnLeft(robot0) : turnLeft(robot0) : moveForward(robot0) : nil, Probability, s0, Situation),
												holds(robotLocation(robot0, 0, 0, Situation), Situation).
holds_one_robot_11_1(Probability, Situation) :- stDo(turnRight(robot0) : moveForward(robot0) : turnLeft(robot0) : turnLeft(robot0) : moveForward(robot0) : pickUp(robot0, item0) : nil, Probability, s0, Situation),
												holds(robotItemLoad(robot0, item0, Situation), Situation).
holds_one_robot_12(Probability, Situation) :- stDo(pickUp(robot0, item0) : turnRight(robot0) : moveForward(robot0) : drop(robot0, item0) : nil, Probability, s0, Situation),
												holds(not(robotItemLoad(robot0, item0, Situation)), Situation),
												holds(not(itemLocation(item0, 0, 0, Situation)), Situation),
												holds(itemLocation(item0, 1, 0, Situation), Situation).

% test multiple robots
holds_two_robots_0(X, Y, Probability, Situation) :- stDo(moveForward(robot1) : nil, Probability, s0, Situation),
													holds(robotLocation(robot0, X, Y, Situation), Situation).
holds_two_robots_0_1(X, Y, Probability, Situation) :- stDo(moveForward(robot1) : nil, Probability, s0, Situation),
													holds(robotLocation(robot1, X, Y, Situation), Situation).
holds_two_robots_1(X, Y, Probability, Situation) :- stDo(moveForward(robot0) : moveForward(robot1) : nil, Probability, s0, Situation),
													holds(robotLocation(robot1, X, Y, Situation), Situation).
holds_two_robots_2(X, Y, Probability, Situation) :- stDo(moveForward(robot0) :
															moveForward(robot1) :
															nil,
															Probability, s0, Situation),
													holds(robotLocation(robot1, X, Y, Situation), Situation).
two_robots_hardcore(Probability, Situation) :- 	stDo(pickUp(robot0, item0) :		% robot0 picks up item0
																moveForward(robot1) : 			% robot1 is on 9,8
																turnRight(robot0) :				% robot0 heads east
																moveForward(robot0) :			% robot0 is on 1,0
																turnLeft(robot1) :				% robot1 heads west
																moveForward(robot1) :			% robot1 is on 8,8
																pickUp(robot1, item1) :			% robot1 picks up item1 (on 8,8)
																drop(robot0, item0) :			% robot0 drops item0 (on 1,0)
																nil,
																Probability, s0, Situation).
holds_two_robots_hardcore(Probability, Situation) :- 	stDo(pickUp(robot0, item0) :		% robot0 picks up item0
																moveForward(robot1) : 			% robot1 is on 9,8
																turnRight(robot0) :				% robot0 heads east
																moveForward(robot0) :			% robot0 is on 1,0
																turnLeft(robot1) :				% robot1 heads west
																moveForward(robot1) :			% robot1 is on 8,8
																pickUp(robot1, item1) :			% robot1 picks up item1 (on 8,8)
																drop(robot0, item0) :			% robot0 drops item0 (on 1,0)
																nil,
																Probability, s0, Situation),
															holds(robotLocation(robot0, 1, 0, Situation), Situation),
															holds(robotLocation(robot1, 8, 8, Situation), Situation),
															holds(not(robotItemLoad(robot0, item0, Situation)), Situation),
															holds(not(robotItemLoad(robot0, item1, Situation)), Situation),
															holds(not(robotItemLoad(robot1, item0, Situation)), Situation),
															holds(robotItemLoad(robot1, item1, Situation), Situation)
															.
holds_two_robots_hardcore_with_item_loc(Probability, Situation) :- 	stDo(pickUp(robot0, item0) :		% robot0 picks up item0
																		moveForward(robot1) : 			% robot1 is on 9,8
																		turnRight(robot0) :				% robot0 heads east
																		moveForward(robot0) :			% robot0 is on 1,0
																		turnLeft(robot1) :				% robot1 heads west
																		moveForward(robot1) :			% robot1 is on 8,8
																		pickUp(robot1, item1) :			% robot1 picks up item1 (on 8,8)
																		drop(robot0, item0) :			% robot0 drops item0 (on 1,0)
																		nil,
																		Probability, s0, Situation),
																	holds(robotLocation(robot0, 1, 0, Situation), Situation),
																	holds(robotLocation(robot1, 8, 8, Situation), Situation),
																	holds(not(robotItemLoad(robot0, item0, Situation)), Situation),
																	holds(not(robotItemLoad(robot0, item1, Situation)), Situation),
																	holds(not(robotItemLoad(robot1, item0, Situation)), Situation),
																	holds(robotItemLoad(robot1, item1, Situation), Situation),
																	holds(itemLocation(item0, 1, 0, Situation), Situation),
																	holds(itemLocation(item1, 8, 8, Situation), Situation)
																	.
									
% TODO: Compute this assertion in reasonable time.		
getSituationSize(do(Action, Situation), Size) :- getSituationSize(Situation, OldSize), Size is OldSize + 1.
getSituationSize(s0, 0). 					
assertion_0(Prog) :- once(stDo(Prog, Probability, s0, Situation)),
							holds(getSituationSize(Situation, 1), Situation),
							holds(robotHeading(robot0, 1, Situation), Situation).

% test probabilities

prob_0(P) :- probF(itemLocation(item0, 1, 0)
					,
					pickUp(robot0, item0) :		% robot0 picks up item0
					moveForward(robot1) : 		% robot1 is on 9,8
					turnRight(robot0) :			% robot0 heads east
					moveForward(robot0) :		% robot0 is on 1,0
					turnLeft(robot1) :			% robot1 heads west
					moveForward(robot1) :		% robot1 is on 8,8
					pickUp(robot1, item1) :		% robot1 picks up item1 (on 8,8)
					drop(robot0, item0)			% robot0 drops item0 (on 1,0)
					,
					P).
					
prob_1(P) :- probF(itemLocation(item0, 1, 0)
					,
					pickUp(robot0, item0) :		% robot0 picks up item0
					turnRight(robot0) :			% robot0 heads east
					moveForward(robot0)	:		% robot0 is on 1,0
					drop(robot0, item0)			% robot0 drops item0 (on 1,0)
					,
					P).
					
prob_2(P) :- probF(robotLocation(robot0, X, Y) <=> itemLocation(item0, X, Y)
					,
					pickUp(robot0, item0) :		% robot0 picks up item0
					turnRight(robot0) :			% robot0 heads east
					moveForward(robot0)	:		% robot0 is on 1,0
					drop(robot0, item0)	:		% robot0 drops item0 (on 1,0)
					moveForward(robot0)			% robot0 is on 2,0
					,
					P).

% test values

evalue_0(V) :- eValue(pickUp(robot0, item0) :		% robot0 picks up item0
						moveForward(robot1) : 		% robot1 is on 9,8
						turnRight(robot0) :			% robot0 heads east
						moveForward(robot0) :		% robot0 is on 1,0
						turnLeft(robot1) :			% robot1 heads west
						moveForward(robot1) :		% robot1 is on 8,8
						pickUp(robot1, item1) :		% robot1 picks up item1 (on 8,8)
						drop(robot0, item0)			% robot0 drops item0 (on 1,0)
						,
						V).
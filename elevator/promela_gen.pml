#define ELEV_ACCEL 1;
#define ELEV_MAX_SPEED 5;
#define ELEV_DOWN_COORD 100;

bool on_top_floor;
bool on_bot_floor; 
bool top_call;
bool bot_call;
bool up_call;
bool down_call;
bool top_door_closed;
bool bot_door_closed;
bool top_call_LED;
bool bot_call_LED;
bool up_call_LED;
bool down_call_LED;
bool up;
bool down;
short v;
short coord;
int time_Motion = -1;

mtype: FunStates = {Begin, up_down, check_ON_OFF, check_command, check_stop, motion, error, stop};
mtype : FunStates state_Elevator = stop; 
mtype : FunStates state_top_call_Latch = stop;
mtype : FunStates state_bot_call_Latch = stop;
mtype : FunStates state_up_call_Latch = stop;
mtype : FunStates state_down_call_Latch = stop;
mtype : FunStates state_Motion = stop; 
mtype : FunStates state_go_down = stop;
mtype : FunStates state_go_up = stop;
mtype : process = { Environment_n, Elevator_n, 
					top_call_Latch_n, bot_call_Latch_n,
					up_call_Latch_n, down_call_Latch_n,
					Motion_p_n, go_down_n, go_up_n}; 
chan turn = [ 1 ] of { mtype : process} 
proctype Environment() { 
	do
	::	turn ? Environment_n;		
		atomic{
		if 
			:: top_call = true;
			:: top_call = false;
			:: bot_call = true;
			:: bot_call = false;
			:: up_call = true;
			:: up_call = false;
			:: down_call = true;
			:: down_call = false;
			:: top_door_closed = true;
			:: top_door_closed = false;
			:: bot_door_closed = true;
			:: bot_door_closed = false;
			:: else -> skip;
		fi;
		if 
			:: ( time_Motion > -1 ) -> time_Motion++;
			:: else -> skip;
		fi;
		}
		turn ! Elevator_n;
	od;
	}

proctype Elevator() { 
	do
	::	turn ? Elevator_n;		
		atomic{
		if 
			:: state_Elevator == Begin -> 	
				v = 0;
				coord = 0;
				state_Elevator = up_down;				
				
			::	state_Elevator == up_down 	
				if 
					:: up -> {
                        v = v - ELEV_ACCEL;
                        } 
					:: down -> {
                        v = v + ELEV_ACCEL;
                        }
					:: else -> v = 0;
				fi
				if 
					:: v > ELEV_MAX_SPEED -> {
                        v = ELEV_MAX_SPEED;
                        }
					:: v < -ELEV_MAX_SPEED -> {
                        v = -ELEV_MAX_SPEED;
                        }
					:: else -> skip;
				fi
				coord = coord + v;
				if 
					:: (coord < 0) -> {
                        coord = 0;
                        }
					:: coord > ELEV_DOWN_COORD -> {
                        coord = ELEV_DOWN_COORD;
                        }
					:: else -> skip;
				fi
				on_top_floor = false; 
				on_bot_floor = false;
				if 
					:: (coord < 5)  ->	{
                        on_top_floor = true;
                        }
					:: (coord > 95) ->	{
                        on_bot_floor = true;
                        }
					:: else -> skip;
				fi
				
			:: 	else -> skip;
		fi;
		}
		turn ! top_call_Latch_n;
	od;
	}

proctype top_call_Latch() { 
	bool prev_in;
	bool prev_out;
		
	do
	::	turn ? top_call_Latch_n;		
		atomic{
		if
			:: 	state_top_call_Latch == Begin -> 	
					prev_in = !top_call;
					prev_out = !top_door_closed;
					state_top_call_Latch = check_ON_OFF;				
				
			::	state_top_call_Latch == check_ON_OFF -> 
					if 
						:: (top_call && !prev_in) -> top_call_LED = true;
						:: else -> skip;
					fi;
					if 
						:: (!top_door_closed && prev_out) -> top_call_LED = false;
						:: else -> skip;
					fi;				
					prev_in = top_call;
					prev_out = top_door_closed;
				
			:: 	else -> skip;
		fi;
		}
		turn ! bot_call_Latch_n;
	od;
	}
	
proctype bot_call_Latch() {
	bool prev_in;
	bool prev_out;
		
	do
	::	turn ? bot_call_Latch_n;		
		atomic{
		if
			:: 	state_bot_call_Latch == Begin -> {	
					prev_in = !bot_call;
					prev_out = !bot_door_closed;
					state_bot_call_Latch = check_ON_OFF;				
				}
			::	state_bot_call_Latch == check_ON_OFF -> {	
					if 
						:: (bot_call && !prev_in) -> {
                            bot_call_LED = true;
                            }
						:: else -> skip;
					fi;
					if 
						:: (!bot_door_closed && prev_out) -> {
                            bot_call_LED = false; 
                        } 
						:: else -> skip;
					fi;				
					prev_in = bot_call;
					prev_out = bot_door_closed;
				}
			:: 	else -> skip;
		fi;
		}
		turn ! up_call_Latch_n;
	od;
	}	

proctype up_call_Latch() { 
	bool prev_in;
	bool prev_out;
		
	do
	::	turn ? up_call_Latch_n;		
		atomic{
		if
			:: 	state_up_call_Latch == Begin -> {	
					prev_in = !up_call;
					prev_out = !top_door_closed;
					state_up_call_Latch = check_ON_OFF; 				
				}
			::	state_up_call_Latch == check_ON_OFF -> {	
					if 
						:: (up_call && !prev_in) -> {
                            up_call_LED = true;
                            }
						:: else -> skip;
					fi;
					if 
						:: (!top_door_closed && prev_out) -> {
                            up_call_LED = false;
                            }
						:: else -> skip;
					fi;				
					prev_in = up_call;
					prev_out = top_door_closed;
				}
			:: 	else -> skip; 
		fi;
		}
		turn ! down_call_Latch_n;
	od;
	}	

proctype down_call_Latch() {
	bool prev_in;
	bool prev_out;
		
	do
	::	turn ? down_call_Latch_n;		
		atomic{
		if
			:: 	state_down_call_Latch == Begin -> {	
					prev_in = !down_call;
					prev_out = !bot_door_closed;
					state_down_call_Latch = check_ON_OFF;			
				}
			::	state_down_call_Latch == check_ON_OFF -> {	
					if 
						:: (down_call && !prev_in) -> {
                            down_call_LED = true;
                            }
						:: else -> skip;
					fi;
					if 
						:: (!bot_door_closed && prev_out) -> {
                            down_call_LED = false;
                            } 
						:: else -> skip;
					fi;				
					prev_in = down_call;
					prev_out = bot_door_closed;
				}
			:: 	else -> skip;
		fi;
		}
		turn ! Motion_p_n;
	od;
	}	

proctype Motion_p() {
		
	do
	::	turn ? Motion_p_n;		
		atomic{
		if
			:: state_Motion == check_command -> 	
				if 
				:: (bot_call_LED) ->{
					state_go_down = motion;
					state_Motion = check_stop;
					time_Motion = -1;
					}
				:: else -> 
					if 
					:: (top_call_LED) -> {
						state_go_up = motion;
						state_Motion = check_stop;
						time_Motion = -1;
						}
					:: else -> 
						if 
						:: (down_call_LED) -> {
							state_go_down = motion;
							state_Motion = check_stop;
							time_Motion = -1;
							}
						:: else -> 
							if 
							:: (up_call_LED) -> {
								state_go_up = motion;
								state_Motion = check_stop;
								time_Motion = -1;
								}	
							:: else -> 
								if 
								:: (on_top_floor && time_Motion == -1) -> time_Motion = 0;
								:: (on_top_floor && time_Motion == 20) -> {
									state_go_down = motion;
									time_Motion = -1;
									state_Motion = check_stop;
									}
								:: else -> skip;														
								fi;
							fi;
						fi;
					fi;
				fi;
			:: state_Motion == check_stop -> 	
					if 
						:: ((state_go_down == stop) && (state_go_up == stop)) ->{
								state_Motion = check_command;
                        }
						:: else -> skip;
					fi;
					
			:: else -> skip;
		fi;
		}
		turn ! go_down_n;
	od;
	}
	
proctype go_down() { 
	do
	::	turn ? go_down_n;		
		atomic{
		if
			:: state_go_down == motion -> {
				if 
					:: (top_door_closed && bot_door_closed) ->{ 
                        down = true;
                    }
					:: else -> skip;
				fi
				if 
					:: (on_bot_floor) -> {
							down = false;
							state_go_down = stop;
						}
					:: else -> skip;
				fi
				}
			:: state_go_down == stop -> skip;
			:: else -> skip;
		fi;
		}
		turn ! go_up_n;
	od;
	}
	
proctype go_up() {
	do
	::	turn ? go_up_n;		
		atomic{
		if
			:: state_go_up == motion -> {
				if 
					:: (top_door_closed && bot_door_closed) -> {
                        up = true;
                    }
					:: else -> skip;
				fi
				if 
					:: (on_top_floor) -> {
							up = false;
							state_go_up = stop;
						}
					:: else -> skip;
				fi
				}
			:: state_go_up == stop -> skip;
			:: else -> skip;
		fi;
		}
		turn ! Environment_n;
	od;
	}

init {
    run Environment();
	run Elevator();
    state_Elevator = Begin; 
	run top_call_Latch();
    state_top_call_Latch = Begin;
	run bot_call_Latch();
    state_bot_call_Latch = Begin;	
	run up_call_Latch();
    state_up_call_Latch = Begin;
	run down_call_Latch();
    state_down_call_Latch = Begin;
	run Motion_p();
    state_Motion = check_command; 
	run go_down();
	run go_up();

	turn ! Environment_n;
	}
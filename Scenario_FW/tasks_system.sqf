JTF_completeTask = {
	params ["_taskName"];
	private _script = _this spawn {
		params ["_taskName"];
		waitUntil { _taskName call BIS_fnc_taskCompleted };
		sleep 8;
		[_taskName] call BIS_fnc_deleteTask;
	};
	_script
};

JTF_tasks = [];

JTF_taskChecker = [] spawn {
	while { true } do {
		{
			_x params ["_taskName","_taskDone","_succCond","_succParams","_failCond","_failedParams","_cancelCond","_cancelParams"];
			if ( !_taskDone ) then {
				if ( _succParams call _succCond ) then {
					_x set [1, true];
					[_taskName, "SUCCEEDED", true] call BIS_fnc_taskSetState;
				} else {
					if ( _failedParams call _failCond ) then {
						_x set [1, true];
						[_taskName, "FAILED", true] call BIS_fnc_taskSetState;
					} else {
						if ( _cancelParams call _cancelCond ) then {
							_x set [1, true];
							[_taskName, "CANCELED", true] call BIS_fnc_taskSetState;
						};
					};
				};
			};
		} forEach JTF_tasks;
	};
};

JTF_newTask = {
	params ["_owner","_title","_desc","_marker","_pos","_name","_succeed","_succParams","_fail","_failParams","_cancel","_cancelParams"];
	
	[_owner,_name,[_desc,_title,_marker],_pos, "ASSIGNED", 1] call BIS_fnc_taskCreate;
	
	JTF_tasks pushback [_name,false,_succeed,_succParams,_fail,_failParams,_cancel,_cancelParams];
	
	[_name] call JTF_completeTask
};

// MISSION LOGIC HERE

JTF_tasksLoop = [] spawn (compile preprocessFileLineNumbers "tasks.sqf");


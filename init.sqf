// функция обработки физики троса
ropePhysHandler = {
	params ["_cargo", "_vehicle", "_rope"];

	_vehicleSpeedCoeff = 0.75; // предел скорости в виде коэффицента от максималки 3/4

	while {!isNull(_rope)} do {
		// отключение тормоза двигателя
		_cargo disableBrakes true; 
		_cargo awake true;
		
		private _posBamVeh = _vehicle modelToWorld ([_vehicle, getPosATL _rope] call func_get_bamperPos);
		private _posBamCargo = _cargo modelToWorld ([_cargo, getPosATL _rope] call func_get_bamperPos);

		
		// направление относительно к переду или заду подцепили груз
		private _dirCargo = (_cargo modelToWorldVisual [0,0,0]) getDirVisual ((ropeEndPosition _rope) # 1);
		private _dir = (getPosATL _cargo) getDirVisual (getPosATL _vehicle);
		_dir = [_dir - _dirCargo, 360 - (_dirCargo - _dir)] select (_dir < _dirCargo);
		// направление независимо от стороны - правой или левой
		private _sideDir = ([abs (_dir - 180), abs (180 - _dir)] select (abs (180 - _dir) < 90));
		_sideDir = 180 - _sideDir;

		private _distance = _posBamVeh distance _posBamCargo;
		private _speedVeh = vectorMagnitude velocity _vehicle * 3.6;
		private _speedCargo = vectorMagnitude velocity _cargo * 3.6;
		private _massDiff = (getMass _vehicle / getMass _cargo);
		private _vehMaxSpeed = getNumber (configfile >> "CfgVehicles" >> typeOf _vehicle >> "maxSpeed");
		
		// ускорение/замедление техники
		if (
			_speedCargo > 0.1 && // если груз не стоит
			{vectorMagnitude ((surfaceNormal (getPosATL _vehicle)) vectorDiff (vectorUp _vehicle)) < 0.1 && // если тягач не перевернут
			{vectorMagnitude ((surfaceNormal (getPosATL _cargo)) vectorDiff (vectorUp _cargo)) < 0.1 // если груз не перевернут
		}}) then {
			private _k = speed _cargo / abs speed _cargo; // направление скорости груза
			private _m = [1, -1] select (abs (_dir - 180) < 90); // [вперёд, назад]

			if (
				_distance > (ropeLength _rope) && // если трос натянут
				{_speedVeh > 0.1 && // если тягач не стоит
				{_speedVeh < _vehMaxSpeed * _vehicleSpeedCoeff * _massDiff // если скорость не выше предела
			}}) then {
				private _boost = 800;
				private _impulse = -1 * (abs speed _vehicle - abs speed _cargo) / _massDiff; // отрицательный импульс от груза
				private _acceleration = 50 * _impulse + _boost;

				_acceleration = [0, _acceleration * _m,  abs _acceleration * -2];
				_acceleration = _vehicle vectorModelToWorldVisual _acceleration;
				_vehicle addForce [_acceleration, boundingCenter _vehicle];
			};

			private _deceleration = [0, -500 * _k,  -1000];
			_deceleration = _cargo vectorModelToWorldVisual _deceleration;
			_cargo addForce [_deceleration, boundingCenter _cargo];
		};

		// поворот техники
		private _sideDir = ([abs (_dir - 180), abs (180 - _dir)] select (abs (180 - _dir) < 90));
		_sideDir = 180 - _sideDir;
		if (
			_distance > (ropeLength _rope) &&
			{_speedVeh > 0.1 &&
			{_speedCargo > 0.1 &&
			{getPosATL _cargo # 2 < 1 && // если груз на земле
			{vectorMagnitude ((surfaceNormal (getPosATL _cargo)) vectorDiff (vectorUp _cargo)) < 0.1 // если груз не перевернут
		}}}}) then {
			private _k = [1, -1] select ((_dir - 180) > 0); // [вправо, влево]
			private _m = [1, -1] select (abs (_dir - 180) < 90); // [вперёд, назад]

			private _force = [_sideDir ^ 2, 30] select (_sideDir > 5);
			_force = [_force * _k * _m, 0, 0];
			_force = _cargo vectorModelToWorldVisual _force;
			_cargo addForce [_force, [0, 50 * _m, 0]];
		};

		// срыв тормоза колёс
		if (
			_distance > (ropeLength _rope) &&
			{_speedVeh > 0.1 &&
			{_speedCargo < 0.1 &&
			{vectorMagnitude ((surfaceNormal (getPosATL _cargo)) vectorDiff (vectorUp _cargo)) < 0.1
		}}}) then {
			private _k = [1, -1] select ((_dir - 180) > 0); // [вправо, влево]
			private _m = [1, -1] select (abs (_dir - 180) < 90); // [вперёд, назад]

			// [x,y,z] +x - право -x - лево +y - вперёд -y - назад
			private _force = [[0, 6000 * _m, -12000], [1000 * _k, 0,  0]] select (_sideDir >= 45 && {_sideDir < 135});
			_force = _cargo vectorModelToWorldVisual _force;
			_cargo addForce [_force, boundingCenter _cargo]; 
		};
		sleep 0.01;
	};
};

// функция получения относительных координат ближнего к игроку бампера
func_get_bamperPos = {
	params ["_vehicle", "_pos"];
	_bampers = [
		[
			"O_LSV_02_unarmed_F", // квилин без оружия
			"O_T_LSV_02_unarmed_F",
			"O_LSV_02_armed_F", // квилин с пулемётом
			"O_T_LSV_02_armed_F",
			"O_LSV_02_AT_F", // квилин ПТ
			"O_T_LSV_02_AT_F",
			[-0.166, 2.45, -0.55],
			[-0.166, -2.35, -0.85]
		],
		[
			"O_Truck_02_transport_F", // замак
			"O_T_Truck_02_transport_F",
			"I_E_Truck_02_transport_F",
			"I_Truck_02_transport_F",
			"C_Truck_02_transport_F",
			"C_IDAP_Truck_02_transport_F",
			"O_Truck_02_covered_F", // крытый замак
			"I_E_Truck_02_F",
			"I_Truck_02_covered_F",
			"O_T_Truck_02_F",
			"C_Truck_02_covered_F",
			"C_IDAP_Truck_02_F",
			[0, 3.8, -1.15],
			[0.03, -3.9, -1.15]
		],
		[
			"O_Truck_02_medical_F", // мед замак
			"O_T_Truck_02_Medical_F",
			"I_E_Truck_02_Medical_F",
			"I_Truck_02_medical_F",
			"O_Truck_02_fuel_F", // топливный замак
			"O_T_Truck_02_fuel_F",
			"I_E_Truck_02_fuel_F",
			"I_Truck_02_fuel_F",
			"C_Truck_02_fuel_F",
			"C_IDAP_Truck_02_water_F",
			[0, 3.8, -1.15],
			[0, -3.9, -1.15]
		],
		[
			"O_Truck_02_box_F", // тех замак
			"O_T_Truck_02_Box_F",
			"I_E_Truck_02_Box_F",
			"I_Truck_02_box_F",
			"C_Truck_02_box_F",
			"O_Truck_02_Ammo_F", // бк замак
			"O_T_Truck_02_Ammo_F",
			"I_E_Truck_02_Ammo_F",
			"I_Truck_02_ammo_F",
			[0, 3.8, -1.15],
			[0, -3.7, -1.15]
		],
		[
			"I_Truck_02_MRL_F", // арта замак
			"I_E_Truck_02_MRL_F",
			[0, 3.8, -1.5],
			[-0.05, -3.8, -1.5]
		],
		[
			"O_MRAP_02_F", // ифрит
			[0, 1.4, -1.45],
			[0, -4.6, -1.25]
		],
		[
			"O_APC_Wheeled_02_rcws_v2_F", // марид
			"O_T_APC_Wheeled_02_rcws_v2_ghex_F",
			[0.2, 1.2, -1.6],
			[0.2, -4.2, -1.5]
		],
		[
			"O_APC_Tracked_02_cannon_F", // камыш
			"O_T_APC_Tracked_02_cannon_ghex_F",
			"O_APC_Tracked_02_AA_F", // ЗСУ тигрис
			"O_T_APC_Tracked_02_AA_ghex_F",
			[0, 1.9, -1.6],
			[0, -4.6, -0.5]
		],
		[
			"O_MBT_02_cannon_F", // варсук
			"O_T_MBT_02_cannon_ghex_F",
			"O_MBT_04_cannon_F", // ангара
			"O_T_MBT_04_cannon_F",
			"O_MBT_04_command_F",
			"O_T_MBT_04_command_F",
			[0, 2, -1.4],
			[0, -4.6, -1.5]
		],
		[
			"O_MBT_02_arty_F", // арта сочор
			"O_T_MBT_02_arty_ghex_F",
			[0, 1.6, -1.9],
			[0, -4.8, -1.9]
		],
		[
			"B_MBT_01_mlrs_F", // арта мрлс нато
			"B_T_MBT_01_mlrs_F",
			[0.6, 2, -0.6],
			[0.6, -3.6, -0.7]
		],
		[
			"B_LSV_01_unarmed_F", // повлер
			"B_T_LSV_01_unarmed_F",
			"B_CTRG_LSV_01_light_F",
			"B_LSV_01_armed_F", // повлер с пулеметом
			"B_T_LSV_01_armed_F",
			[0, 2.1, -1.4],
			[0, -1.8, -1.4]
		],
		[
			"B_LSV_01_AT_F", // пт повлер
			"B_T_LSV_01_AT_F",
			[0, 2.1, -1],
			[0, -1.8, -1]
		],
		[
			"B_MRAP_01_F", // хантер
			"B_T_MRAP_01_F",
			[0, 1.5, -1.2],
			[0, -4.3, -1]
		],
		[ 
			"B_MRAP_01_hmg_F", // хантер с пулеметом
			"B_T_MRAP_01_hmg_F",
			"B_MRAP_01_gmg_F", // хантер с гп
			"B_T_MRAP_01_gmg_F",
			[0, 1.5, -1.7],
			[0, -4.25, -1.5]
		],
		[
			"B_APC_Wheeled_01_cannon_F", // маршал
			"B_T_APC_Wheeled_01_cannon_F",
			[0, 2.6, -1],
			[0, -4.1, -1.7]
		],
		[
			"B_APC_Tracked_01_CRV_F", // бобка
			"B_T_APC_Tracked_01_CRV_F",
			[0, 2.5, -1.3],
			[0, -4.1, 0.3]
		],
		[
			"B_APC_Tracked_01_rcws_F", // пантера
			"B_T_APC_Tracked_01_rcws_F",
			[0, 2.5, -1.3],
			[0,-3.8,-0.3]
		],
		[
			"B_APC_Tracked_01_AA_F", // ЗСУ - читах
			"B_T_APC_Tracked_01_AA_F",
			[0, 2.5, -1.5],
			[0,-3.8,-0.7]
		],
		[
			"B_AFV_Wheeled_01_cannon_F", // рино
			"B_AFV_Wheeled_01_up_cannon_F",
			"B_T_AFV_Wheeled_01_cannon_F",
			"B_T_AFV_Wheeled_01_up_cannon_F",
			[0, 2.55, -1.27],
			[0, -4.4, -1.27]
		],
		[
			"B_MBT_01_cannon_F", // сламер
			"B_T_MBT_01_cannon_F",
			"B_MBT_01_TUSK_F",
			"B_T_MBT_01_TUSK_F",
			[0, 2.5, -1.3],
			[0,-3.6,-1.35]
		],
		[
			"I_MRAP_03_F", // страйдер
			[0, 2.5, -0.6],
			[0, -2.6, -0.9]
		],
		[
			"I_MRAP_03_hmg_F", // страйдер - пулемёт
			"I_MRAP_03_gmg_F", // страйдер - гп
			[0, 2.5, -1.3],
			[0, -2.6, -1.6]
		],
		[
			"B_UGV_01_F", // БПА UGV
			"B_T_UGV_01_olive_F",
			"O_UGV_01_F",
			"O_T_UGV_01_ghex_F",
			"I_E_UGV_01_F",
			"I_UGV_01_F",
			"B_UGV_01_rcws_F", // БПА UGV - пулемёт
			"B_T_UGV_01_rcws_olive_F",
			"O_UGV_01_rcws_F",
			"O_T_UGV_01_rcws_ghex_F",
			"I_E_UGV_01_rcws_F",
			"I_UGV_01_rcws_F",
			[0.4, 1.9, -1.4],
			[0.4, -1.9, -1.4]
		],
		[
			"I_E_Offroad_01_F", // внедорожник
			"I_G_Offroad_01_F",
			"O_G_Offroad_01_F",
			"B_G_Offroad_01_F",
			"C_Offroad_01_F",
			"C_IDAP_Offroad_01_F",
			"B_GEN_Offroad_01_gen_F", // полицейский внедорожник
			[0, 2.6, -0.9],
			[0, -2.6, -0.9]
		],
		[
			"I_E_Offroad_01_covered_F", // крытый внедорожник
			"B_GEN_Offroad_01_covered_F", // полицейский крытый внедорожник
			[-0.03, 2.9, -1.05],
			[-0.03, -2.6, -1.05]
		],
		[
			"B_Quadbike_01_F", // квадроцикл
			"B_T_Quadbike_01_F",
			"B_G_Quadbike_01_F",
			"O_Quadbike_01_F",
			"O_T_Quadbike_01_ghex_F",
			"O_G_Quadbike_01_F",
			"I_E_Quadbike_01_F",
			"I_Quadbike_01_F",
			"I_G_Quadbike_01_F",
			"C_Quadbike_01_F",
			[0, 0.9, -0.9],
			[0, -1, -1.05]
		]
	];

	_bampersIndex = _bampers findIf {typeOf _vehicle in _x};
	_bampers = _bampers # _bampersIndex;

	_frontBam = _bampers # (count _bampers - 2);
	_backBam = _bampers # (count _bampers - 1);

	_frontBamPos = _vehicle modelToWorld _frontBam;
	_backBamPos = _vehicle modelToWorld _backBam;

	// относительная позиция ближайжего к игроку бампера
	_bamPos = [_frontBam, _backBam] select ((_pos distance _frontBamPos) > (_pos distance _backBamPos));
	_bamPos;
};

// функция обработки условий разрыва троса с игроком
ropePlayerHandler = {
	params ["_rope"];
	private _helperPlayer = player getVariable ["helperPlayer", objNull];
	private _vehicle = cursorObject;
	while {player getVariable ["ropeDeployed", true]} do {
		// условия потери троса
		if (
			isNull _rope ||
			{!alive player || 
			{vehicle player != player || 
			{(getPosATL player) distance (getPosATL _vehicle) > 10}}}
		) then {
			ropeDestroy _rope;
			_vehicle setVariable ["rope", objNull];
			player setVariable ["ropeDeployed", false];

			deleteVehicle _helperPlayer;
			player setVariable ["helperPlayer", objNull];
		};
		sleep 1;
	}
};
// функция обработки условий разрыва троса с техникой
ropeVehicleHandler = {
	params ["_cargo", "_vehicle", "_rope"];
	private _helperPlayer = player getVariable ["helperPlayer", objNull];
	while {alive _rope} do {
		// условия потери троса
		if (
			isNull _rope ||
			{ropeLength _rope < 10 ||
			{!alive _vehicle ||
			{!alive _cargo ||
			{(getPosATL _cargo) distance (getPosATL _vehicle) > 25
			}}}}
		) then {
			ropeDestroy _rope;
			_vehicle setVariable ["rope", objNull];
			player setVariable ["ropeDeployed", false];
			_vehicle setVariable ["rope", objNull];
			_cargo setVariable ["rope", objNull];
		};
		sleep 1;
	}
};
// функция проверки условий развертывания троса
canDeploy = {
	private _helperPlayer = player getVariable ["helperPlayer", objNull];
	private _vehicle = cursorObject;
	if (_vehicle isKindOf "Car" || {_vehicle isKindOf "Tank"}) then {
		vehicle player == player && // если игрок не в машине
		player distance _vehicle < 10 &&
		isNull(_helperPlayer) && // если у игрока нет троса
		isNull(_vehicle getVariable ["rope", objNull])
	};
};
// функция развертывания троса
deployRope =  {
	private _vehicle = cursorObject;
	private _vehBam = [_vehicle, getPosATL player] call func_get_bamperPos;

	private _helperPlayer = "Land_Can_V1_F" createVehicle [0,0,0]; 
	_helperPlayer hideObjectGlobal true; 
	_helperPlayer enableSimulationGlobal false;
	_helperPlayer attachTo [player, [0.01,0,0], "leftforearmroll"];
	player setVariable ["helperPlayer", _helperPlayer];

	private _rope = ropeCreate [_vehicle, _vehBam, _helperPlayer, [0, 0, 0], 10];

	[_rope] spawn ropePlayerHandler;

	player setVariable ["ropeDeployed", true];
	_vehicle setVariable ["rope", _rope];
};
// функция проверки условий прикрепления троса
canAttach = {
	private _helperPlayer = player getVariable ["helperPlayer", objNull];
	private _vehicle = ropeAttachedTo _helperPlayer;
	private _cargo = cursorObject;
	private _rope = _vehicle getVariable "rope";

	private _posBamVeh = _vehicle modelToWorld ([_vehicle, getPosATL _rope] call func_get_bamperPos);
	private _posBamCargo = _cargo modelToWorld ([_cargo, getPosATL _rope] call func_get_bamperPos);

	if (alive _cargo && _cargo isKindOf "Car") then {
		!isPlayer _cargo && // если не игрок
		_cargo != _vehicle && // если не к самому себе
		!isNull(_helperPlayer) && // если у игрока есть трос
		player getVariable ["ropeDeployed", false] && // если трос еще не прикреплён
		isNull(_cargo getVariable ["rope", objNull]) && // если у машины нет троса
		_posBamVeh distance _posBamCargo < 10 &&
		player distance _cargo < 10
	};
};
// функция прикрепления троса
attachRope = {
	private _helperPlayer = player getVariable "helperPlayer";
	private _cargo = cursorObject;
    private _vehicle = ropeAttachedTo _helperPlayer;
	private _rope = _vehicle getVariable "rope";

	ropeDestroy _rope;

	deleteVehicle _helperPlayer;
	player setVariable ["helperPlayer", objNull];

	_vehBam = [_vehicle, getPosATL player] call func_get_bamperPos;
	_cargoBam = [_cargo, getPosATL player] call func_get_bamperPos;

	_rope = ropeCreate [_vehicle, _vehBam, _cargo, _cargoBam, 10];

	_vehicle setVariable ["rope", _rope];
	_cargo setVariable ["rope", _rope];
	player setVariable ["ropeDeployed", false];

	[_cargo, _vehicle, _rope] spawn ropePhysHandler;
	[_cargo, _vehicle, _rope] spawn ropeVehicleHandler;
};
// функция проверки условий открепления троса
canDetach = {
	private _vehicle = cursorObject;

	// три проверки на игрока
	!isPlayer _vehicle && // for player
	((count ropeAttachedObjects _vehicle > 0) && {!isPlayer (ropeAttachedObjects _vehicle # 0)} || // for vehicle
	(count ropesAttachedTo _vehicle > 0) && {!isPlayer (ropesAttachedTo _vehicle # 0)}) && // for cargo
	!isNull(_vehicle getVariable ["rope", objNull]) && // если у машины есть трос
	!(player getVariable ["ropeDeployed", false]) && // если у игрока нет троса
	player distance _vehicle < 10
};
// функция открепления троса
detachRope = {
	private _vehicle = cursorObject;
	private _rope = _vehicle getVariable "rope";

	ropeDestroy _rope;
	private _vehBam = [_vehicle, getPosATL player] call func_get_bamperPos;

	private _helperPlayer = "Land_Can_V1_F" createVehicle [0,0,0]; 
	_helperPlayer hideObjectGlobal true; 
	_helperPlayer attachTo [player, [0,0.2,0.9]];
	player setVariable ["helperPlayer", _helperPlayer];
	
	_rope = ropeCreate [_vehicle, _vehBam, _helperPlayer, [0, 0, 0], 10];
	_vehicle setVariable ["rope", _rope];
	player setVariable ["ropeDeployed", true];
	[_rope] spawn ropePlayerHandler;
};
// функция проверки удаления троса
canRemove = {
	private _vehicle = cursorObject;

	!isNull(_vehicle getVariable ["rope", objNull]) && // если у машины есть трос
	player getVariable ["ropeDeployed", false] && // если у игрока есть трос
	player distance _vehicle < 10
};
// функция удаления троса
removeRope = {
	private _helperPlayer = player getVariable "helperPlayer";
	private _cargo = cursorObject;
    private _vehicle = ropeAttachedTo _helperPlayer;
	private _rope = _vehicle getVariable "rope";

	ropeDestroy _rope;
	_vehicle setVariable ["rope", objNull];
	_cargo setVariable ["rope", objNull];
	player setVariable ["ropeDeployed", false];

	deleteVehicle _helperPlayer;
	player setVariable ["helperPlayer", objNull];
};
// функция добавления действий с тросом
addActions = {
    player addAction ["<t color='#4682B4'>Развернуть</t> трос", {
        [player] call deployRope;
    }, nil, 0, false, true, "", "call canDeploy"];

    player addAction ["<t color='#4682B4'>Прикрепить</t> трос", {
        [player] call attachRope;
    }, nil, 0, false, true, "", "call canAttach"];

	player addAction ["<t color='#4682B4'>Свернуть</t> трос", {
        [player] call detachRope;
    }, nil, 0, false, true, "", "call canDetach"];

	player addAction ["<t color='#4682B4'>Убрать</t> трос", {
        [player] call removeRope;
    }, nil, 0, false, true, "", "call canRemove"];

    player addEventHandler ["Respawn", {
        player setVariable ["ropeDeployed", false];
    }];
};
// вызов функции добавления действий
[] call addActions;

/* поиск точек бамперов техники
[] spawn {
_helperPlayer = "Land_Can_V1_F" createVehicle [0,0,0];  
_helperPlayer hideObjectGlobal true;  
_helperPlayer attachTo [player, [0,-0.1,0.9]];  
_rope = ropeCreate [cursorObject, [0, -1, -1.05], _helperPlayer, [0, 0, 0], 3];
sleep 3;
deleteVehicle _rope;
deleteVehicle _helperPlayer;
}
*/
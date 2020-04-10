
//// DIALOGS /////


class UnitOverviewDialog {
	idd = 6645;                    
	movingEnable = true;           
	enableSimulation = true;      
	controlsBackground[] = { };    // no background controls needed
	objects[] = { };               // no objects needed
	controls[] = { UnitFrame, UnitText, OOBText, StrengthText, AmmoText, MoraleText, ROETExt, BehaviourText, FormationText, ROE_Box, Formation_Box, Behavior_Box, OOB_Text, Strength_Text, Ammo_Text, Morale_Text }; 

	class UnitFrame: RscFrame
	{
		idc = 1800;
		moving = 1;
		x = 0.175;
		y = 0.2;
		w = 0.4375;
		h = 0.68;
		colorBackground[] = {0,0,0,1};
	};
	class UnitText: RscText
	{
		idc = 1000;
		text = "Unit Overview"; //--- ToDo: Localize;
		x = 0.2625;
		y = 0.22;
		w = 0.2125;
		h = 0.08;
		sizeEx = 1.6 * GUI_GRID_H;
	};
	class OOBText: RscText
	{
		idc = 1001;
		text = "OOB"; //--- ToDo: Localize;
		x = 0.2;
		y = 0.32;
		w = 0.0625;
		h = 0.04;
	};
	class StrengthText: RscText
	{
		idc = 1002;
		text = "Strength"; //--- ToDo: Localize;
		x = 0.2;
		y = 0.38;
		w = 0.0875;
		h = 0.04;
	};
	class AmmoText: RscText
	{
		idc = 1003;
		text = "Ammo"; //--- ToDo: Localize;
		x = 0.2;
		y = 0.44;
		w = 0.0875;
		h = 0.04;
	};
	class MoraleText: RscText
	{
		idc = 1004;
		text = "Morale"; //--- ToDo: Localize;
		x = 0.2;
		y = 0.5;
		w = 0.0875;
		h = 0.04;
	};
	class ROEText: RscText
	{
		idc = 1005;
		text = "ROE"; //--- ToDo: Localize;
		x = 0.2;
		y = 0.6;
		w = 0.0875;
		h = 0.04;
	};
	class BehaviourText: RscText
	{
		idc = 1006;
		text = "Behavior"; //--- ToDo: Localize;
		x = 0.2;
		y = 0.68;
		w = 0.0875;
		h = 0.04;
	};
	class FormationText: RscText
	{
		idc = 1007;
		text = "Formation"; //--- ToDo: Localize;
		x = 0.2;
		y = 0.76;
		w = 0.1125;
		h = 0.04;
	};
	class ROE_Box: RscListbox
	{
		idc = 1500;
		x = 0.325;
		y = 0.6;
		w = 0.2625;
		h = 0.04;
	};
	class Behavior_Box: RscListbox
	{
		idc = 1501;
		x = 0.325;
		y = 0.68;
		w = 0.2625;
		h = 0.04;
	};
	class Formation_Box: RscListbox
	{
		idc = 1502;
		x = 0.325;
		y = 0.76;
		w = 0.2625;
		h = 0.04;
	};
	class OOB_Text: RscText
	{
		idc = 1008;
		text = "oob_text"; //--- ToDo: Localize;
		x = 0.325;
		y = 0.32;
		w = 0.2625;
		h = 0.04;
		sizeEx = 0.7;
	};
	class Strength_Text: RscText
	{
		idc = 1009;
		text = "oob_text"; //--- ToDo: Localize;
		x = 0.325;
		y = 0.38;
		w = 0.2625;
		h = 0.04;
		sizeEx = 0.7;
	};
	class Ammo_Text: RscText
	{
		idc = 1010;
		text = "oob_text"; //--- ToDo: Localize;
		x = 0.325;
		y = 0.44;
		w = 0.2625;
		h = 0.04;
		sizeEx = 0.7;
	};
	class Morale_Text: RscText
	{
		idc = 1011;
		text = "oob_text"; //--- ToDo: Localize;
		x = 0.325;
		y = 0.5;
		w = 0.2625;
		h = 0.04;
		sizeEx = 0.7;
	};

}

/// Spectator

#define CT_MAP_MAIN 101
#define ST_PICTURE 48

class EGVAR(common,CompassControl);

class RscMapControl {
	access = 0;
	alphaFadeEndScale = 2;
	alphaFadeStartScale = 2;
	colorBackground[] = {0.929412,0.929412,0.929412,1};
	colorCountlines[] = {0.647059,0.533333,0.286275,1};
	colorCountlinesWater[] = {0.491,0.577,0.702,0.3};
	colorForest[] = {0.6,0.8,0.2,0.25};
	colorForestBorder[] = {0,0,0,0};
	colorGrid[] = {0.05,0.1,0,0.6};
	colorGridMap[] = {0.05,0.1,0,0.4};
	colorInactive[] = {1,1,1,0.5};
	colorLevels[] = {0,0,0,1};
	colorMainCountlines[] = {0.858824,0,0,1};
	colorMainCountlinesWater[] = {0.491,0.577,0.702,0.6};
	colorMainRoads[] = {0,0,0,1};
	colorMainRoadsFill[] = {0.94,0.69,0.2,1};
	colorNames[] = {0.1,0.1,0.1,0.9};
	colorOutside[] = {0.929412,0.929412,0.929412,1};
	colorPowerLines[] = {0.1,0.1,0.1,1};
	colorRailWay[] = {0.8,0.2,0,1};
	colorRoads[] = {0.2,0.13,0,1};
	colorRoadsFill[] = {1,0.88,0.65,1};
	colorRocks[] = {0.5,0.5,0.5,0.5};
	colorRocksBorder[] = {0,0,0,0};
	colorSea[] = {0.467,0.631,0.851,0.5};
	colorText[] = {0,0,0,1};
	colorTracks[] = {0.2,0.13,0,1};
	colorTracksFill[] = {1,0.88,0.65,0.3};
	colorTrails[] = {0.84,0.76,0.65,0.15};
	colorTrailsFill[] = {0.84,0.76,0.65,0.65};
	deletable = 0;
	fade = 0;
	font = "TahomaB";
	fontGrid = "TahomaB";
	fontInfo = "RobotoCondensed";
	fontLabel = "RobotoCondensed";
	fontLevel = "TahomaB";
	fontNames = "EtelkaNarrowMediumPro";
	fontUnits = "TahomaB";
	h = "SafeZoneH - 1.5 * 					(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
	idc = 51;
	idcMarkerColor = -1;
	idcMarkerIcon = -1;
	maxSatelliteAlpha = 0.5;
	moveOnEdges = 1;
	ptsPerSquareCLn = 10;
	ptsPerSquareCost = 10;
	ptsPerSquareExp = 10;
	ptsPerSquareFor = 9;
	ptsPerSquareForEdge = 9;
	ptsPerSquareObj = 9;
	ptsPerSquareRoad = 6;
	ptsPerSquareSea = 5;
	ptsPerSquareTxt = 20;
	scaleDefault = 0.16;
	scaleMax = 1;
	scaleMin = 0.001;
	shadow = 0;
	showCountourInterval = 1;
	showMarkers = 1;
	sizeEx = 0.04;
	sizeExGrid = 0.032;
	sizeExInfo = "(			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
	sizeExLabel = "(			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
	sizeExLevel = 0.03;
	sizeExNames = "(			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8) * 2";
	sizeExUnits = "(			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
	stickX[] = {0.2,["Gamma",1,1.5]};
	stickY[] = {0.2,["Gamma",1,1.5]};
	style = 48;
	text = "#(argb,8,8,3)color(1,1,1,1)";
	textureComboBoxColor = "#(argb,8,8,3)color(1,1,1,1)";
	type = 101;
	w = "SafeZoneWAbs";
	x = "SafeZoneXAbs";
	y = "SafeZoneY + 1.5 * 					(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
	
	class ActiveMarker {
		color[] = {0.3,0.1,0.9,1};
		size = 50;
	};
	class Bunker {
		coefMax = 4;
		coefMin = 0.25;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\bunker_ca.paa";
		importance = "1.5 * 14 * 0.05";
		size = 14;
	};
	class Bush {
		coefMax = 4;
		coefMin = 0.25;
		color[] = {0.45,0.64,0.33,0.4};
		icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
		importance = "0.2 * 14 * 0.05 * 0.05";
		size = "14/2";
	};
	class BusStop {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\busstop_CA.paa";
		importance = 1;
		size = 24;
	};
	class Chapel {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\Chapel_CA.paa";
		importance = 1;
		size = 24;
	};
	class Church {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\church_CA.paa";
		importance = 1;
		size = 24;
	};
	class Command {
		coefMax = 1;
		coefMin = 1;
		color[] = {1,1,1,1};
		icon = "\a3\ui_f\data\map\mapcontrol\waypoint_ca.paa";
		importance = 1;
		size = 18;
	};
	class Cross {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\Cross_CA.paa";
		importance = 1;
		size = 24æ
	};
	class CustomMark {
		coefMax = 1;
		coefMin = 1;
		color[] = {1,1,1,1};
		icon = "\a3\ui_f\data\map\mapcontrol\custommark_ca.paa";
		importance = 1;
		size = 18;
	};
	class Fortress {
		coefMax = 4;
		coefMin = 0.25;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\bunker_ca.paa";
		importance = "2 * 16 * 0.05";
		size = 16;
	};
	class Fountain {
		coefMax = 4;
		coefMin = 0.25;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\fountain_ca.paa";
		importance = "1 * 12 * 0.05";
		size = 11;
	};
	class Fuelstation {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\fuelstation_CA.paa";
		importance = 1;
		size = 24;
	};
	class Hospital {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\hospital_CA.paa";
		importance = 1;
		size = 24;
	};
	class Legend {
		color[] = {0,0,0,1};
		colorBackground[] = {1,1,1,0.5};
		font = "RobotoCondensed";
		h = "3.5 * 					(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
		sizeEx = "(			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
		w = "10 * 					(			((safezoneW / safezoneH) min 1.2) / 40)";
		x = "SafeZoneX + 					(			((safezoneW / safezoneH) min 1.2) / 40)";
		y = "SafeZoneY + safezoneH - 4.5 * 					(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
	};
	class Lighthouse {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\lighthouse_CA.paa";
		importance = 1;
		size = 24;
	};
	class LineMarker {
		lineDistanceMin = 3e-005;
		lineLengthMin = 5;
		lineWidthThick = 0.014;
		lineWidthThin = 0.008;
		textureComboBoxColor = "#(argb,8,8,3)color(1,1,1,1)";
	};
	class power {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\power_CA.paa";
		importance = 1;
		size = 24;
	};
	class powersolar {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\powersolar_CA.paa";
		importance = 1;
		size = 24;
	};
	class powerwave {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\powerwave_CA.paa";
		importance = 1;
		size = 24;
	};
	class powerwind {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\powerwind_CA.paa";
		importance = 1;
		size = 24;
	};
	class Quay {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\quay_CA.paa";
		importance = 1;
		size = 24;
	};
	class Rock {
		coefMax = 4;
		coefMin = 0.25;
		color[] = {0.1,0.1,0.1,0.8};
		icon = "\A3\ui_f\data\map\mapcontrol\rock_ca.paa";
		importance = "0.5 * 12 * 0.05";
		size = 12;
	};
	class Ruin {
		coefMax = 4;
		coefMin = 1;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\ruin_ca.paa";
		importance = "1.2 * 16 * 0.05";
		size = 16;
	};
	class Shipwreck {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\Shipwreck_CA.paa";
		importance = 1;
		size = 24;
	};
	class SmallTree {
		coefMax = 4;
		coefMin = 0.25;
		color[] = {0.45,0.64,0.33,0.4};
		icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
		importance = "0.6 * 12 * 0.05";
		size = 12;
	};
	class Stack {
		coefMax = 2;
		coefMin = 0.4;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\stack_ca.paa";
		importance = "2 * 16 * 0.05";
		size = 16;
	};
	class Task {
		coefMax = 1;
		coefMin = 1;
		color[] = {"(profilenamespace getvariable ['IGUI_TEXT_RGB_R',0])","(profilenamespace getvariable ['IGUI_TEXT_RGB_G',1])","(profilenamespace getvariable ['IGUI_TEXT_RGB_B',1])","(profilenamespace getvariable ['IGUI_TEXT_RGB_A',0.8])"};
		colorCanceled[] = {0.7,0.7,0.7,1};
		colorCreated[] = {1,1,1,1};
		colorDone[] = {0.7,1,0.3,1};
		colorFailed[] = {1,0.3,0.2,1};
		icon = "\A3\ui_f\data\map\mapcontrol\taskIcon_CA.paa";
		iconCanceled = "\A3\ui_f\data\map\mapcontrol\taskIconCanceled_CA.paa";
		iconCreated = "\A3\ui_f\data\map\mapcontrol\taskIconCreated_CA.paa";
		iconDone = "\A3\ui_f\data\map\mapcontrol\taskIconDone_CA.paa";
		iconFailed = "\A3\ui_f\data\map\mapcontrol\taskIconFailed_CA.paa";
		importance = 1;
		size = 27;
		taskAssigned = "#(argb,8,8,3)color(1,1,1,1)";
		taskCanceled = "#(argb,8,8,3)color(1,0.5,0,1)";
		taskCreated = "#(argb,8,8,3)color(0,0,0,1)";
		taskFailed = "#(argb,8,8,3)color(1,0,0,1)";
		taskNone = "#(argb,8,8,3)color(0,0,0,0)";
		taskSucceeded = "#(argb,8,8,3)color(0,1,0,1)";
	};
	class Tourism {
		coefMax = 4;
		coefMin = 0.7;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\tourism_ca.paa";
		importance = "1 * 16 * 0.05";
		size = 16;
	};
	class Transmitter {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\transmitter_CA.paa";
		importance = 1;
		size = 24;
	};
	class Tree {
		coefMax = 4;
		coefMin = 0.25;
		color[] = {0.45,0.64,0.33,0.4};
		icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
		importance = "0.9 * 16 * 0.05";
		size = 12;
	};
	class ViewTower {
		coefMax = 4;
		coefMin = 0.5;
		color[] = {0,0,0,1};
		icon = "\A3\ui_f\data\map\mapcontrol\viewtower_ca.paa";
		importance = "2.5 * 16 * 0.05";
		size = 16;
	};
	class Watertower {
		coefMax = 1;
		coefMin = 0.85;
		color[] = {1,1,1,1};
		icon = "\A3\ui_f\data\map\mapcontrol\watertower_CA.paa";
		importance = 1;
		size = 24;
	};
	class Waypoint {
		coefMax = 1;
		coefMin = 1;
		color[] = {1,1,1,1};
		icon = "\a3\ui_f\data\map\mapcontrol\waypoint_ca.paa";
		importance = 1;
		size = 18;
	};
	class WaypointCompleted {
		coefMax = 1;
		coefMin = 1;
		color[] = {1,1,1,1};
		icon = "\a3\ui_f\data\map\mapcontrol\waypointcompleted_ca.paa";
		importance = 1;
		size = 18;
	};
	
};



// Based on RscDisplayEGSpectator (sadly Arma doesn't like display inheritance)
class GVAR(displayMission) {
    idd = IDD_SPEC_DISPLAY;
    enableSimulation = 1;
    movingEnable = 0;
    closeOnMissionEnd = 1;

    onLoad = QUOTE(_this call FUNC(ui_handleLoad));

    onKeyDown = QUOTE(_this call RTS_fnc_handleKeyDown);
    onKeyUp = QUOTE(_this call RTS_fnc_ui_handleKeyUp);
 //   onMouseMoving = QUOTE(_this call FUNC(ui_handleMouseMoving));
    onChildDestroyed = QUOTE(_this call FUNC(ui_handleChildDestroyed));

    class ControlsBackground {
        class MouseHandler: RscText {
            idc = IDC_MOUSE;

            onMouseButtonDown = QUOTE(_this call RTS_fnc_ui_handleMouseButtonDown);
            onMouseButtonUp = QUOTE(_this call RTS_fnc_ui_handleMouseButtonUp);
            onMouseButtonDblClick = QUOTE(_this call RTS_fnc_ui_handleMouseButtonDblClick);
            onMouseZChanged = QUOTE(_this call FUNC(ui_handleMouseZChanged));

            text = "";
            x = "safeZoneXAbs";
            y = "safeZoneY";
            w = "safeZoneWAbs";
            h = "safeZoneH";
            colorBackground[] = {1,1,1,0};
            style = 16;
        };
    };
    class Controls {
        class Map: RscMapControl {
            idc = IDC_MAP;

            onDraw = QUOTE(_this call FUNC(ui_handleMapDraw));
            onMouseButtonClick = QUOTE(_this call RTS_fnc_ui_handleMapClick);

            x = safeZoneX;
            y = safeZoneY;
            w = safeZoneW;
            h = safeZoneH;

            maxSatelliteAlpha = 0.75;
            colorBackground[] = {1,1,1,1};
			colorOutside[] = {1,1,1,1};
        };
        class compass: EGVAR(common,CompassControl) {};
    };
};
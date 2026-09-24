--[[
	 __  __             _   _ ___
	|  \/  | __ _  ___ | | | |_ _|
	| |\/| |/ _` |/ __|| | | || |
	| |  | | (_| | (__ | |_| || |
	|_|  |_|\__,_|\___| \___/|___|

	MacUI — a macOS System Settings–style interface library for Roblox.

	Version : 4.0.0
	Author  : Kiwzu  (https://github.com/Kiwzu/Mac-OS-UI-LUA)
	Icons   : Lucide (ISC license) via the asset ids published with Fluent (MIT)

	The public API is a superset of the Fluent API, so most Fluent scripts
	work after swapping the loadstring. See README.md for the full reference.
]]

local MacUI = {
	Version = "4.0.0",
	Options = {},
	Windows = {},
	Unloaded = false,
	ThemeName = "Dark",
	Accent = Color3.fromRGB(10, 132, 255),
	FontFamily = "rbxasset://fonts/families/BuilderSans.json",
}
MacUI.Flags = MacUI.Options

do
	local ok, face = pcall(Font.fromEnum, Enum.Font.BuilderSans)
	if ok and face then
		MacUI.FontFamily = face.Family
	end
end

--------------------------------------------------------------------------------
-- Services & environment
--------------------------------------------------------------------------------

local cloneref = cloneref or function(object)
	return object
end

local function GetService(name)
	return cloneref(game:GetService(name))
end

local Players = GetService("Players")
local TweenService = GetService("TweenService")
local UserInputService = GetService("UserInputService")
local TextService = GetService("TextService")
local GuiService = GetService("GuiService")
local Workspace = GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local rgb = Color3.fromRGB

local function Viewport()
	local camera = Workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function ParentGui(gui)
	local protect = (syn and syn.protect_gui) or protectgui or protect_gui
	if type(protect) == "function" then
		pcall(protect, gui)
	end
	if type(gethui) == "function" then
		local ok, container = pcall(gethui)
		if ok and typeof(container) == "Instance" then
			gui.Parent = container
			return
		end
	end
	local ok = pcall(function()
		gui.Parent = GetService("CoreGui")
	end)
	if not ok then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

--------------------------------------------------------------------------------
-- Design tokens
--------------------------------------------------------------------------------

MacUI.Themes = {
	Dark = {
		Background = rgb(30, 30, 32),
		Sidebar = rgb(40, 40, 43),
		SidebarDivider = rgb(14, 14, 16),
		WindowStroke = rgb(74, 74, 79),
		Group = rgb(39, 39, 42),
		GroupStroke = rgb(51, 51, 55),
		Separator = rgb(53, 53, 57),
		Text = rgb(242, 242, 245),
		SubText = rgb(152, 152, 159),
		Tertiary = rgb(104, 104, 110),
		SelectionText = rgb(255, 255, 255),
		Control = rgb(68, 68, 73),
		ControlHover = rgb(82, 82, 88),
		ControlStroke = rgb(84, 84, 90),
		Button = rgb(72, 72, 77),
		ButtonHover = rgb(86, 86, 92),
		Field = rgb(28, 28, 30),
		FieldStroke = rgb(64, 64, 69),
		Search = rgb(50, 50, 54),
		SwitchOff = rgb(64, 64, 69),
		Knob = rgb(248, 248, 250),
		Track = rgb(62, 62, 67),
		SegmentBg = rgb(52, 52, 56),
		SegmentSelected = rgb(96, 96, 102),
		Hover = rgb(255, 255, 255),
		HoverTransparency = 0.94,
		Menu = rgb(42, 42, 45),
		MenuStroke = rgb(70, 70, 75),
		Scrollbar = rgb(122, 122, 128),
		Shadow = rgb(0, 0, 0),
		ShadowTransparency = 0.3,
		Dim = rgb(0, 0, 0),
		DimTransparency = 0.45,
		Destructive = rgb(255, 69, 58),
	},
	Light = {
		Background = rgb(243, 243, 246),
		Sidebar = rgb(230, 230, 234),
		SidebarDivider = rgb(208, 208, 213),
		WindowStroke = rgb(196, 196, 202),
		Group = rgb(255, 255, 255),
		GroupStroke = rgb(222, 222, 227),
		Separator = rgb(229, 229, 234),
		Text = rgb(28, 28, 30),
		SubText = rgb(110, 110, 116),
		Tertiary = rgb(160, 160, 166),
		SelectionText = rgb(255, 255, 255),
		Control = rgb(229, 229, 234),
		ControlHover = rgb(216, 216, 222),
		ControlStroke = rgb(206, 206, 212),
		Button = rgb(255, 255, 255),
		ButtonHover = rgb(246, 246, 248),
		Field = rgb(255, 255, 255),
		FieldStroke = rgb(206, 206, 212),
		Search = rgb(226, 226, 231),
		SwitchOff = rgb(221, 221, 226),
		Knob = rgb(255, 255, 255),
		Track = rgb(218, 218, 224),
		SegmentBg = rgb(226, 226, 231),
		SegmentSelected = rgb(255, 255, 255),
		Hover = rgb(0, 0, 0),
		HoverTransparency = 0.95,
		Menu = rgb(249, 249, 251),
		MenuStroke = rgb(206, 206, 212),
		Scrollbar = rgb(150, 150, 156),
		Shadow = rgb(0, 0, 0),
		ShadowTransparency = 0.55,
		Dim = rgb(0, 0, 0),
		DimTransparency = 0.7,
		Destructive = rgb(255, 59, 48),
	},
	Midnight = {
		Background = rgb(0, 0, 0),
		Sidebar = rgb(15, 15, 17),
		SidebarDivider = rgb(30, 30, 33),
		WindowStroke = rgb(52, 52, 56),
		Group = rgb(21, 21, 23),
		GroupStroke = rgb(35, 35, 39),
		Separator = rgb(37, 37, 41),
		Text = rgb(245, 245, 247),
		SubText = rgb(142, 142, 148),
		Tertiary = rgb(92, 92, 98),
		SelectionText = rgb(255, 255, 255),
		Control = rgb(50, 50, 54),
		ControlHover = rgb(63, 63, 68),
		ControlStroke = rgb(62, 62, 67),
		Button = rgb(54, 54, 58),
		ButtonHover = rgb(66, 66, 71),
		Field = rgb(10, 10, 11),
		FieldStroke = rgb(50, 50, 54),
		Search = rgb(28, 28, 31),
		SwitchOff = rgb(52, 52, 56),
		Knob = rgb(248, 248, 250),
		Track = rgb(46, 46, 50),
		SegmentBg = rgb(32, 32, 35),
		SegmentSelected = rgb(78, 78, 84),
		Hover = rgb(255, 255, 255),
		HoverTransparency = 0.94,
		Menu = rgb(26, 26, 28),
		MenuStroke = rgb(56, 56, 60),
		Scrollbar = rgb(110, 110, 116),
		Shadow = rgb(0, 0, 0),
		ShadowTransparency = 0.25,
		Dim = rgb(0, 0, 0),
		DimTransparency = 0.4,
		Destructive = rgb(255, 69, 58),
	},
}
MacUI.ThemeData = MacUI.Themes.Dark

-- The macOS accent colours (System Settings › Appearance)
MacUI.Accents = {
	Blue = rgb(10, 132, 255),
	Purple = rgb(191, 90, 242),
	Pink = rgb(255, 55, 95),
	Red = rgb(255, 69, 58),
	Orange = rgb(255, 159, 10),
	Yellow = rgb(255, 204, 0),
	Green = rgb(48, 209, 88),
	Graphite = rgb(142, 142, 147),
}
MacUI.AccentOrder = { "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Graphite" }

-- Colours used for the rounded icon tiles in the sidebar (System Settings style)
MacUI.TileColors = {
	rgb(10, 132, 255), -- blue
	rgb(191, 90, 242), -- purple
	rgb(255, 159, 10), -- orange
	rgb(48, 209, 88), -- green
	rgb(255, 55, 95), -- pink
	rgb(64, 200, 224), -- teal
	rgb(94, 92, 230), -- indigo
	rgb(255, 69, 58), -- red
	rgb(142, 142, 147), -- gray
	rgb(0, 199, 190), -- mint
	rgb(255, 204, 0), -- yellow
	rgb(172, 142, 104), -- brown
}

local TRAFFIC = {
	{ Name = "Close", Color = rgb(255, 95, 87), Stroke = rgb(224, 68, 62), Glyph = rgb(120, 10, 10) },
	{ Name = "Minimize", Color = rgb(254, 188, 46), Stroke = rgb(222, 161, 35), Glyph = rgb(140, 80, 0) },
	{ Name = "Zoom", Color = rgb(40, 200, 64), Stroke = rgb(26, 171, 41), Glyph = rgb(0, 90, 10) },
}

local SHADOW_IMAGE = "rbxassetid://6014261993"

--------------------------------------------------------------------------------
-- Icons (Lucide)
--------------------------------------------------------------------------------

local IconData = "accessibility=10709751939;activity=10709752035;air-vent=10709752131;airplay=10709752254;alarm-check=10709752405;alarm-clock=10709752630;alarm-clock-off=10709752508;alarm-minus=10709752732;alarm-plus=10709752825;album=10709752906;alert-circle=10709752996;alert-octagon=10709753064;alert-triangle=10709753149;align-center=10709753570;align-center-horizontal=10709753272;align-center-vertical=10709753421;align-end-horizontal=10709753692;align-end-vertical=10709753808;align-horizontal-distribute-center=10747779791;align-horizontal-distribute-end=10747784534;align-horizontal-distribute-start=10709754118;align-horizontal-justify-center=10709754204;align-horizontal-justify-end=10709754317;align-horizontal-justify-start=10709754436;align-horizontal-space-around=10709754590;align-horizontal-space-between=10709754749;align-justify=10709759610;align-left=10709759764;align-right=10709759895;align-start-horizontal=10709760051;align-start-vertical=10709760244;align-vertical-distribute-center=10709760351;align-vertical-distribute-end=10709760434;align-vertical-distribute-start=10709760612;align-vertical-justify-center=10709760814;align-vertical-justify-end=10709761003;align-vertical-justify-start=10709761176;align-vertical-space-around=10709761324;align-vertical-space-between=10709761434;anchor=10709761530;angry=10709761629;annoyed=10709761722;aperture=10709761813;apple=10709761889;archive=10709762233;archive-restore=10709762058;armchair=10709762327;arrow-big-down=10747796644;arrow-big-left=10709762574;arrow-big-right=10709762727;arrow-big-up=10709762879;arrow-down=10709767827;arrow-down-circle=10709763034;arrow-down-left=10709767656;arrow-down-right=10709767750;arrow-left=10709768114;arrow-left-circle=10709767936;arrow-left-right=10709768019;arrow-right=10709768347;arrow-right-circle=10709768226;arrow-up=10709768939;arrow-up-circle=10709768432;arrow-up-down=10709768538;arrow-up-left=10709768661;arrow-up-right=10709768787;asterisk=10709769095;at-sign=10709769286;award=10709769406;axe=10709769508;axis-3d=10709769598;baby=10709769732;backpack=10709769841;baggage-claim=10709769935;banana=10709770005;banknote=10709770178;bar-chart=10709773755;bar-chart-2=10709770317;bar-chart-3=10709770431;bar-chart-4=10709770560;bar-chart-horizontal=10709773669;barcode=10747360675;baseline=10709773863;bath=10709773963;battery=10709774640;battery-charging=10709774068;battery-full=10709774206;battery-low=10709774370;battery-medium=10709774513;beaker=10709774756;bed=10709775036;bed-double=10709774864;bed-single=10709774968;beer=10709775167;bell=10709775704;bell-minus=10709775241;bell-off=10709775320;bell-plus=10709775448;bell-ring=10709775560;bike=10709775894;binary=10709776050;bitcoin=10709776126;bluetooth=10709776655;bluetooth-connected=10709776240;bluetooth-off=10709776344;bluetooth-searching=10709776501;bold=10747813908;bomb=10709781460;bone=10709781605;book=10709781824;book-open=10709781717;bookmark=10709782154;bookmark-minus=10709781919;bookmark-plus=10709782044;bot=10709782230;box=10709782497;box-select=10709782342;boxes=10709782582;briefcase=10709782662;brush=10709782758;bug=10709782845;building=10709783051;building-2=10709782939;bus=10709783137;cake=10709783217;calculator=10709783311;calendar=10709789505;calendar-check=10709783474;calendar-check-2=10709783392;calendar-clock=10709783577;calendar-days=10709783673;calendar-heart=10709783835;calendar-minus=10709783959;calendar-off=10709788784;calendar-plus=10709788937;calendar-range=10709789053;calendar-search=10709789200;calendar-x=10709789407;calendar-x-2=10709789329;camera=10709789686;camera-off=10747822677;car=10709789810;carrot=10709789960;cast=10709790097;charge=10709790202;check=10709790644;check-circle=10709790387;check-circle-2=10709790298;check-square=10709790537;chef-hat=10709790757;cherry=10709790875;chevron-down=10709790948;chevron-first=10709791015;chevron-last=10709791130;chevron-left=10709791281;chevron-right=10709791437;chevron-up=10709791523;chevrons-down=10709796864;chevrons-down-up=10709791632;chevrons-left=10709797151;chevrons-left-right=10709797006;chevrons-right=10709797382;chevrons-right-left=10709797274;chevrons-up=10709797622;chevrons-up-down=10709797508;chrome=10709797725;circle=10709798174;circle-dot=10709797837;circle-ellipsis=10709797985;circle-slashed=10709798100;citrus=10709798276;clapperboard=10709798350;clipboard=10709799288;clipboard-check=10709798443;clipboard-copy=10709798574;clipboard-edit=10709798682;clipboard-list=10709798792;clipboard-signature=10709798890;clipboard-type=10709798999;clipboard-x=10709799124;clock=10709805144;clock-1=10709799535;clock-10=10709799718;clock-11=10709799818;clock-12=10709799962;clock-2=10709803876;clock-3=10709803989;clock-4=10709804164;clock-5=10709804291;clock-6=10709804435;clock-7=10709804599;clock-8=10709804784;clock-9=10709804996;cloud=10709806740;cloud-cog=10709805262;cloud-drizzle=10709805371;cloud-fog=10709805477;cloud-hail=10709805596;cloud-lightning=10709805727;cloud-moon=10709805942;cloud-moon-rain=10709805838;cloud-off=10709806060;cloud-rain=10709806277;cloud-rain-wind=10709806166;cloud-snow=10709806374;cloud-sun=10709806631;cloud-sun-rain=10709806475;cloudy=10709806859;clover=10709806995;code=10709810463;code-2=10709807111;codepen=10709810534;codesandbox=10709810676;coffee=10709810814;cog=10709810948;coins=10709811110;columns=10709811261;command=10709811365;compass=10709811445;component=10709811595;concierge-bell=10709811706;connection=10747361219;contact=10709811834;contrast=10709811939;cookie=10709812067;copy=10709812159;copyleft=10709812251;copyright=10709812311;corner-down-left=10709812396;corner-down-right=10709812485;corner-left-down=10709812632;corner-left-up=10709812784;corner-right-down=10709812939;corner-right-up=10709813094;corner-up-left=10709813185;corner-up-right=10709813281;cpu=10709813383;croissant=10709818125;crop=10709818245;cross=10709818399;crosshair=10709818534;crown=10709818626;cup-soda=10709818763;curly-braces=10709818847;currency=10709818931;database=10709818996;delete=10709819059;diamond=10709819149;dice-1=10709819266;dice-2=10709819361;dice-3=10709819508;dice-4=10709819670;dice-5=10709819801;dice-6=10709819896;dices=10723343321;diff=10723343416;disc=10723343537;divide=10723343805;divide-circle=10723343636;divide-square=10723343737;dollar-sign=10723343958;download=10723344270;download-cloud=10723344088;droplet=10723344432;droplets=10734883356;drumstick=10723344737;edit=10734883598;edit-2=10723344885;edit-3=10723345088;egg=10723345518;egg-fried=10723345347;electricity=10723345749;electricity-off=10723345643;equal=10723345990;equal-not=10723345866;eraser=10723346158;euro=10723346372;expand=10723346553;external-link=10723346684;eye=10723346959;eye-off=10723346871;factory=10723347051;fan=10723354359;fast-forward=10723354521;feather=10723354671;figma=10723354801;file=10723374641;file-archive=10723354921;file-audio=10723355148;file-audio-2=10723355026;file-axis-3d=10723355272;file-badge=10723355622;file-badge-2=10723355451;file-bar-chart=10723355887;file-bar-chart-2=10723355746;file-box=10723355989;file-check=10723356210;file-check-2=10723356100;file-clock=10723356329;file-code=10723356507;file-cog=10723356830;file-cog-2=10723356676;file-diff=10723357039;file-digit=10723357151;file-down=10723357322;file-edit=10723357495;file-heart=10723357637;file-image=10723357790;file-input=10723357933;file-json=10723364435;file-json-2=10723364361;file-key=10723364605;file-key-2=10723364515;file-line-chart=10723364725;file-lock=10723364957;file-lock-2=10723364861;file-minus=10723365254;file-minus-2=10723365086;file-output=10723365457;file-pie-chart=10723365598;file-plus=10723365877;file-plus-2=10723365766;file-question=10723365987;file-scan=10723366167;file-search=10723366550;file-search-2=10723366340;file-signature=10723366741;file-spreadsheet=10723366962;file-symlink=10723367098;file-terminal=10723367244;file-text=10723367380;file-type=10723367606;file-type-2=10723367509;file-up=10723367734;file-video=10723373884;file-video-2=10723367834;file-volume=10723374172;file-volume-2=10723374030;file-warning=10723374276;file-x=10723374544;file-x-2=10723374378;files=10723374759;film=10723374981;filter=10723375128;fingerprint=10723375250;flag=10723375890;flag-off=10723375443;flag-triangle-left=10723375608;flag-triangle-right=10723375727;flame=10723376114;flashlight=10723376471;flashlight-off=10723376365;flask-conical=10734883986;flask-round=10723376614;flip-horizontal=10723376884;flip-horizontal-2=10723376745;flip-vertical=10723377138;flip-vertical-2=10723377026;flower=10747830374;flower-2=10723377305;focus=10723377537;folder=10723387563;folder-archive=10723384478;folder-check=10723384605;folder-clock=10723384731;folder-closed=10723384893;folder-cog=10723385213;folder-cog-2=10723385036;folder-down=10723385338;folder-edit=10723385445;folder-heart=10723385545;folder-input=10723385721;folder-key=10723385848;folder-lock=10723386005;folder-minus=10723386127;folder-open=10723386277;folder-output=10723386386;folder-plus=10723386531;folder-search=10723386787;folder-search-2=10723386674;folder-symlink=10723386930;folder-tree=10723387085;folder-up=10723387265;folder-x=10723387448;folders=10723387721;form-input=10723387841;forward=10723388016;frame=10723394389;framer=10723394565;frown=10723394681;fuel=10723394846;function-square=10723395041;gamepad=10723395457;gamepad-2=10723395215;gauge=10723395708;gavel=10723395896;gem=10723396000;ghost=10723396107;gift=10723396402;gift-card=10723396225;git-branch=10723396676;git-branch-plus=10723396542;git-commit=10723396812;git-compare=10723396954;git-fork=10723397049;git-merge=10723397165;git-pull-request=10723397431;git-pull-request-closed=10723397268;git-pull-request-draft=10734884302;glass=10723397788;glass-2=10723397529;glass-water=10723397678;glasses=10723397895;globe=10723404337;globe-2=10723398002;grab=10723404472;graduation-cap=10723404691;grape=10723404822;grid=10723404936;grip-horizontal=10723405089;grip-vertical=10723405236;hammer=10723405360;hand=10723405649;hand-metal=10723405508;hard-drive=10723405749;hard-hat=10723405859;hash=10723405975;haze=10723406078;headphones=10723406165;heart=10723406885;heart-crack=10723406299;heart-handshake=10723406480;heart-off=10723406662;heart-pulse=10723406795;help-circle=10723406988;hexagon=10723407092;highlighter=10723407192;history=10723407335;home=10723407389;hourglass=10723407498;ice-cream=10723414308;image=10723415040;image-minus=10723414487;image-off=10723414677;image-plus=10723414827;import=10723415205;inbox=10723415335;indent=10723415494;indian-rupee=10723415642;infinity=10723415766;info=10723415903;inspect=10723416057;italic=10723416195;japanese-yen=10723416363;joystick=10723416527;key=10723416652;keyboard=10723416765;lamp=10723417513;lamp-ceiling=10723416922;lamp-desk=10723417016;lamp-floor=10723417131;lamp-wall-down=10723417240;lamp-wall-up=10723417356;landmark=10723417608;languages=10723417703;laptop=10723423881;laptop-2=10723417797;lasso=10723424235;lasso-select=10723424058;laugh=10723424372;layers=10723424505;layout=10723425376;layout-dashboard=10723424646;layout-grid=10723424838;layout-list=10723424963;layout-template=10723425187;leaf=10723425539;library=10723425615;life-buoy=10723425685;lightbulb=10723425852;lightbulb-off=10723425762;line-chart=10723426393;link=10723426722;link-2=10723426595;link-2-off=10723426513;list=10723433811;list-checks=10734884548;list-end=10723426886;list-minus=10723426986;list-music=10723427081;list-ordered=10723427199;list-plus=10723427334;list-start=10723427494;list-video=10723427619;list-x=10723433655;loader=10723434070;loader-2=10723433935;locate=10723434557;locate-fixed=10723434236;locate-off=10723434379;lock=10723434711;log-in=10723434830;log-out=10723434906;luggage=10723434993;magnet=10723435069;mail=10734885430;mail-check=10723435182;mail-minus=10723435261;mail-open=10723435342;mail-plus=10723435443;mail-question=10723435515;mail-search=10734884739;mail-warning=10734885015;mail-x=10734885247;mails=10734885614;map=10734886202;map-pin=10734886004;map-pin-off=10734885803;maximize=10734886735;maximize-2=10734886496;medal=10734887072;megaphone=10734887454;megaphone-off=10734887311;meh=10734887603;menu=10734887784;message-circle=10734888000;message-square=10734888228;mic=10734888864;mic-2=10734888430;mic-off=10734888646;microscope=10734889106;microwave=10734895076;milestone=10734895310;minimize=10734895698;minimize-2=10734895530;minus=10734896206;minus-circle=10734895856;minus-square=10734896029;monitor=10734896881;monitor-off=10734896360;monitor-speaker=10734896512;moon=10734897102;more-horizontal=10734897250;more-vertical=10734897387;mountain=10734897956;mountain-snow=10734897665;mouse=10734898592;mouse-pointer=10734898476;mouse-pointer-2=10734898194;mouse-pointer-click=10734898355;move=10734900011;move-3d=10734898756;move-diagonal=10734899164;move-diagonal-2=10734898934;move-horizontal=10734899414;move-vertical=10734899821;music=10734905958;music-2=10734900215;music-3=10734905665;music-4=10734905823;navigation=10734906744;navigation-2=10734906332;navigation-2-off=10734906144;navigation-off=10734906580;network=10734906975;newspaper=10734907168;octagon=10734907361;option=10734907649;outdent=10734907933;package=10734909540;package-2=10734908151;package-check=10734908384;package-minus=10734908626;package-open=10734908793;package-plus=10734909016;package-search=10734909196;package-x=10734909375;paint-bucket=10734909847;paintbrush=10734910187;paintbrush-2=10734910030;palette=10734910430;palmtree=10734910680;paperclip=10734910927;party-popper=10734918735;pause=10734919336;pause-circle=10735024209;pause-octagon=10734919143;pen-tool=10734919503;pencil=10734919691;percent=10734919919;person-standing=10734920149;phone=10734921524;phone-call=10734920305;phone-forwarded=10734920508;phone-incoming=10734920694;phone-missed=10734920845;phone-off=10734921077;phone-outgoing=10734921288;pie-chart=10734921727;piggy-bank=10734921935;pin=10734922324;pin-off=10734922180;pipette=10734922497;pizza=10734922774;plane=10734922971;play=10734923549;play-circle=10734923214;plus=10734924532;plus-circle=10734923868;plus-square=10734924219;podcast=10734929553;pointer=10734929723;pound-sterling=10734929981;power=10734930466;power-off=10734930257;printer=10734930632;puzzle=10734930886;quote=10734931234;radio=10734931596;radio-receiver=10734931402;rectangle-horizontal=10734931777;rectangle-vertical=10734932081;recycle=10734932295;redo=10734932822;redo-2=10734932586;refresh-ccw=10734933056;refresh-cw=10734933222;refrigerator=10734933465;regex=10734933655;repeat=10734933966;repeat-1=10734933826;reply=10734934252;reply-all=10734934132;rewind=10734934347;rocket=10734934585;rocking-chair=10734939942;rotate-3d=10734940107;rotate-ccw=10734940376;rotate-cw=10734940654;rss=10734940825;ruler=10734941018;russian-ruble=10734941199;sailboat=10734941354;save=10734941499;scale=10734941912;scale-3d=10734941739;scaling=10734942072;scan=10734942565;scan-face=10734942198;scan-line=10734942351;scissors=10734942778;screen-share=10734943193;screen-share-off=10734942967;scroll=10734943448;search=10734943674;send=10734943902;separator-horizontal=10734944115;separator-vertical=10734944326;server=10734949856;server-cog=10734944444;server-crash=10734944554;server-off=10734944668;settings=10734950309;settings-2=10734950020;share=10734950813;share-2=10734950553;sheet=10734951038;shield=10734951847;shield-alert=10734951173;shield-check=10734951367;shield-close=10734951535;shield-off=10734951684;shirt=10734952036;shopping-bag=10734952273;shopping-cart=10734952479;shovel=10734952773;shower-head=10734952942;shrink=10734953073;shrub=10734953241;shuffle=10734953451;sidebar=10734954301;sidebar-close=10734953715;sidebar-open=10734954000;sigma=10734954538;signal=10734961133;signal-high=10734954807;signal-low=10734955080;signal-medium=10734955336;signal-zero=10734960878;siren=10734961284;skip-back=10734961526;skip-forward=10734961809;skull=10734962068;slack=10734962339;slash=10734962600;slice=10734963024;sliders=10734963400;sliders-horizontal=10734963191;smartphone=10734963940;smartphone-charging=10734963671;smile=10734964441;smile-plus=10734964188;snowflake=10734964600;sofa=10734964852;sort-asc=10734965115;sort-desc=10734965287;speaker=10734965419;sprout=10734965572;square=10734965702;star=10734966248;star-half=10734965897;star-off=10734966097;stethoscope=10734966384;sticker=10734972234;sticky-note=10734972463;stop-circle=10734972621;stretch-horizontal=10734972862;stretch-vertical=10734973130;strikethrough=10734973290;subscript=10734973457;sun=10734974297;sun-dim=10734973645;sun-medium=10734973778;sun-moon=10734973999;sun-snow=10734974130;sunrise=10734974522;sunset=10734974689;superscript=10734974850;swiss-franc=10734975024;switch-camera=10734975214;sword=10734975486;swords=10734975692;syringe=10734975932;table=10734976230;table-2=10734976097;tablet=10734976394;tag=10734976528;tags=10734976739;target=10734977012;tent=10734981750;terminal=10734982144;terminal-square=10734981995;text-cursor=10734982395;text-cursor-input=10734982297;thermometer=10734983134;thermometer-snowflake=10734982571;thermometer-sun=10734982771;thumbs-down=10734983359;thumbs-up=10734983629;ticket=10734983868;timer=10734984606;timer-off=10734984138;timer-reset=10734984355;toggle-left=10734984834;toggle-right=10734985040;tornado=10734985247;toy-brick=10747361919;train=10747362105;trash=10747362393;trash-2=10747362241;tree-deciduous=10747362534;tree-pine=10747362748;trees=10747363016;trending-down=10747363205;trending-up=10747363465;triangle=10747363621;trophy=10747363809;truck=10747364031;tv=10747364593;tv-2=10747364302;type=10747364761;umbrella=10747364971;underline=10747365191;undo=10747365484;undo-2=10747365359;unlink=10747365771;unlink-2=10747397871;unlock=10747366027;upload=10747366434;upload-cloud=10747366266;usb=10747366606;user=10747373176;user-check=10747371901;user-cog=10747372167;user-minus=10747372346;user-plus=10747372702;user-x=10747372992;users=10747373426;utensils=10747373821;utensils-crossed=10747373629;venetian-mask=10747374003;verified=10747374131;vibrate=10747374489;vibrate-off=10747374269;video=10747374938;video-off=10747374721;view=10747375132;voicemail=10747375281;volume=10747376008;volume-1=10747375450;volume-2=10747375679;volume-x=10747375880;wallet=10747376205;wand=10747376565;wand-2=10747376349;watch=10747376722;waves=10747376931;webcam=10747381992;wifi=10747382504;wifi-off=10747382268;wind=10747382750;wrap-text=10747383065;wrench=10747383470;x=10747384394;x-circle=10747383819;x-octagon=10747384037;x-square=10747384217;zoom-in=10747384552;zoom-out=10747384679"

local Icons = {}
for name, id in string.gmatch(IconData, "([%w%-]+)=(%d+)") do
	Icons[name] = "rbxassetid://" .. id
end
local IconAliases = {
	["panel-left"] = "sidebar",
	["store"] = "shopping-bag",
	["sparkles"] = "star",
	["user-circle"] = "user",
	["app-window"] = "layout",
}
MacUI.Icons = Icons

function MacUI:GetIcon(name)
	if name == nil or name == "" then
		return nil
	end
	if type(name) == "number" then
		return "rbxassetid://" .. name
	end
	name = tostring(name)
	if name:find("^rbxasset") or name:find("^https?://") then
		return name
	end
	if name:match("^%d+$") then
		return "rbxassetid://" .. name
	end
	local key = (name:lower():gsub("^lucide%-", ""))
	return Icons[key] or Icons[IconAliases[key] or ""]
end

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[MacUI] callback error: " .. tostring(err))
	end
end

local function Spawn(fn, ...)
	if type(fn) == "function" then
		task.spawn(SafeCall, fn, ...)
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handler = { Fn = fn, Connected = true }
	table.insert(self._handlers, handler)
	local handlers = self._handlers
	local connection = { Connected = true }
	function connection.Disconnect()
		connection.Connected = false
		handler.Connected = false
		local index = table.find(handlers, handler)
		if index then
			table.remove(handlers, index)
		end
	end
	return connection
end

function Signal:Fire(...)
	for _, handler in ipairs(table.clone(self._handlers)) do
		if handler.Connected then
			Spawn(handler.Fn, ...)
		end
	end
end

MacUI.ThemeChanged = Signal.new()
MacUI.AccentChanged = Signal.new()

-- Set while a keybind is recording so the same key press doesn't also
-- trigger other keybinds or the window's show/hide key.
local KeyCapture = { Active = false }

local function Tween(object, goals, duration, style, direction)
	local tween = TweenService:Create(
		object,
		TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		goals
	)
	tween:Play()
	return tween
end

local function Round(value, decimals)
	local factor = 10 ^ (decimals or 0)
	return math.floor(value * factor + 0.5) / factor
end

local function IsPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function GetFont(weight)
	return Font.new(MacUI.FontFamily, weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

local MeasureFonts = {
	[Enum.FontWeight.Regular] = Enum.Font.BuilderSans,
	[Enum.FontWeight.Medium] = Enum.Font.BuilderSansMedium,
	[Enum.FontWeight.SemiBold] = Enum.Font.BuilderSansBold,
	[Enum.FontWeight.Bold] = Enum.Font.BuilderSansBold,
}

-- Width of a single line of text in logical (unscaled) pixels.
local function MeasureText(text, size, weight)
	local ok, bounds = pcall(function()
		return TextService:GetTextSize(
			tostring(text),
			size,
			MeasureFonts[weight or Enum.FontWeight.Regular] or Enum.Font.BuilderSans,
			Vector2.new(10000, 1000)
		)
	end)
	if ok and bounds then
		return bounds.X
	end
	return #tostring(text) * size * 0.52
end

--------------------------------------------------------------------------------
-- Theme registry: every themed property is re-resolved when the theme,
-- accent or an element's state changes.
--------------------------------------------------------------------------------

local ThemeRegistry = {}
local FontRegistry = {}

local function Resolve(token)
	if type(token) == "function" then
		return token(MacUI.ThemeData)
	elseif token == "Accent" then
		return MacUI.Accent
	end
	return MacUI.ThemeData[token]
end

-- Drops registry entries when an instance is destroyed so closed popups,
-- banners and dialogs can be garbage collected.
local function Watch(instance)
	instance.Destroying:Connect(function()
		ThemeRegistry[instance] = nil
		FontRegistry[instance] = nil
	end)
end

local function Themed(instance, map)
	local entry = ThemeRegistry[instance]
	if not entry then
		entry = {}
		if FontRegistry[instance] == nil then
			Watch(instance)
		end
		ThemeRegistry[instance] = entry
	end
	for property, token in pairs(map) do
		entry[property] = token
		local value = Resolve(token)
		if value ~= nil then
			instance[property] = value
		end
	end
	return instance
end

-- Re-resolves an instance's tokens (used after its state changes, e.g. hover).
local function Restyle(instance, duration)
	local entry = ThemeRegistry[instance]
	if not entry then
		return
	end
	local goals = {}
	for property, token in pairs(entry) do
		goals[property] = Resolve(token)
	end
	if duration == 0 then
		for property, value in pairs(goals) do
			instance[property] = value
		end
	else
		Tween(instance, goals, duration or 0.18)
	end
end

local function RefreshTheme(duration)
	for instance in pairs(ThemeRegistry) do
		if instance.Parent == nil then
			ThemeRegistry[instance] = nil
		else
			Restyle(instance, duration)
		end
	end
end

local Defaults = {
	Frame = { BorderSizePixel = 0 },
	CanvasGroup = { BorderSizePixel = 0 },
	ScrollingFrame = { BorderSizePixel = 0, BackgroundTransparency = 1, ScrollBarThickness = 0 },
	TextLabel = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	},
	TextButton = { BorderSizePixel = 0, BackgroundTransparency = 1, AutoButtonColor = false, Text = "", TextSize = 14 },
	TextBox = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	},
	ImageLabel = { BorderSizePixel = 0, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit },
	ImageButton = { BorderSizePixel = 0, BackgroundTransparency = 1, AutoButtonColor = false },
}

local TextClasses = { TextLabel = true, TextButton = true, TextBox = true }

local function New(className, props)
	local instance = Instance.new(className)
	local defaults = Defaults[className]
	if defaults then
		for property, value in pairs(defaults) do
			instance[property] = value
		end
	end
	if TextClasses[className] then
		local weight = props and props.Weight or Enum.FontWeight.Regular
		instance.FontFace = GetFont(weight)
		FontRegistry[instance] = weight
		Watch(instance)
	end
	local parent, theme, children
	if props then
		for property, value in pairs(props) do
			if property == "Parent" then
				parent = value
			elseif property == "Theme" then
				theme = value
			elseif property == "Children" then
				children = value
			elseif property ~= "Weight" then
				instance[property] = value
			end
		end
	end
	if theme then
		Themed(instance, theme)
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function Corner(parent, radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function Stroke(parent, token, thickness, transparency)
	return New("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Theme = { Color = token },
		Parent = parent,
	})
end

local function Padding(parent, top, right, bottom, left)
	return New("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		Parent = parent,
	})
end

local function List(parent, direction, padding, props)
	local layout = New("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
	for property, value in pairs(props or {}) do
		layout[property] = value
	end
	return layout
end

local function Shadow(parent, spread, transparencyToken)
	return New("ImageLabel", {
		Name = "Shadow",
		Image = SHADOW_IMAGE,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		SliceScale = spread / 49,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, math.floor(spread * 0.25)),
		Size = UDim2.new(1, spread * 2, 1, spread * 2),
		ZIndex = 0,
		Theme = { ImageColor3 = "Shadow", ImageTransparency = transparencyToken or "ShadowTransparency" },
		Parent = parent,
	})
end

local function IconImage(props)
	local icon = props.Icon
	props.Icon = nil
	local size = props.IconSize or 16
	props.IconSize = nil
	props.Image = MacUI:GetIcon(icon) or ""
	props.Size = props.Size or UDim2.fromOffset(size, size)
	return New("ImageLabel", props)
end

local function Lighten(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

local function Darken(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

local function TileGradient(color)
	return ColorSequence.new(Lighten(color, 0.14), Darken(color, 0.08))
end

-- A rounded, gradient-filled square with a white glyph: the System Settings icon.
local function IconTile(parent, icon, color, size, radius, glyphSize, props)
	local tile = New("Frame", {
		Name = "Tile",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = parent,
	})
	for property, value in pairs(props or {}) do
		tile[property] = value
	end
	Corner(tile, radius)
	local gradient = New("UIGradient", { Rotation = 90, Parent = tile })
	local glyph = IconImage({
		Name = "Glyph",
		Icon = icon,
		IconSize = glyphSize,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ImageColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = tile,
	})
	local function Paint()
		local value = type(color) == "function" and color() or color
		gradient.Color = TileGradient(value)
	end
	Paint()
	if type(color) == "function" then
		local connection = MacUI.AccentChanged:Connect(Paint)
		tile.Destroying:Connect(connection.Disconnect)
	end
	return tile, glyph, gradient
end

local function ResolveColor(value)
	if typeof(value) == "Color3" then
		return value
	elseif type(value) == "string" then
		if MacUI.Accents[value] then
			return MacUI.Accents[value]
		end
		local ok, color = pcall(Color3.fromHex, value)
		if ok then
			return color
		end
	end
	return nil
end

local function ParseArgs(idx, info)
	if type(idx) == "table" and info == nil then
		info = idx
		idx = info.Flag or info.Idx or info.Id
	end
	return idx, info or {}
end

local function KeyName(value)
	local names = {
		LeftControl = "L-Ctrl",
		RightControl = "R-Ctrl",
		LeftShift = "L-Shift",
		RightShift = "R-Shift",
		LeftAlt = "L-Alt",
		RightAlt = "R-Alt",
		LeftSuper = "L-Cmd",
		RightSuper = "R-Cmd",
		Return = "Enter",
		MB1 = "Mouse 1",
		MB2 = "Mouse 2",
		MB3 = "Mouse 3",
	}
	return names[value] or tostring(value)
end

--------------------------------------------------------------------------------
-- Library-level settings
--------------------------------------------------------------------------------

function MacUI:SetTheme(name, instant)
	local theme = self.Themes[name]
	if not theme then
		warn("[MacUI] unknown theme: " .. tostring(name))
		return
	end
	self.ThemeName = name
	self.ThemeData = theme
	RefreshTheme(instant and 0 or 0.3)
	self.ThemeChanged:Fire(name)
end

function MacUI:SetAccent(value, instant)
	local color = ResolveColor(value)
	if not color then
		warn("[MacUI] invalid accent: " .. tostring(value))
		return
	end
	self.Accent = color
	RefreshTheme(instant and 0 or 0.3)
	self.AccentChanged:Fire(color)
end

function MacUI:SetFont(family)
	if typeof(family) == "EnumItem" then
		family = Font.fromEnum(family).Family
	elseif type(family) == "string" and not family:find("://") then
		family = "rbxasset://fonts/families/" .. family .. ".json"
	end
	self.FontFamily = family
	for instance, weight in pairs(FontRegistry) do
		if instance.Parent == nil then
			FontRegistry[instance] = nil
		else
			instance.FontFace = GetFont(weight)
		end
	end
end

function MacUI:SetScale(scale)
	for _, window in ipairs(self.Windows) do
		window:SetScale(scale)
	end
end

function MacUI:SetMinimizeKey(key)
	for _, window in ipairs(self.Windows) do
		window:SetMinimizeKey(key)
	end
end

function MacUI:GetThemes()
	local names = {}
	for name in pairs(self.Themes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function MacUI:SafeCallback(fn, ...)
	SafeCall(fn, ...)
end

function MacUI:Round(value, decimals)
	return Round(value, decimals)
end

local UnloadCallbacks = {}
function MacUI:OnUnload(fn)
	table.insert(UnloadCallbacks, fn)
end

--------------------------------------------------------------------------------
-- Notifications (macOS Notification Center banners)
--------------------------------------------------------------------------------

local NotificationGui
local Banners = {}

local function NotificationScale()
	return math.clamp(Viewport().X / 1150, 0.72, 1)
end

local function LayoutBanners()
	local y = 12
	for _, banner in ipairs(Banners) do
		if not banner.Closing then
			Tween(banner.Holder, { Position = UDim2.new(1, -14, 0, y) }, 0.45, Enum.EasingStyle.Quint)
			y += (banner.Height * banner.Scale) + 10
		end
	end
end

function MacUI:Notify(config)
	config = config or {}
	if self.Unloaded then
		return
	end
	if not NotificationGui or not NotificationGui.Parent then
		NotificationGui = New("ScreenGui", {
			Name = "MacUI_Notifications",
			ResetOnSpawn = false,
			DisplayOrder = 1000,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		})
		ParentGui(NotificationGui)
	end

	local scale = NotificationScale()
	local width = 344
	local banner = { Scale = scale, Height = 72, Closing = false }

	local holder = New("Frame", {
		Name = "Banner",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, width * scale + 40, 0, 12),
		Size = UDim2.fromOffset(width, banner.Height),
		Parent = NotificationGui,
	})
	New("UIScale", { Scale = scale, Parent = holder })
	local shadow = Shadow(holder, 26, function(t)
		return banner.Shown and t.ShadowTransparency + 0.15 or 1
	end)
	local card = New("CanvasGroup", {
		Name = "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1,
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Menu" },
		Parent = holder,
	})
	Corner(card, 16)
	local border = New("Frame", {
		Name = "Border",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 5,
		Parent = card,
	})
	Corner(border, 15)
	Stroke(border, "MenuStroke", 1, 0.2)

	local content = New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	Padding(content, 12, 14, 13, 12)

	local tileColor = ResolveColor(config.IconColor)
	IconTile(content, config.Icon or "bell", tileColor or function()
		return MacUI.Accent
	end, 36, 9, 20, { Position = UDim2.fromOffset(0, 1) })

	local column = New("Frame", {
		Name = "Text",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(48, 0),
		Size = UDim2.new(1, -48, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = content,
	})
	List(column, nil, 1)
	local header = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 1,
		Parent = column,
	})
	New("TextLabel", {
		Name = "Title",
		Text = tostring(config.Title or "Notification"),
		TextSize = 14,
		Weight = Enum.FontWeight.Bold,
		Size = UDim2.new(1, -40, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Text" },
		Parent = header,
	})
	New("TextLabel", {
		Name = "Time",
		Text = config.Time or "now",
		TextSize = 12,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 40, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		Theme = { TextColor3 = "SubText" },
		Parent = header,
	})
	if config.SubContent and config.SubContent ~= "" then
		New("TextLabel", {
			Name = "Subtitle",
			Text = tostring(config.SubContent),
			TextSize = 13,
			Weight = Enum.FontWeight.Medium,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			LayoutOrder = 2,
			Theme = { TextColor3 = "Text" },
			Parent = column,
		})
	end
	if config.Content and config.Content ~= "" then
		New("TextLabel", {
			Name = "Body",
			Text = tostring(config.Content),
			TextSize = 13,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			RichText = true,
			LayoutOrder = 3,
			Theme = { TextColor3 = function(t)
				return t.Text:Lerp(t.SubText, 0.35)
			end },
			Parent = column,
		})
	end

	local hitbox = New("TextButton", {
		Name = "Hitbox",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Parent = holder,
	})
	local close = New("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		ZIndex = 6,
		Theme = { BackgroundColor3 = "Menu" },
		Parent = holder,
	})
	Corner(close, 10)
	local closeStroke = Stroke(close, "MenuStroke", 1, 1)
	local closeGlyph = IconImage({
		Icon = "x",
		IconSize = 11,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ImageTransparency = 1,
		Theme = { ImageColor3 = "SubText" },
		ZIndex = 7,
		Parent = close,
	})

	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local height = math.max(card.AbsoluteSize.Y / scale, 40)
		if math.abs(height - banner.Height) > 0.5 then
			banner.Height = height
			holder.Size = UDim2.fromOffset(width, height)
			LayoutBanners()
		end
	end)

	banner.Holder = holder
	function banner:Close()
		if banner.Closing then
			return
		end
		banner.Closing = true
		banner.Shown = false
		local index = table.find(Banners, banner)
		if index then
			table.remove(Banners, index)
		end
		LayoutBanners()
		Tween(holder, { Position = holder.Position + UDim2.fromOffset(width * scale + 40, 0) }, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		Tween(card, { GroupTransparency = 1 }, 0.35)
		Restyle(shadow, 0.25)
		task.delay(0.42, function()
			holder:Destroy()
		end)
	end

	hitbox.MouseEnter:Connect(function()
		Tween(close, { BackgroundTransparency = 0 }, 0.15)
		Tween(closeStroke, { Transparency = 0.2 }, 0.15)
		Tween(closeGlyph, { ImageTransparency = 0 }, 0.15)
	end)
	hitbox.MouseLeave:Connect(function()
		Tween(close, { BackgroundTransparency = 1 }, 0.15)
		Tween(closeStroke, { Transparency = 1 }, 0.15)
		Tween(closeGlyph, { ImageTransparency = 1 }, 0.15)
	end)
	close.MouseButton1Click:Connect(function()
		banner:Close()
	end)
	hitbox.MouseButton1Click:Connect(function()
		Spawn(config.Callback)
		banner:Close()
	end)

	table.insert(Banners, 1, banner)
	holder.Position = UDim2.new(1, width * scale + 40, 0, 12)
	LayoutBanners()
	banner.Shown = true
	Tween(card, { GroupTransparency = 0 }, 0.3)
	Restyle(shadow, 0.4)

	local duration = config.Duration
	if duration == nil then
		duration = 5
	end
	if duration and duration > 0 then
		task.delay(duration, function()
			banner:Close()
		end)
	end
	return banner
end

--------------------------------------------------------------------------------
-- Rows: every element lives in a row inside a rounded group box.
--------------------------------------------------------------------------------

local RowMethods = {}
RowMethods.__index = RowMethods

local function CreateRow(container, info, options)
	options = options or {}
	local window = container.Window
	local tab = container.Tab
	local group = container:_GetGroup()

	local row = setmetatable({
		Window = window,
		Tab = tab,
		Group = group,
		Title = tostring(info.Title or ""),
		Description = tostring(info.Description or info.Desc or ""),
		Keywords = tostring(info.Keywords or ""),
		UserVisible = true,
		SearchMatch = true,
		Hovered = false,
		Pressed = false,
		Disabled = false,
		Connections = {},
	}, RowMethods)

	group.Order += 1
	row.Frame = New("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = group.Order,
		Parent = group.Frame,
	})
	row.Separator = New("Frame", {
		Name = "Separator",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 0, 1),
		ZIndex = 4,
		Theme = { BackgroundColor3 = "Separator" },
		Parent = row.Frame,
	})

	if options.Clickable then
		row.Highlight = New("Frame", {
			Name = "Highlight",
			Position = UDim2.fromOffset(4, 4),
			Size = UDim2.new(1, -8, 1, -8),
			ZIndex = 1,
			Theme = {
				BackgroundColor3 = "Hover",
				BackgroundTransparency = function(t)
					if row.Pressed then
						return t.HoverTransparency - 0.04
					end
					return row.Hovered and t.HoverTransparency or 1
				end,
			},
			Parent = row.Frame,
		})
		Corner(row.Highlight, 7)
		row.Hitbox = New("TextButton", {
			Name = "Hitbox",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
			Parent = row.Frame,
		})
		row.Hitbox.MouseEnter:Connect(function()
			row.Hovered = true
			Restyle(row.Highlight, 0.12)
		end)
		row.Hitbox.MouseLeave:Connect(function()
			row.Hovered = false
			row.Pressed = false
			Restyle(row.Highlight, 0.2)
		end)
		row.Hitbox.MouseButton1Down:Connect(function()
			row.Pressed = true
			Restyle(row.Highlight, 0.08)
		end)
		row.Hitbox.MouseButton1Up:Connect(function()
			row.Pressed = false
			Restyle(row.Highlight, 0.2)
		end)
		row.Hitbox.MouseButton1Click:Connect(function()
			if not row.Disabled and row.OnClick then
				row.OnClick()
			end
		end)
	end

	row.Content = New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 3,
		Parent = row.Frame,
	})
	row.Padding = Padding(row.Content, 13, 12, 13, 12)
	row.Stack = New("Frame", {
		Name = "Text",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = row.Content,
	})
	List(row.Stack, nil, 2)
	row.TitleLabel = New("TextLabel", {
		Name = "Title",
		Text = row.Title,
		TextSize = 14,
		Weight = options.TitleWeight or Enum.FontWeight.Regular,
		Size = UDim2.new(1, 0, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Theme = { TextColor3 = "Text" },
		Parent = row.Stack,
	})
	row.DescLabel = New("TextLabel", {
		Name = "Description",
		Text = row.Description,
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		RichText = true,
		LayoutOrder = 2,
		Theme = { TextColor3 = options.DescToken or "SubText" },
		Parent = row.Stack,
	})
	if options.DescSize then
		row.DescLabel.TextSize = options.DescSize
	end

	row.Accessory = New("Frame", {
		Name = "Accessory",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 5,
		Parent = row.Frame,
	})
	List(row.Accessory, Enum.FillDirection.Horizontal, 8, {
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	})

	row.Accessory:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		row:_UpdateReserve()
	end)

	table.insert(group.Rows, row)
	table.insert(tab.Rows, row)
	row:_UpdateLayout()
	row:_UpdateReserve()
	group:Refresh()
	if window.SearchQuery ~= "" then
		window:_ApplySearch()
	end
	return row
end

function RowMethods:_UpdateReserve()
	local width = self.Accessory.AbsoluteSize.X / self.Window:GetAbsoluteScale()
	if self.FullWidthText then
		width = 0
	end
	self.Stack.Size = UDim2.new(1, -(width > 1 and width + 14 or 0), 0, 0)
end

function RowMethods:_UpdateLayout()
	local hasTitle = self.Title ~= ""
	local hasDesc = self.Description ~= ""
	self.TitleLabel.Visible = hasTitle
	self.DescLabel.Visible = hasDesc
	self.Stack.Visible = hasTitle or hasDesc
	local pad = (hasTitle and hasDesc) and 9 or 13
	if self.TallPadding then
		pad = math.max(pad, self.TallPadding)
	end
	self.Padding.PaddingTop = UDim.new(0, pad)
	self.Padding.PaddingBottom = UDim.new(0, pad)
end

function RowMethods:SetTitle(text)
	self.Title = tostring(text or "")
	self.TitleLabel.Text = self.Title
	self:_UpdateLayout()
end

function RowMethods:SetDesc(text)
	self.Description = tostring(text or "")
	self.DescLabel.Text = self.Description
	self:_UpdateLayout()
end

function RowMethods:_Matches(query)
	local haystack = (self.Title .. " " .. self.Description .. " " .. self.Keywords .. " " .. (self.SearchExtra or "")):lower()
	return haystack:find(query, 1, true) ~= nil
end

function RowMethods:_ApplyVisibility()
	self.Frame.Visible = self.UserVisible and self.SearchMatch
	self.Group:Refresh()
end

function RowMethods:SetVisible(visible)
	self.UserVisible = visible ~= false
	self:_ApplyVisibility()
end

function RowMethods:SetDisabled(disabled)
	self.Disabled = disabled == true
	if self.Disabled and not self.Blocker then
		self.Blocker = New("TextButton", {
			Name = "Disabled",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 20,
			Theme = { BackgroundColor3 = "Group" },
			Parent = self.Frame,
		})
		Tween(self.Blocker, { BackgroundTransparency = 0.45 }, 0.2)
	elseif not self.Disabled and self.Blocker then
		local blocker = self.Blocker
		self.Blocker = nil
		Tween(blocker, { BackgroundTransparency = 1 }, 0.2)
		task.delay(0.2, function()
			blocker:Destroy()
		end)
	end
end

function RowMethods:Destroy()
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	local index = table.find(self.Group.Rows, self)
	if index then
		table.remove(self.Group.Rows, index)
	end
	index = table.find(self.Tab.Rows, self)
	if index then
		table.remove(self.Tab.Rows, index)
	end
	self.Frame:Destroy()
	self.Group:Refresh()
end

-- A connection that is cleaned up with the row.
function RowMethods:Connect(signal, fn)
	local connection = signal:Connect(fn)
	table.insert(self.Connections, connection)
	return connection
end

--------------------------------------------------------------------------------
-- Element base
--------------------------------------------------------------------------------

local ElementBase = {}
ElementBase.__index = ElementBase

local function NewElement(kind, row, info)
	return setmetatable({
		Type = kind,
		Row = row,
		Title = info.Title,
		Description = info.Description,
		Callback = info.Callback,
		_listeners = {},
	}, ElementBase)
end

function ElementBase:SetTitle(text)
	self.Title = text
	self.Row:SetTitle(text)
end

function ElementBase:SetDesc(text)
	self.Description = text
	self.Row:SetDesc(text)
end
ElementBase.SetDescription = ElementBase.SetDesc

function ElementBase:SetVisible(visible)
	self.Row:SetVisible(visible)
end

function ElementBase:SetDisabled(disabled)
	self.Disabled = disabled == true
	self.Row:SetDisabled(disabled)
end

function ElementBase:Lock()
	self:SetDisabled(true)
end

function ElementBase:Unlock()
	self:SetDisabled(false)
end

function ElementBase:OnChanged(fn)
	table.insert(self._listeners, fn)
	SafeCall(fn, self.Value)
	return self
end

function ElementBase:_Emit(...)
	Spawn(self.Callback, ...)
	for _, fn in ipairs(self._listeners) do
		Spawn(fn, ...)
	end
end

function ElementBase:Destroy()
	self.Row:Destroy()
	if self.Idx ~= nil and MacUI.Options[self.Idx] == self then
		MacUI.Options[self.Idx] = nil
	end
end

local function Register(idx, element)
	if idx ~= nil then
		element.Idx = idx
		MacUI.Options[idx] = element
	end
	return element
end

-- Push button used in rows and dialogs.
local function PushButton(parent, text, style, height)
	local button = { Hovered = false, Pressed = false, Style = style or "Default" }
	button.Instance = New("TextButton", {
		Name = "PushButton",
		Text = tostring(text),
		TextSize = 13,
		Weight = Enum.FontWeight.Medium,
		Size = UDim2.fromOffset(0, height or 24),
		AutomaticSize = Enum.AutomaticSize.X,
		Theme = {
			BackgroundColor3 = function(t)
				local base
				if button.Style == "Primary" then
					base = MacUI.Accent
				elseif button.Style == "Destructive" then
					base = t.Destructive
				else
					base = t.Button
				end
				if button.Pressed then
					return Darken(base, 0.12)
				elseif button.Hovered then
					return button.Style == "Default" and t.ButtonHover or Lighten(base, 0.1)
				end
				return base
			end,
			BackgroundTransparency = function()
				return 0
			end,
			TextColor3 = function(t)
				if button.Style == "Default" then
					return t.Text
				end
				return rgb(255, 255, 255)
			end,
		},
		Parent = parent,
	})
	Corner(button.Instance, 6)
	Padding(button.Instance, 0, 12, 0, 12)
	button.Stroke = Stroke(button.Instance, function(t)
		return button.Style == "Default" and t.ControlStroke or Darken(MacUI.Accent, 0.2)
	end, 1, 0.35)
	New("UISizeConstraint", { MinSize = Vector2.new(56, 0), Parent = button.Instance })
	button.Instance.MouseEnter:Connect(function()
		button.Hovered = true
		Restyle(button.Instance, 0.12)
	end)
	button.Instance.MouseLeave:Connect(function()
		button.Hovered = false
		button.Pressed = false
		Restyle(button.Instance, 0.18)
	end)
	button.Instance.MouseButton1Down:Connect(function()
		button.Pressed = true
		Restyle(button.Instance, 0.06)
	end)
	button.Instance.MouseButton1Up:Connect(function()
		button.Pressed = false
		Restyle(button.Instance, 0.15)
	end)
	return button
end

--------------------------------------------------------------------------------
-- Containers (tabs and sections share these element constructors)
--------------------------------------------------------------------------------

local Container = {}

function Container:AddParagraph(idx, info)
	if type(idx) == "table" then
		info = idx
		idx = info.Flag
	end
	info = info or {}
	local row = CreateRow(self, {
		Title = info.Title,
		Description = info.Content or info.Description,
		Keywords = info.Keywords,
	}, { TitleWeight = Enum.FontWeight.Medium, DescSize = 13, DescToken = "SubText" })
	row.FullWidthText = true
	row:_UpdateReserve()
	local Paragraph = NewElement("Paragraph", row, info)
	Paragraph.Content = info.Content
	function Paragraph:SetContent(text)
		self.Content = text
		row:SetDesc(text)
	end
	Paragraph.SetDesc = Paragraph.SetContent
	Paragraph.SetValue = Paragraph.SetContent
	return Register(idx, Paragraph)
end

-- Key/value row: "Status ........ Fighting: Blessed Maiden"
function Container:AddLabel(idx, info)
	idx, info = ParseArgs(idx, info)
	local row = CreateRow(self, info)
	local Label = NewElement("Label", row, info)
	Label.Value = tostring(info.Value or info.Text or "")

	local valueLabel = New("TextLabel", {
		Name = "Value",
		Text = Label.Value,
		TextSize = 14,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = true,
		Theme = {
			TextColor3 = function(t)
				return ResolveColor(info.ValueColor) or t.SubText
			end,
		},
		Parent = row.Accessory,
	})
	local limit = New("UISizeConstraint", { MaxSize = Vector2.new(320, 18), Parent = valueLabel })
	local function UpdateLimit()
		local rowWidth = row.Frame.AbsoluteSize.X / row.Window:GetAbsoluteScale()
		local share = row.Title == "" and row.Description == "" and 1 or 0.62
		limit.MaxSize = Vector2.new(math.max(rowWidth * share - 24, 40), 18)
	end
	row:Connect(row.Frame:GetPropertyChangedSignal("AbsoluteSize"), UpdateLimit)
	UpdateLimit()

	function Label:SetValue(text)
		self.Value = tostring(text or "")
		valueLabel.Text = self.Value
		row.SearchExtra = self.Value
	end
	Label.SetText = Label.SetValue
	function Label:SetValueColor(color)
		info.ValueColor = color
		Restyle(valueLabel, 0.15)
	end
	Label:SetValue(Label.Value)
	return Register(idx, Label)
end
Container.AddStatus = Container.AddLabel

function Container:AddButton(info, callback)
	if type(info) == "string" then
		info = { Title = info, Callback = callback }
	end
	info = info or {}
	local row = CreateRow(self, info, { Clickable = true })
	local Button = NewElement("Button", row, info)

	local function Fire()
		if row.Disabled then
			return
		end
		Spawn(Button.Callback)
	end

	if info.ButtonText then
		local push = PushButton(row.Accessory, info.ButtonText, info.Style)
		push.Instance.MouseButton1Click:Connect(Fire)
		Button.PushButton = push
	else
		IconImage({
			Name = "Chevron",
			Icon = info.Icon or "chevron-right",
			IconSize = 14,
			Theme = { ImageColor3 = "Tertiary" },
			Parent = row.Accessory,
		})
	end
	row.OnClick = Fire

	function Button:SetCallback(fn)
		self.Callback = fn
	end
	function Button:Fire()
		Fire()
	end
	return Button
end

function Container:AddToggle(idx, info)
	idx, info = ParseArgs(idx, info)
	local row = CreateRow(self, info, { Clickable = true })
	local Toggle = NewElement("Toggle", row, info)
	Toggle.Value = info.Default == true
	local checkbox = info.Style == "Checkbox"

	local knob, knobShadow, track, check
	if checkbox then
		track = New("Frame", {
			Name = "Checkbox",
			Size = UDim2.fromOffset(18, 18),
			Theme = {
				BackgroundColor3 = function(t)
					return Toggle.Value and MacUI.Accent or t.Field
				end,
			},
			Parent = row.Accessory,
		})
		Corner(track, 5)
		Stroke(track, function(t)
			return Toggle.Value and Darken(MacUI.Accent, 0.15) or t.FieldStroke
		end)
		check = IconImage({
			Icon = "check",
			IconSize = 13,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			ImageColor3 = Color3.new(1, 1, 1),
			ImageTransparency = Toggle.Value and 0 or 1,
			Parent = track,
		})
	else
		track = New("Frame", {
			Name = "Switch",
			Size = UDim2.fromOffset(38, 22),
			Theme = {
				BackgroundColor3 = function(t)
					return Toggle.Value and MacUI.Accent or t.SwitchOff
				end,
			},
			Parent = row.Accessory,
		})
		Corner(track, 11)
		knobShadow = New("Frame", {
			Name = "KnobShadow",
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.fromOffset(Toggle.Value and 18 or 2, 3),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.8,
			Parent = track,
		})
		Corner(knobShadow, 9)
		knob = New("Frame", {
			Name = "Knob",
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.fromOffset(Toggle.Value and 18 or 2, 2),
			ZIndex = 2,
			Theme = { BackgroundColor3 = "Knob" },
			Parent = track,
		})
		Corner(knob, 9)
	end

	local pressed = false
	local function Render(duration)
		Restyle(track, duration)
		if checkbox then
			local stroke = track:FindFirstChildOfClass("UIStroke")
			if stroke then
				Restyle(stroke, duration)
			end
			Tween(check, { ImageTransparency = Toggle.Value and 0 or 1 }, duration)
			return
		end
		local width = pressed and 22 or 18
		local x = Toggle.Value and (36 - width) or 2
		Tween(knob, { Position = UDim2.fromOffset(x, 2), Size = UDim2.fromOffset(width, 18) }, duration, Enum.EasingStyle.Quint)
		Tween(knobShadow, { Position = UDim2.fromOffset(x, 3), Size = UDim2.fromOffset(width, 18) }, duration, Enum.EasingStyle.Quint)
	end

	function Toggle:SetValue(value)
		value = value == true
		self.Value = value
		Render(0.25)
		self:_Emit(value)
	end

	row.OnClick = function()
		Toggle:SetValue(not Toggle.Value)
	end
	if not checkbox then
		row.Hitbox.MouseButton1Down:Connect(function()
			pressed = true
			Render(0.2)
		end)
		row.Hitbox.MouseButton1Up:Connect(function()
			pressed = false
		end)
		row.Hitbox.MouseLeave:Connect(function()
			if pressed then
				pressed = false
				Render(0.2)
			end
		end)
	end

	Render(0)
	Register(idx, Toggle)
	Toggle:_Emit(Toggle.Value)
	return Toggle
end

function Container:AddCheckbox(idx, info)
	idx, info = ParseArgs(idx, info)
	info.Style = "Checkbox"
	return self:AddToggle(idx, info)
end

function Container:AddSlider(idx, info)
	idx, info = ParseArgs(idx, info)
	local row = CreateRow(self, info)
	local Slider = NewElement("Slider", row, info)
	Slider.Min = tonumber(info.Min) or 0
	Slider.Max = tonumber(info.Max) or 100
	Slider.Increment = tonumber(info.Increment or info.Step)
	local stepDecimals = 0
	if Slider.Increment then
		local fraction = tostring(Slider.Increment):match("%.(%d+)$")
		stepDecimals = fraction and #fraction or 0
	end
	Slider.Rounding = tonumber(info.Rounding) or stepDecimals
	Slider.Finished = info.Finished == true
	Slider.Suffix = info.Suffix or ""
	Slider.Value = math.clamp(tonumber(info.Default) or Slider.Min, Slider.Min, Slider.Max)

	local width = info.Width or 170
	local rail = New("Frame", {
		Name = "Slider",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(width, 22),
		LayoutOrder = 1,
		Parent = row.Accessory,
	})
	local bar = New("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 4),
		Theme = { BackgroundColor3 = "Track" },
		Parent = rail,
	})
	Corner(bar, 2)
	local fill = New("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		Theme = { BackgroundColor3 = "Accent" },
		Parent = bar,
	})
	Corner(fill, 2)
	local knobState = { Hovered = false, Dragging = false }
	local knob = New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 3,
		Theme = { BackgroundColor3 = "Knob" },
		Parent = rail,
	})
	Corner(knob, 9)
	New("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.82, Thickness = 1, Parent = knob })
	local hit = New("TextButton", {
		Name = "Hitbox",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 16, 1, 10),
		ZIndex = 4,
		Parent = rail,
	})

	local box = New("TextBox", {
		Name = "Value",
		Text = "",
		TextSize = 13,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 0,
		LayoutOrder = 2,
		Theme = { BackgroundColor3 = "Field", TextColor3 = "Text" },
		Parent = row.Accessory,
	})
	Corner(box, 6)
	local boxStroke = Stroke(box, "FieldStroke")

	local function Format(value)
		return string.format("%." .. math.max(Slider.Rounding, 0) .. "f", value) .. Slider.Suffix
	end
	box.AutomaticSize = Enum.AutomaticSize.None
	box.Size = UDim2.fromOffset(
		math.max(46, math.ceil(math.max(MeasureText(Format(Slider.Max), 13), MeasureText(Format(Slider.Min), 13))) + 16),
		24
	)

	local function Render(duration)
		local range = Slider.Max - Slider.Min
		local alpha = range == 0 and 0 or (Slider.Value - Slider.Min) / range
		Tween(fill, { Size = UDim2.fromScale(alpha, 1) }, duration or 0.12, Enum.EasingStyle.Quart)
		Tween(knob, { Position = UDim2.fromScale(alpha, 0.5) }, duration or 0.12, Enum.EasingStyle.Quart)
		if not box:IsFocused() then
			box.Text = Format(Slider.Value)
		end
	end

	local function Normalize(value)
		value = math.clamp(tonumber(value) or Slider.Min, Slider.Min, Slider.Max)
		if Slider.Increment and Slider.Increment > 0 then
			value = Slider.Min + Round((value - Slider.Min) / Slider.Increment) * Slider.Increment
		end
		return math.clamp(Round(value, Slider.Rounding), Slider.Min, Slider.Max)
	end

	local pendingEmit = false
	function Slider:SetValue(value)
		value = Normalize(value)
		local changed = value ~= self.Value
		self.Value = value
		Render()
		if changed or not self._initialized then
			if self.Finished and knobState.Dragging then
				pendingEmit = true
			else
				self:_Emit(value)
			end
		end
	end

	function Slider:SetMin(value)
		self.Min = value
		self:SetValue(self.Value)
	end

	function Slider:SetMax(value)
		self.Max = value
		self:SetValue(self.Value)
	end

	local function SetFromPointer(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * alpha)
	end

	local function RenderKnob()
		local size = (knobState.Dragging or knobState.Hovered) and 20 or 18
		Tween(knob, { Size = UDim2.fromOffset(size, size) }, 0.15)
	end

	hit.MouseEnter:Connect(function()
		knobState.Hovered = true
		RenderKnob()
	end)
	hit.MouseLeave:Connect(function()
		knobState.Hovered = false
		RenderKnob()
	end)
	hit.InputBegan:Connect(function(input)
		if IsPointer(input) and not row.Disabled then
			knobState.Dragging = true
			RenderKnob()
			SetFromPointer(input.Position.X)
		end
	end)
	row:Connect(UserInputService.InputChanged, function(input)
		if knobState.Dragging and IsMove(input) then
			SetFromPointer(input.Position.X)
		end
	end)
	row:Connect(UserInputService.InputEnded, function(input)
		if knobState.Dragging and IsPointer(input) then
			knobState.Dragging = false
			RenderKnob()
			if pendingEmit then
				pendingEmit = false
				Slider:_Emit(Slider.Value)
			end
		end
	end)

	box.Focused:Connect(function()
		box.Text = string.format("%." .. math.max(Slider.Rounding, 0) .. "f", Slider.Value)
		Themed(boxStroke, { Color = "Accent" })
	end)
	box.FocusLost:Connect(function()
		Themed(boxStroke, { Color = "FieldStroke" })
		local number = tonumber((box.Text:gsub("[^%d%.%-]", "")))
		if number then
			Slider:SetValue(number)
		end
		box.Text = Format(Slider.Value)
	end)

	Slider.Value = Normalize(Slider.Value)
	Render(0)
	Register(idx, Slider)
	Slider:_Emit(Slider.Value)
	Slider._initialized = true
	return Slider
end

function Container:AddDropdown(idx, info)
	idx, info = ParseArgs(idx, info)
	local row = CreateRow(self, info, { Clickable = true })
	local window = row.Window
	local Dropdown = NewElement("Dropdown", row, info)
	Dropdown.Values = info.Values or {}
	Dropdown.Multi = info.Multi == true
	Dropdown.AllowNull = info.AllowNull == true or Dropdown.Multi

	if Dropdown.Multi then
		Dropdown.Value = {}
		local default = info.Default
		if type(default) == "table" then
			for key, value in pairs(default) do
				if type(key) == "number" then
					Dropdown.Value[value] = true
				elseif value then
					Dropdown.Value[key] = true
				end
			end
		elseif type(default) == "string" then
			Dropdown.Value[default] = true
		end
	else
		local default = info.Default
		if type(default) == "number" then
			default = Dropdown.Values[default]
		end
		Dropdown.Value = default
		if Dropdown.Value == nil and not Dropdown.AllowNull then
			Dropdown.Value = Dropdown.Values[1]
		end
	end

	function Dropdown:_Display()
		if self.Multi then
			local selected = {}
			for _, value in ipairs(self.Values) do
				if self.Value[value] then
					table.insert(selected, tostring(value))
				end
			end
			if #selected == 0 then
				return "None"
			end
			local joined = table.concat(selected, ", ")
			if #selected > 2 and #joined > 26 then
				return #selected .. " selected"
			end
			return joined
		end
		if self.Value == nil then
			return "None"
		end
		return tostring(self.Value)
	end

	local popup = New("TextButton", {
		Name = "PopupButton",
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = row.Accessory,
	})
	List(popup, Enum.FillDirection.Horizontal, 7, { VerticalAlignment = Enum.VerticalAlignment.Center })
	local valueLabel = New("TextLabel", {
		Name = "Value",
		TextSize = 14,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Theme = {
			TextColor3 = function(t)
				return Dropdown:_Display() == "None" and t.SubText or t.Text
			end,
		},
		Parent = popup,
	})
	New("UISizeConstraint", { MaxSize = Vector2.new(info.MaxWidth or 200, 18), Parent = valueLabel })
	local capsuleState = { Hovered = false }
	local capsule = New("Frame", {
		Name = "Chevrons",
		Size = UDim2.fromOffset(17, 21),
		LayoutOrder = 2,
		Theme = {
			BackgroundColor3 = function(t)
				return capsuleState.Hovered and t.ControlHover or t.Control
			end,
		},
		Parent = popup,
	})
	Corner(capsule, 5)
	IconImage({
		Icon = "chevrons-up-down",
		IconSize = 12,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Theme = { ImageColor3 = "Text" },
		Parent = capsule,
	})

	function Dropdown:Display()
		valueLabel.Text = self:_Display()
		row.SearchExtra = valueLabel.Text
		Restyle(valueLabel, 0)
	end

	function Dropdown:GetActiveValues()
		if self.Multi then
			local list = {}
			for _, value in ipairs(self.Values) do
				if self.Value[value] then
					table.insert(list, value)
				end
			end
			return list
		end
		return self.Value and 1 or 0
	end

	function Dropdown:SetValue(value)
		if self.Multi then
			local set = {}
			if type(value) == "table" then
				for key, v in pairs(value) do
					if type(key) == "number" then
						set[v] = true
					elseif v then
						set[key] = true
					end
				end
			end
			self.Value = set
		else
			if value ~= nil and not table.find(self.Values, value) then
				value = nil
			end
			if value == nil and not self.AllowNull then
				value = self.Values[1]
			end
			self.Value = value
		end
		self:Display()
		self:_Emit(self.Value)
	end

	function Dropdown:SetValues(values)
		self.Values = values or {}
		if self.Multi then
			for key in pairs(self.Value) do
				if not table.find(self.Values, key) then
					self.Value[key] = nil
				end
			end
		elseif self.Value ~= nil and not table.find(self.Values, self.Value) then
			self.Value = (not self.AllowNull) and self.Values[1] or nil
		end
		self:Display()
	end

	function Dropdown:Open()
		if row.Disabled then
			return
		end
		window:_OpenMenu(popup, {
			Values = self.Values,
			Multi = self.Multi,
			Searchable = info.Searchable,
			MinWidth = math.max(popup.AbsoluteSize.X / window:GetAbsoluteScale() + 24, 170),
			IsSelected = function(value)
				if self.Multi then
					return self.Value[value] == true
				end
				return self.Value == value
			end,
			OnPick = function(value)
				if self.Multi then
					self.Value[value] = not self.Value[value] or nil
					self:Display()
					self:_Emit(self.Value)
				else
					if self.Value == value and self.AllowNull then
						value = nil
					end
					self.Value = value
					self:Display()
					self:_Emit(self.Value)
				end
			end,
		})
	end

	function Dropdown:Close()
		window:_ClosePopup()
	end

	popup.MouseEnter:Connect(function()
		capsuleState.Hovered = true
		Restyle(capsule, 0.12)
	end)
	popup.MouseLeave:Connect(function()
		capsuleState.Hovered = false
		Restyle(capsule, 0.18)
	end)
	popup.MouseButton1Click:Connect(function()
		Dropdown:Open()
	end)
	row.OnClick = function()
		Dropdown:Open()
	end

	Dropdown:Display()
	return Register(idx, Dropdown)
end

function Container:AddInput(idx, info)
	idx, info = ParseArgs(idx, info)
	local row = CreateRow(self, info)
	local Input = NewElement("Input", row, info)
	Input.Value = tostring(info.Default or "")
	Input.Numeric = info.Numeric == true
	Input.Finished = info.Finished == true

	local field = New("Frame", {
		Name = "Field",
		Size = UDim2.fromOffset(info.Width or 180, 26),
		Theme = { BackgroundColor3 = "Field" },
		Parent = row.Accessory,
	})
	Corner(field, 6)
	local stroke = Stroke(field, "FieldStroke")
	local box = New("TextBox", {
		Name = "TextBox",
		Text = Input.Value,
		PlaceholderText = info.Placeholder or "",
		TextSize = 13,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -16, 1, 0),
		ClipsDescendants = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "Tertiary" },
		Parent = field,
	})
	if info.MaxLength then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if #box.Text > info.MaxLength then
				box.Text = box.Text:sub(1, info.MaxLength)
			end
		end)
	end

	function Input:SetValue(text)
		text = tostring(text or "")
		if self.Numeric and text ~= "" and not tonumber(text) then
			text = text:gsub("[^%d%.%-]", "")
		end
		self.Value = text
		if box.Text ~= text then
			box.Text = text
		end
		self:_Emit(text)
	end

	box:GetPropertyChangedSignal("Text"):Connect(function()
		if Input.Numeric then
			local cleaned = box.Text:gsub("[^%d%.%-]", "")
			if cleaned ~= box.Text then
				box.Text = cleaned
				return
			end
		end
		if not Input.Finished and box.Text ~= Input.Value then
			Input:SetValue(box.Text)
		end
	end)
	box.Focused:Connect(function()
		Themed(stroke, { Color = "Accent" })
		Tween(stroke, { Thickness = 2 }, 0.15)
	end)
	box.FocusLost:Connect(function(enterPressed)
		Themed(stroke, { Color = "FieldStroke" })
		Tween(stroke, { Thickness = 1 }, 0.15)
		if Input.Finished and (enterPressed or info.FinishOnFocusLost) then
			Input:SetValue(box.Text)
		end
	end)
	return Register(idx, Input)
end
Container.AddTextbox = Container.AddInput

function Container:AddKeybind(idx, info)
	idx, info = ParseArgs(idx, info)
	local row = CreateRow(self, info)
	local Keybind = NewElement("Keybind", row, info)
	Keybind.Value = info.Default and (typeof(info.Default) == "EnumItem" and info.Default.Name or tostring(info.Default)) or "None"
	Keybind.Mode = info.Mode or "Toggle"
	Keybind.Toggled = false
	Keybind.Picking = false
	Keybind.ChangedCallback = info.ChangedCallback
	local clicked = Signal.new()

	local capState = { Hovered = false }
	local cap = New("TextButton", {
		Name = "KeyCap",
		TextSize = 13,
		Weight = Enum.FontWeight.Medium,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		Theme = {
			BackgroundColor3 = function(t)
				return capState.Hovered and t.ControlHover or t.Control
			end,
			TextColor3 = function(t)
				return Keybind.Picking and t.SubText or t.Text
			end,
		},
		Parent = row.Accessory,
	})
	Corner(cap, 6)
	Padding(cap, 0, 10, 0, 10)
	local capStroke = Stroke(cap, function(t)
		return Keybind.Picking and MacUI.Accent or t.ControlStroke
	end)
	New("UISizeConstraint", { MinSize = Vector2.new(58, 24), Parent = cap })

	local function Render()
		cap.Text = Keybind.Picking and "Press a key…" or KeyName(Keybind.Value)
		Restyle(cap, 0.12)
		Restyle(capStroke, 0.12)
		capStroke.Thickness = Keybind.Picking and 2 or 1
	end

	local function Matches(input)
		if Keybind.Value == "None" then
			return false
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			return input.KeyCode.Name == Keybind.Value
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			return Keybind.Value == "MB1"
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			return Keybind.Value == "MB2"
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			return Keybind.Value == "MB3"
		end
		return false
	end

	function Keybind:GetState()
		if UserInputService:GetFocusedTextBox() and self.Mode ~= "Always" then
			return false
		end
		if self.Mode == "Always" then
			return true
		elseif self.Mode == "Hold" then
			if self.Value == "None" then
				return false
			elseif self.Value == "MB1" then
				return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			elseif self.Value == "MB2" then
				return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			end
			local ok, keycode = pcall(function()
				return Enum.KeyCode[self.Value]
			end)
			return ok and keycode and UserInputService:IsKeyDown(keycode) or false
		end
		return self.Toggled
	end

	function Keybind:SetValue(key, mode)
		if typeof(key) == "EnumItem" then
			key = key.Name
		end
		self.Value = key and tostring(key) or "None"
		self.Mode = mode or self.Mode
		Render()
		Spawn(self.ChangedCallback, self.Value)
		for _, fn in ipairs(self._listeners) do
			Spawn(fn, self.Value)
		end
	end

	function Keybind:OnClick(fn)
		return clicked:Connect(fn)
	end

	function Keybind:DoClick()
		Spawn(self.Callback, self.Toggled)
		clicked:Fire(self.Toggled)
	end

	cap.MouseEnter:Connect(function()
		capState.Hovered = true
		Restyle(cap, 0.12)
	end)
	cap.MouseLeave:Connect(function()
		capState.Hovered = false
		Restyle(cap, 0.18)
	end)
	cap.MouseButton1Click:Connect(function()
		if row.Disabled or Keybind.Picking then
			return
		end
		Keybind.Picking = true
		KeyCapture.Active = true
		Render()
		local connection
		connection = UserInputService.InputBegan:Connect(function(input)
			local key
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					key = Keybind.Value
				elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
					key = "None"
				else
					key = input.KeyCode.Name
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				-- clicking anywhere cancels, like the macOS shortcut recorder
				key = Keybind.Value
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				key = "MB2"
			elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
				key = "MB3"
			else
				return
			end
			connection:Disconnect()
			Keybind.Picking = false
			-- keep the guard up until every other handler has seen this key press
			task.delay(0.1, function()
				KeyCapture.Active = false
			end)
			local before = Keybind.Value
			Keybind.Value = key
			Render()
			if before ~= key then
				Keybind:SetValue(key)
			end
		end)
		table.insert(row.Connections, connection)
	end)

	local holding = false
	row:Connect(UserInputService.InputBegan, function(input)
		if Keybind.Picking or KeyCapture.Active or row.Disabled or UserInputService:GetFocusedTextBox() then
			return
		end
		if Matches(input) then
			if Keybind.Mode == "Toggle" then
				Keybind.Toggled = not Keybind.Toggled
			else
				Keybind.Toggled = true
				holding = Keybind.Mode == "Hold"
			end
			Keybind:DoClick()
		end
	end)
	row:Connect(UserInputService.InputEnded, function(input)
		if holding and Matches(input) then
			holding = false
			Keybind.Toggled = false
			Spawn(Keybind.Callback, false)
			clicked:Fire(false)
		end
	end)

	Render()
	return Register(idx, Keybind)
end

function Container:AddColorpicker(idx, info)
	idx, info = ParseArgs(idx, info)
	local row = CreateRow(self, info, { Clickable = true })
	local window = row.Window
	local Picker = NewElement("Colorpicker", row, info)
	Picker.Value = ResolveColor(info.Default) or MacUI.Accent
	Picker.Transparency = info.Transparency
	Picker.Hue, Picker.Sat, Picker.Vib = Picker.Value:ToHSV()

	local wellState = { Hovered = false }
	local well = New("TextButton", {
		Name = "ColorWell",
		Size = UDim2.fromOffset(46, 24),
		Theme = {
			BackgroundColor3 = function(t)
				return wellState.Hovered and t.ControlHover or t.Control
			end,
		},
		Parent = row.Accessory,
	})
	Corner(well, 7)
	Stroke(well, "ControlStroke", 1, 0.3)
	local swatch = New("Frame", {
		Name = "Swatch",
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.new(1, -6, 1, -6),
		BackgroundColor3 = Picker.Value,
		Parent = well,
	})
	Corner(swatch, 5)

	local listeners = {}
	function Picker:Display()
		swatch.BackgroundColor3 = self.Value
		swatch.BackgroundTransparency = self.Transparency or 0
		row.SearchExtra = "#" .. self.Value:ToHex()
		for _, fn in ipairs(listeners) do
			fn()
		end
	end

	function Picker:SetValueRGB(color, transparency)
		color = ResolveColor(color) or self.Value
		self.Value = color
		self.Hue, self.Sat, self.Vib = color:ToHSV()
		if transparency ~= nil then
			self.Transparency = transparency
		end
		self:Display()
		self:_Emit(self.Value)
	end

	function Picker:SetValue(hsv, transparency)
		if typeof(hsv) == "Color3" or type(hsv) == "string" then
			return self:SetValueRGB(hsv, transparency)
		end
		self.Hue, self.Sat, self.Vib = hsv[1], hsv[2], hsv[3]
		self.Value = Color3.fromHSV(hsv[1], hsv[2], hsv[3])
		if transparency ~= nil then
			self.Transparency = transparency
		end
		self:Display()
		self:_Emit(self.Value)
	end

	local function SetHSV(h, s, v)
		Picker.Hue, Picker.Sat, Picker.Vib = h, s, v
		Picker.Value = Color3.fromHSV(h, s, v)
		Picker:Display()
		Picker:_Emit(Picker.Value)
	end

	local function OpenPicker()
		if row.Disabled then
			return
		end
		local hasAlpha = Picker.Transparency ~= nil
		-- inner layout: SV box 0-140, hue 152-164, alpha 176-188, hex row, presets
		local rowY = (hasAlpha and 188 or 164) + 14
		local presetsY = rowY + 26 + 12
		local height = presetsY + 18 + 24
		window:_OpenPopup(well, 240, height, function(canvas, popover)
			local inner = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Parent = canvas,
			})
			Padding(inner, 12, 12, 12, 12)

			local sv = New("Frame", {
				Name = "SaturationValue",
				Size = UDim2.new(1, 0, 0, 140),
				Parent = inner,
			})
			Corner(sv, 8)
			local white = New("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = sv,
			})
			Corner(white, 8)
			New("UIGradient", {
				Transparency = NumberSequence.new(0, 1),
				Parent = white,
			})
			local black = New("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				ZIndex = 2,
				Parent = sv,
			})
			Corner(black, 8)
			New("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new(1, 0),
				Parent = black,
			})
			local svCursor = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				ZIndex = 3,
				Parent = sv,
			})
			Corner(svCursor, 7)
			New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = svCursor })

			local hue = New("Frame", {
				Name = "Hue",
				Position = UDim2.fromOffset(0, 152),
				Size = UDim2.new(1, 0, 0, 12),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = inner,
			})
			Corner(hue, 6)
			local keypoints = {}
			for i = 0, 6 do
				table.insert(keypoints, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1, 1, 1)))
			end
			New("UIGradient", { Color = ColorSequence.new(keypoints), Parent = hue })
			local hueCursor = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(16, 16),
				ZIndex = 2,
				Parent = hue,
			})
			Corner(hueCursor, 8)
			New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = hueCursor })

			local alpha, alphaFill, alphaCursor
			if hasAlpha then
				alpha = New("Frame", {
					Name = "Alpha",
					Position = UDim2.fromOffset(0, 176),
					Size = UDim2.new(1, 0, 0, 12),
					Theme = { BackgroundColor3 = "Track" },
					Parent = inner,
				})
				Corner(alpha, 6)
				alphaFill = New("Frame", {
					Name = "Fill",
					Size = UDim2.fromScale(1, 1),
					Parent = alpha,
				})
				Corner(alphaFill, 6)
				New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = alphaFill })
				alphaCursor = New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromOffset(16, 16),
					ZIndex = 2,
					Theme = { BackgroundColor3 = "Knob" },
					Parent = alpha,
				})
				Corner(alphaCursor, 8)
				New("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.75, Parent = alphaCursor })
			end

			local preview = New("Frame", {
				Name = "Preview",
				Position = UDim2.fromOffset(0, rowY),
				Size = UDim2.fromOffset(26, 26),
				Parent = inner,
			})
			Corner(preview, 6)
			Stroke(preview, "FieldStroke")
			local hexField = New("Frame", {
				Position = UDim2.fromOffset(36, rowY),
				Size = UDim2.new(1, -36, 0, 26),
				Theme = { BackgroundColor3 = "Field" },
				Parent = inner,
			})
			Corner(hexField, 6)
			local hexStroke = Stroke(hexField, "FieldStroke")
			local hexBox = New("TextBox", {
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -16, 1, 0),
				TextSize = 13,
				Theme = { TextColor3 = "Text" },
				Parent = hexField,
			})
			New("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 0),
				Size = UDim2.new(0, 40, 1, 0),
				Text = "HEX",
				TextSize = 11,
				Weight = Enum.FontWeight.Medium,
				TextXAlignment = Enum.TextXAlignment.Right,
				Theme = { TextColor3 = "Tertiary" },
				Parent = hexField,
			})
			local presets = New("Frame", {
				Name = "Presets",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, presetsY),
				Size = UDim2.new(1, 0, 0, 18),
				Parent = inner,
			})
			List(presets, Enum.FillDirection.Horizontal, 9, { VerticalAlignment = Enum.VerticalAlignment.Center })
			for index, name in ipairs(MacUI.AccentOrder) do
				local color = MacUI.Accents[name]
				local dot = New("TextButton", {
					Name = name,
					Size = UDim2.fromOffset(18, 18),
					BackgroundTransparency = 0,
					BackgroundColor3 = color,
					LayoutOrder = index,
					Parent = presets,
				})
				Corner(dot, 9)
				New("UIStroke", { Color = Darken(color, 0.25), Transparency = 0.4, Parent = dot })
				dot.MouseButton1Click:Connect(function()
					Picker:SetValueRGB(color)
				end)
			end

			local function Refresh()
				sv.BackgroundColor3 = Color3.fromHSV(Picker.Hue, 1, 1)
				svCursor.Position = UDim2.fromScale(Picker.Sat, 1 - Picker.Vib)
				svCursor.BackgroundColor3 = Picker.Value
				hueCursor.Position = UDim2.fromScale(Picker.Hue, 0.5)
				hueCursor.BackgroundColor3 = Color3.fromHSV(Picker.Hue, 1, 1)
				preview.BackgroundColor3 = Picker.Value
				preview.BackgroundTransparency = Picker.Transparency or 0
				if not hexBox:IsFocused() then
					hexBox.Text = "#" .. Picker.Value:ToHex():upper()
				end
				if alpha then
					alphaFill.BackgroundColor3 = Picker.Value
					alphaCursor.Position = UDim2.fromScale(Picker.Transparency or 0, 0.5)
				end
			end
			table.insert(listeners, Refresh)
			popover.OnClose = function()
				local index = table.find(listeners, Refresh)
				if index then
					table.remove(listeners, index)
				end
			end
			Refresh()

			local dragging
			local function Update(position)
				if dragging == "sv" then
					local s = math.clamp((position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
					local v = 1 - math.clamp((position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
					SetHSV(Picker.Hue, s, v)
				elseif dragging == "hue" then
					local h = math.clamp((position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 0.999)
					SetHSV(h, Picker.Sat, Picker.Vib)
				elseif dragging == "alpha" then
					Picker.Transparency = Round(math.clamp((position.X - alpha.AbsolutePosition.X) / alpha.AbsoluteSize.X, 0, 1), 2)
					Picker:Display()
					Picker:_Emit(Picker.Value)
				end
			end
			local function Begin(kind)
				return function(input)
					if IsPointer(input) then
						dragging = kind
						Update(input.Position)
					end
				end
			end
			sv.InputBegan:Connect(Begin("sv"))
			hue.InputBegan:Connect(Begin("hue"))
			if alpha then
				alpha.InputBegan:Connect(Begin("alpha"))
			end
			popover:Connect(UserInputService.InputChanged, function(input)
				if dragging and IsMove(input) then
					Update(input.Position)
				end
			end)
			popover:Connect(UserInputService.InputEnded, function(input)
				if IsPointer(input) then
					dragging = nil
				end
			end)
			hexBox.Focused:Connect(function()
				Themed(hexStroke, { Color = "Accent" })
			end)
			hexBox.FocusLost:Connect(function()
				Themed(hexStroke, { Color = "FieldStroke" })
				local text = hexBox.Text:gsub("#", ""):gsub("%s", "")
				local ok, color = pcall(Color3.fromHex, text)
				if ok and color then
					Picker:SetValueRGB(color)
				else
					Refresh()
				end
			end)
		end)
	end

	well.MouseEnter:Connect(function()
		wellState.Hovered = true
		Restyle(well, 0.12)
	end)
	well.MouseLeave:Connect(function()
		wellState.Hovered = false
		Restyle(well, 0.18)
	end)
	well.MouseButton1Click:Connect(OpenPicker)
	row.OnClick = OpenPicker

	Picker:Display()
	return Register(idx, Picker)
end
Container.AddColorPicker = Container.AddColorpicker

function Container:AddSegmented(idx, info)
	idx, info = ParseArgs(idx, info)
	local row = CreateRow(self, info)
	local window = row.Window
	local Segmented = NewElement("Segmented", row, info)
	Segmented.Values = info.Values or {}
	local default = info.Default
	if type(default) == "number" then
		default = Segmented.Values[default]
	end
	Segmented.Value = default or Segmented.Values[1]

	local control = New("Frame", {
		Name = "Segmented",
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Theme = { BackgroundColor3 = "SegmentBg" },
		Parent = row.Accessory,
	})
	Corner(control, 7)
	local pill = New("Frame", {
		Name = "Selection",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.fromOffset(0, 22),
		Theme = { BackgroundColor3 = "SegmentSelected" },
		Parent = control,
	})
	Corner(pill, 6)
	New("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.9, Parent = pill })
	local items = New("Frame", {
		Name = "Items",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 2,
		Parent = control,
	})
	List(items, Enum.FillDirection.Horizontal, 0)
	Padding(items, 0, 2, 0, 2)

	local buttons = {}
	local function MovePill(duration)
		local button = buttons[Segmented.Value]
		if not button then
			pill.Visible = false
			return
		end
		pill.Visible = true
		local scale = window:GetAbsoluteScale()
		local x = (button.AbsolutePosition.X - control.AbsolutePosition.X) / scale
		local width = button.AbsoluteSize.X / scale
		local goal = { Position = UDim2.fromOffset(x, 2), Size = UDim2.fromOffset(width, 22) }
		if duration == 0 or pill.Size.X.Offset == 0 then
			pill.Position = goal.Position
			pill.Size = goal.Size
		else
			Tween(pill, goal, duration or 0.25, Enum.EasingStyle.Quint)
		end
	end

	local function Build()
		for _, button in pairs(buttons) do
			button:Destroy()
		end
		table.clear(buttons)
		for index, value in ipairs(Segmented.Values) do
			local button = New("TextButton", {
				Name = tostring(value),
				Text = tostring(value),
				TextSize = 13,
				Weight = Enum.FontWeight.Medium,
				Size = UDim2.fromOffset(0, 26),
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = index,
				Theme = { TextColor3 = "Text" },
				Parent = items,
			})
			Padding(button, 0, 14, 0, 14)
			buttons[value] = button
			button.MouseButton1Click:Connect(function()
				if not row.Disabled then
					Segmented:SetValue(value)
				end
			end)
			button:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				if Segmented.Value == value then
					MovePill(0)
				end
			end)
			button:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				if Segmented.Value == value then
					MovePill(0)
				end
			end)
		end
		MovePill(0)
	end

	function Segmented:SetValue(value)
		if not table.find(self.Values, value) then
			return
		end
		self.Value = value
		MovePill()
		self:_Emit(value)
	end

	function Segmented:SetValues(values)
		self.Values = values or {}
		if not table.find(self.Values, self.Value) then
			self.Value = self.Values[1]
		end
		Build()
	end

	Build()
	return Register(idx, Segmented)
end
Container.AddSegmentedControl = Container.AddSegmented

function Container:AddProgress(idx, info)
	idx, info = ParseArgs(idx, info)
	local row = CreateRow(self, info)
	local Progress = NewElement("Progress", row, info)
	Progress.Max = tonumber(info.Max) or 100
	Progress.Value = math.clamp(tonumber(info.Default or info.Value) or 0, 0, Progress.Max)

	local bar = New("Frame", {
		Name = "Progress",
		Size = UDim2.fromOffset(info.Width or 150, 6),
		LayoutOrder = 1,
		Theme = { BackgroundColor3 = "Track" },
		Parent = row.Accessory,
	})
	Corner(bar, 3)
	local fill = New("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		Theme = { BackgroundColor3 = "Accent" },
		Parent = bar,
	})
	Corner(fill, 3)
	local label = New("TextLabel", {
		Name = "Percent",
		TextSize = 13,
		Size = UDim2.fromOffset(38, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
		LayoutOrder = 2,
		Theme = { TextColor3 = "SubText" },
		Parent = row.Accessory,
	})

	function Progress:SetValue(value)
		self.Value = math.clamp(tonumber(value) or 0, 0, self.Max)
		local alpha = self.Max == 0 and 0 or self.Value / self.Max
		Tween(fill, { Size = UDim2.fromScale(alpha, 1) }, 0.35)
		label.Text = math.floor(alpha * 100 + 0.5) .. "%"
		self:_Emit(self.Value)
	end

	Progress:SetValue(Progress.Value)
	return Register(idx, Progress)
end
Container.AddProgressBar = Container.AddProgress

--------------------------------------------------------------------------------
-- Groups, sections and tabs
--------------------------------------------------------------------------------

local GroupMethods = {}
GroupMethods.__index = GroupMethods

local function CreateGroup(tab, block)
	local group = setmetatable({ Tab = tab, Block = block, Rows = {}, Order = 0 }, GroupMethods)
	group.Frame = New("Frame", {
		Name = "Group",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = tab:_NextOrder(),
		Visible = false,
		Theme = { BackgroundColor3 = "Group" },
		Parent = tab.Content,
	})
	Corner(group.Frame, 10)
	Stroke(group.Frame, "GroupStroke")
	List(group.Frame, nil, 0)
	return group
end

function GroupMethods:Refresh()
	local first = true
	for _, row in ipairs(self.Rows) do
		if row.Frame.Visible then
			row.Separator.Visible = not first
			first = false
		end
	end
	local visible = not first
	self.Frame.Visible = visible
	if self.Block.Header then
		self.Block.Header.Visible = visible
	end
	self.Tab:_RefreshSpacers()
end

local TabMethods = setmetatable({}, { __index = Container })
TabMethods.__index = TabMethods

local SectionMethods = setmetatable({}, { __index = Container })
SectionMethods.__index = SectionMethods

function TabMethods:_NextOrder()
	self.Order += 1
	return self.Order
end

function TabMethods:_NewBlock(spacing)
	local block = {}
	block.Spacer = New("Frame", {
		Name = "Spacer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, spacing),
		LayoutOrder = self:_NextOrder(),
		Parent = self.Content,
	})
	block.Spacing = spacing
	table.insert(self.Blocks, block)
	return block
end

function TabMethods:_RefreshSpacers()
	local first = true
	for _, block in ipairs(self.Blocks) do
		local visible = block.Group and block.Group.Frame.Visible
		block.Spacer.Visible = visible and not first
		if visible then
			first = false
		end
	end
end

function TabMethods:_GetGroup()
	if not self.CurrentGroup then
		local block = self:_NewBlock(16)
		block.Group = CreateGroup(self, block)
		self.CurrentGroup = block.Group
	end
	return self.CurrentGroup
end

function TabMethods:AddSection(info)
	if type(info) ~= "table" then
		info = { Title = tostring(info or "") }
	end
	local window = self.Window
	local block = self:_NewBlock(22)
	local header = New("Frame", {
		Name = "SectionHeader",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_NextOrder(),
		Visible = false,
		Parent = self.Content,
	})
	Padding(header, 0, 12, 8, 12)
	List(header, nil, 2)
	local titleRow = New("Frame", {
		Name = "TitleRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 1,
		Parent = header,
	})
	local offset = 0
	if info.Icon and MacUI:GetIcon(info.Icon) then
		IconImage({
			Name = "Icon",
			Icon = info.Icon,
			IconSize = 16,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Theme = { ImageColor3 = info.IconColor and function()
				return ResolveColor(info.IconColor)
			end or "Accent" },
			Parent = titleRow,
		})
		offset = 22
	end
	local titleLabel = New("TextLabel", {
		Name = "Title",
		Text = info.Title or "",
		TextSize = 15,
		Weight = Enum.FontWeight.Bold,
		Position = UDim2.fromOffset(offset, 0),
		Size = UDim2.new(1, -offset, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Text" },
		Parent = titleRow,
	})
	local descLabel = New("TextLabel", {
		Name = "Description",
		Text = info.Description or "",
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		RichText = true,
		LayoutOrder = 2,
		Visible = (info.Description or "") ~= "",
		Theme = { TextColor3 = "SubText" },
		Parent = header,
	})
	block.Header = header
	block.SearchText = ((info.Title or "") .. " " .. (info.Description or "")):lower()
	block.Group = CreateGroup(self, block)
	self.CurrentGroup = nil

	local section = setmetatable({
		Window = window,
		Tab = self,
		Title = info.Title,
		Block = block,
		Group = block.Group,
	}, SectionMethods)
	function section:SetTitle(text)
		self.Title = text
		titleLabel.Text = tostring(text)
		block.SearchText = (tostring(text) .. " " .. descLabel.Text):lower()
	end
	function section:SetDesc(text)
		descLabel.Text = tostring(text or "")
		descLabel.Visible = descLabel.Text ~= ""
		block.SearchText = (titleLabel.Text .. " " .. descLabel.Text):lower()
	end
	return section
end

function SectionMethods:_GetGroup()
	return self.Group
end

function TabMethods:_ApplySearch(query)
	local count = 0
	for _, block in ipairs(self.Blocks) do
		if block.Group then
			local sectionHit = query ~= "" and block.SearchText ~= nil and block.SearchText:find(query, 1, true) ~= nil
			for _, row in ipairs(block.Group.Rows) do
				row.SearchMatch = query == "" or sectionHit or row:_Matches(query)
				row.Frame.Visible = row.UserVisible and row.SearchMatch
				if row.Frame.Visible then
					count += 1
				end
			end
			block.Group:Refresh()
		end
	end
	return count
end

function TabMethods:Select()
	self.Window:SelectTab(self)
end

function TabMethods:SetTitle(text)
	self.Title = tostring(text)
	self.Label.Text = self.Title
end

function TabMethods:SetBadge(value)
	local text = value ~= nil and value ~= false and value ~= 0 and tostring(value) or nil
	self.Badge.Visible = text ~= nil
	self.BadgeLabel.Text = text or ""
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local function SizeFromConfig(value, fallback)
	if typeof(value) == "UDim2" then
		return Vector2.new(value.X.Offset, value.Y.Offset)
	elseif typeof(value) == "Vector2" then
		return value
	end
	return fallback
end

function MacUI:CreateWindow(config)
	config = config or {}
	if config.Theme and self.Themes[config.Theme] then
		self:SetTheme(config.Theme, true)
	end
	if config.Accent then
		self:SetAccent(config.Accent, true)
	end
	if config.Font then
		self:SetFont(config.Font)
	end

	local size = SizeFromConfig(config.Size, Vector2.new(780, 540))
	local minSize = SizeFromConfig(config.MinSize, Vector2.new(560, 380))
	local sidebarWidth = math.max(config.TabWidth or config.SidebarWidth or 214, 150)
	local sidebarStyle = config.SidebarStyle or "Tile"
	local toolbarHeight = 52

	local Window = {
		Title = tostring(config.Title or "MacUI"),
		SubTitle = tostring(config.SubTitle or config.Subtitle or ""),
		Tabs = {},
		History = {},
		HistoryIndex = 0,
		Minimized = false,
		Maximized = false,
		SidebarVisible = true,
		SearchQuery = "",
		MinimizeKey = config.MinimizeKey or Enum.KeyCode.RightControl,
		Scale = 1,
		Size = size,
		Connections = {},
	}
	table.insert(self.Windows, Window)

	local function Connect(signal, fn)
		local connection = signal:Connect(fn)
		table.insert(Window.Connections, connection)
		return connection
	end

	local ScreenGui = New("ScreenGui", {
		Name = "MacUI",
		ResetOnSpawn = false,
		DisplayOrder = config.DisplayOrder or 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	ParentGui(ScreenGui)
	Window.ScreenGui = ScreenGui

	-- Root: positioned & scaled container; Holder: the visible window.
	local Root = New("Frame", {
		Name = "Window",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		Parent = ScreenGui,
	})
	local RootScale = New("UIScale", { Scale = 1, Parent = Root })
	local ScaleTween

	-- The scale currently applied on screen (differs from Window.Scale mid-animation).
	function Window:GetAbsoluteScale()
		return RootScale.Scale
	end
	local WindowShadow = Shadow(Root, 44)
	local AnimGroup = New("CanvasGroup", {
		Name = "Transition",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 2,
		Parent = Root,
	})
	local Holder = New("Frame", {
		Name = "Holder",
		Size = UDim2.fromScale(1, 1),
		Active = true, -- clicks on the window never reach the game world
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Root,
	})
	Corner(Holder, 12)
	Stroke(Holder, "WindowStroke", 1, 0.1)

	-- Popups (menus, color picker) render above everything in this window.
	local PopupLayer = New("Frame", {
		Name = "Popups",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Parent = ScreenGui,
	})
	Window.PopupLayer = PopupLayer

	----------------------------------------------------------------------------
	-- Sidebar
	----------------------------------------------------------------------------

	local Sidebar = New("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		ClipsDescendants = true,
		Theme = { BackgroundColor3 = "Sidebar" },
		Parent = Holder,
	})
	Corner(Sidebar, 12)
	New("Frame", {
		Name = "Square",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 14, 1, 0),
		Theme = { BackgroundColor3 = "Sidebar" },
		Parent = Sidebar,
	})
	New("Frame", {
		Name = "Divider",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 1, 1, 0),
		ZIndex = 3,
		Theme = { BackgroundColor3 = "SidebarDivider" },
		Parent = Sidebar,
	})
	local SidebarInner = New("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		ZIndex = 2,
		Parent = Sidebar,
	})
	local SidebarDrag = New("Frame", {
		Name = "DragArea",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, toolbarHeight),
		Parent = SidebarInner,
	})

	local listTop = toolbarHeight
	if config.Profile then
		local profile = type(config.Profile) == "table" and config.Profile or {}
		local card = New("Frame", {
			Name = "Profile",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, toolbarHeight - 2),
			Size = UDim2.new(1, -20, 0, 54),
			Parent = SidebarInner,
		})
		local avatar = New("ImageLabel", {
			Name = "Avatar",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.fromOffset(38, 38),
			BackgroundTransparency = 0,
			ScaleType = Enum.ScaleType.Crop,
			Image = profile.Image or "",
			Theme = { BackgroundColor3 = "Control" },
			Parent = card,
		})
		Corner(avatar, 19)
		if not profile.Image and LocalPlayer then
			task.spawn(function()
				local ok, image = pcall(function()
					return Players:GetUserThumbnailAsync(
						LocalPlayer.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size150x150
					)
				end)
				if ok and image then
					avatar.Image = image
				end
			end)
		end
		New("TextLabel", {
			Name = "Name",
			Text = profile.Title or (LocalPlayer and LocalPlayer.DisplayName) or "Player",
			TextSize = 14,
			Weight = Enum.FontWeight.SemiBold,
			Position = UDim2.new(0, 54, 0.5, -17),
			Size = UDim2.new(1, -58, 0, 18),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Theme = { TextColor3 = "Text" },
			Parent = card,
		})
		New("TextLabel", {
			Name = "Subtitle",
			Text = profile.Subtitle or (LocalPlayer and ("@" .. LocalPlayer.Name)) or "",
			TextSize = 12,
			Position = UDim2.new(0, 54, 0.5, 1),
			Size = UDim2.new(1, -58, 0, 16),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Theme = { TextColor3 = "SubText" },
			Parent = card,
		})
		listTop += 58
	end

	local TabScroll = New("ScrollingFrame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(0, listTop),
		Size = UDim2.new(1, 0, 1, -listTop),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0,
		Parent = SidebarInner,
	})
	local Pill = New("Frame", {
		Name = "Selection",
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 0, 30),
		Visible = false,
		ZIndex = 1,
		Theme = { BackgroundColor3 = "Accent" },
		Parent = TabScroll,
	})
	Corner(Pill, 7)
	local TabList = New("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
		Parent = TabScroll,
	})
	Padding(TabList, 2, 10, 12, 10)
	List(TabList, nil, 2)
	local TabOrder = 0
	local function NextTabOrder()
		TabOrder += 1
		return TabOrder
	end

	----------------------------------------------------------------------------
	-- Main area: toolbar + pages
	----------------------------------------------------------------------------

	local Main = New("Frame", {
		Name = "Main",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(sidebarWidth, 0),
		Size = UDim2.new(1, -sidebarWidth, 1, 0),
		Parent = Holder,
	})
	local Toolbar = New("Frame", {
		Name = "Toolbar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, toolbarHeight),
		ZIndex = 3,
		Parent = Main,
	})
	local ToolbarDivider = New("Frame", {
		Name = "Divider",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 1,
		Theme = { BackgroundColor3 = "Separator" },
		Parent = Toolbar,
	})
	local Leading = New("Frame", {
		Name = "Leading",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = Toolbar,
	})
	List(Leading, Enum.FillDirection.Horizontal, 2, { VerticalAlignment = Enum.VerticalAlignment.Center })

	local function ToolbarButton(icon, order, iconSize)
		local state = { Hovered = false, Enabled = true }
		local button = New("TextButton", {
			Name = icon,
			Size = UDim2.fromOffset(30, 28),
			LayoutOrder = order,
			Theme = {
				BackgroundColor3 = "Hover",
				BackgroundTransparency = function(t)
					return (state.Hovered and state.Enabled) and t.HoverTransparency - 0.02 or 1
				end,
			},
			Parent = Leading,
		})
		Corner(button, 6)
		local image = IconImage({
			Icon = icon,
			IconSize = iconSize or 18,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Theme = {
				ImageColor3 = function(t)
					return state.Enabled and t.SubText or t.Tertiary
				end,
				ImageTransparency = function()
					return state.Enabled and 0 or 0.35
				end,
			},
			Parent = button,
		})
		button.MouseEnter:Connect(function()
			state.Hovered = true
			Restyle(button, 0.12)
		end)
		button.MouseLeave:Connect(function()
			state.Hovered = false
			Restyle(button, 0.18)
		end)
		local function SetEnabled(enabled)
			state.Enabled = enabled
			Restyle(button, 0.15)
			Restyle(image, 0.15)
		end
		return button, SetEnabled
	end

	local SidebarButton = ToolbarButton("sidebar", 1, 18)
	New("Frame", { Name = "Gap", BackgroundTransparency = 1, Size = UDim2.fromOffset(8, 1), LayoutOrder = 2, Parent = Leading })
	local BackButton, SetBackEnabled = ToolbarButton("chevron-left", 3, 20)
	local ForwardButton, SetForwardEnabled = ToolbarButton("chevron-right", 4, 20)
	New("Frame", { Name = "Gap", BackgroundTransparency = 1, Size = UDim2.fromOffset(8, 1), LayoutOrder = 5, Parent = Leading })

	local TitleStack = New("Frame", {
		Name = "Titles",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 6,
		Parent = Leading,
	})
	List(TitleStack, nil, 0, { VerticalAlignment = Enum.VerticalAlignment.Center })
	local TitleLabel = New("TextLabel", {
		Name = "Title",
		Text = Window.Title,
		TextSize = 15,
		Weight = Enum.FontWeight.Bold,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
		Theme = { TextColor3 = "Text" },
		Parent = TitleStack,
	})
	local SubtitleLabel = New("TextLabel", {
		Name = "Subtitle",
		Text = Window.SubTitle,
		TextSize = 12,
		Size = UDim2.fromOffset(0, 15),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Visible = Window.SubTitle ~= "",
		Theme = { TextColor3 = "SubText" },
		Parent = TitleStack,
	})

	-- Search field
	local SearchWidth = config.SearchWidth or 180
	local Search = New("Frame", {
		Name = "Search",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(SearchWidth, 28),
		Visible = config.Search ~= false,
		Theme = { BackgroundColor3 = "Search" },
		Parent = Toolbar,
	})
	Corner(Search, 7)
	local SearchStroke = Stroke(Search, "Accent", 3, 1)
	IconImage({
		Icon = "search",
		IconSize = 14,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 9, 0.5, 0),
		Theme = { ImageColor3 = "SubText" },
		Parent = Search,
	})
	local SearchBox = New("TextBox", {
		Name = "Query",
		Text = "",
		PlaceholderText = config.SearchPlaceholder or "Search",
		TextSize = 13,
		Position = UDim2.fromOffset(29, 0),
		Size = UDim2.new(1, -54, 1, 0),
		ClipsDescendants = true,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
		Parent = Search,
	})
	local SearchClear = New("TextButton", {
		Name = "Clear",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 0,
		Visible = false,
		Theme = { BackgroundColor3 = "Tertiary" },
		Parent = Search,
	})
	Corner(SearchClear, 8)
	IconImage({
		Icon = "x",
		IconSize = 10,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Theme = { ImageColor3 = "Search" },
		Parent = SearchClear,
	})

	local PageHost = New("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, toolbarHeight),
		Size = UDim2.new(1, 0, 1, -toolbarHeight),
		ClipsDescendants = true,
		Parent = Main,
	})
	local PageFade = New("Frame", {
		Name = "Fade",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Theme = { BackgroundColor3 = "Background" },
		Parent = PageHost,
	})
	local EmptyState = New("Frame", {
		Name = "NoResults",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(1, -40, 0, 110),
		Visible = false,
		ZIndex = 5,
		Parent = PageHost,
	})
	IconImage({
		Icon = "search",
		IconSize = 34,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Theme = { ImageColor3 = "Tertiary" },
		Parent = EmptyState,
	})
	local EmptyTitle = New("TextLabel", {
		Text = "No Results",
		TextSize = 17,
		Weight = Enum.FontWeight.Bold,
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Text" },
		Parent = EmptyState,
	})
	New("TextLabel", {
		Text = "Check the spelling or try a new search.",
		TextSize = 13,
		Position = UDim2.fromOffset(0, 74),
		Size = UDim2.new(1, 0, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Center,
		Theme = { TextColor3 = "SubText" },
		Parent = EmptyState,
	})

	----------------------------------------------------------------------------
	-- Traffic lights
	----------------------------------------------------------------------------

	local Lights = New("Frame", {
		Name = "TrafficLights",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 20),
		Size = UDim2.fromOffset(52, 12),
		ZIndex = 20,
		Parent = Holder,
	})
	local LightGlyphs = {}
	local LightButtons = {}
	for index, spec in ipairs(TRAFFIC) do
		local button = New("TextButton", {
			Name = spec.Name,
			Position = UDim2.fromOffset((index - 1) * 20, 0),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 0,
			BackgroundColor3 = spec.Color,
			ZIndex = 21,
			Parent = Lights,
		})
		Corner(button, 6)
		New("UIStroke", { Color = spec.Stroke, Thickness = 1, Transparency = 0.45, Parent = button })
		local glyphs = {}
		local function Bar(rotation, width)
			local bar = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(width, 1),
				Rotation = rotation,
				BackgroundColor3 = spec.Glyph,
				BackgroundTransparency = 1,
				ZIndex = 22,
				Parent = button,
			})
			table.insert(glyphs, bar)
		end
		if spec.Name == "Close" then
			Bar(45, 8)
			Bar(-45, 8)
		elseif spec.Name == "Minimize" then
			Bar(0, 7)
		else
			Bar(0, 7)
			Bar(90, 7)
		end
		LightGlyphs[spec.Name] = glyphs
		LightButtons[spec.Name] = button
	end
	Lights.MouseEnter:Connect(function()
		for _, glyphs in pairs(LightGlyphs) do
			for _, bar in ipairs(glyphs) do
				Tween(bar, { BackgroundTransparency = 0.15 }, 0.12)
			end
		end
	end)
	Lights.MouseLeave:Connect(function()
		for _, glyphs in pairs(LightGlyphs) do
			for _, bar in ipairs(glyphs) do
				Tween(bar, { BackgroundTransparency = 1 }, 0.15)
			end
		end
	end)

	----------------------------------------------------------------------------
	-- Dock icon shown while minimised
	----------------------------------------------------------------------------

	local Dock = New("TextButton", {
		Name = "Dock",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 90),
		Size = UDim2.fromOffset(64, 64),
		Visible = false,
		ZIndex = 5,
		Parent = ScreenGui,
	})
	local DockScale = New("UIScale", { Scale = 1, Parent = Dock })
	Shadow(Dock, 20)
	local DockBody = New("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.08,
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Menu" },
		Parent = Dock,
	})
	Corner(DockBody, 18)
	Stroke(DockBody, "MenuStroke", 1, 0.2)
	IconTile(DockBody, config.Icon or "command", ResolveColor(config.IconColor) or function()
		return MacUI.Accent
	end, 48, 12, 26, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
	local DockDot = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 4),
		Size = UDim2.fromOffset(4, 4),
		Theme = { BackgroundColor3 = "Text" },
		Parent = Dock,
	})
	Corner(DockDot, 2)
	local DockTip = New("TextLabel", {
		Name = "Tooltip",
		Text = Window.Title,
		TextSize = 13,
		Weight = Enum.FontWeight.Medium,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -10),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 0,
		Visible = false,
		Theme = { BackgroundColor3 = "Menu", TextColor3 = "Text" },
		Parent = Dock,
	})
	Corner(DockTip, 6)
	Padding(DockTip, 0, 10, 0, 10)
	Stroke(DockTip, "MenuStroke", 1, 0.2)

	----------------------------------------------------------------------------
	-- Scale
	----------------------------------------------------------------------------

	function Window:SetScale(scale)
		scale = math.clamp(tonumber(scale) or 1, 0.4, 2)
		self.Scale = scale
		if ScaleTween then
			ScaleTween:Cancel()
			ScaleTween = nil
		end
		RootScale.Scale = scale
		DockScale.Scale = scale
		if self._ClosePopup then
			self:_ClosePopup(true)
		end
		for _, tab in ipairs(self.Tabs) do
			for _, row in ipairs(tab.Rows) do
				row:_UpdateReserve()
			end
		end
	end

	local function AutoScale()
		local viewport = ScreenGui.AbsoluteSize
		if viewport.X < 10 or viewport.Y < 10 then
			viewport = Viewport() - Vector2.new(0, GuiService:GetGuiInset().Y)
		end
		local fit = math.min((viewport.X - 32) / size.X, (viewport.Y - 32) / size.Y, 1)
		return math.max(fit, 0.5)
	end
	Window:SetScale(config.Scale or AutoScale())

	----------------------------------------------------------------------------
	-- Popups
	----------------------------------------------------------------------------

	function Window:_ClosePopup(instant)
		local popup = self.ActivePopup
		if not popup then
			return
		end
		self.ActivePopup = nil
		popup.Shown = false
		for _, connection in ipairs(popup.Connections) do
			connection:Disconnect()
		end
		SafeCall(popup.OnClose)
		popup.Catcher:Destroy()
		if instant then
			popup.Holder:Destroy()
			return
		end
		Tween(popup.Canvas, { GroupTransparency = 1 }, 0.14)
		Restyle(popup.Shadow, 0.14)
		Tween(popup.Scale, { Scale = self.Scale * 0.97 }, 0.14)
		task.delay(0.15, function()
			popup.Holder:Destroy()
		end)
	end

	function Window:_OpenPopup(anchor, width, height, build, options)
		options = options or {}
		self:_ClosePopup(true)
		local scale = self.Scale
		local popup = { Connections = {} }
		function popup:Connect(signal, fn)
			local connection = signal:Connect(fn)
			table.insert(popup.Connections, connection)
			return connection
		end
		popup.Catcher = New("TextButton", {
			Name = "Dismiss",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 1,
			Parent = PopupLayer,
		})
		popup.Holder = New("Frame", {
			Name = "Popover",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(width, height),
			ZIndex = 2,
			Parent = PopupLayer,
		})
		popup.Scale = New("UIScale", { Scale = scale * 0.96, Parent = popup.Holder })
		-- Frames don't sink clicks; without this the dismiss catcher underneath
		-- would close the popover when clicking its background or colour square.
		New("TextButton", {
			Name = "Sink",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 1,
			Parent = popup.Holder,
		})
		popup.Shadow = Shadow(popup.Holder, 24, function(t)
			return popup.Shown and t.ShadowTransparency + 0.2 or 1
		end)
		popup.Canvas = New("CanvasGroup", {
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			GroupTransparency = 1,
			ZIndex = 2,
			Theme = { BackgroundColor3 = "Menu" },
			Parent = popup.Holder,
		})
		Corner(popup.Canvas, 10)
		local border = New("Frame", {
			Name = "Border",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.new(1, -2, 1, -2),
			ZIndex = 50,
			Parent = popup.Canvas,
		})
		Corner(border, 9)
		Stroke(border, "MenuStroke", 1, 0.1)

		local layerPos = PopupLayer.AbsolutePosition
		local screen = PopupLayer.AbsoluteSize
		local anchorPos = anchor.AbsolutePosition - layerPos
		local anchorSize = anchor.AbsoluteSize
		local w, h = width * scale, height * scale
		local x = options.Align == "Left" and anchorPos.X or (anchorPos.X + anchorSize.X - w)
		x = math.clamp(x, 8, math.max(screen.X - w - 8, 8))
		local y = anchorPos.Y + anchorSize.Y + 6 * scale
		if y + h > screen.Y - 8 then
			y = anchorPos.Y - h - 6 * scale
		end
		y = math.clamp(y, 8, math.max(screen.Y - h - 8, 8))
		popup.Holder.Position = UDim2.fromOffset(x, y)

		self.ActivePopup = popup
		popup.Catcher.MouseButton1Click:Connect(function()
			self:_ClosePopup()
		end)
		popup.Catcher.MouseButton2Click:Connect(function()
			self:_ClosePopup()
		end)

		build(popup.Canvas, popup)

		popup.Shown = true
		Tween(popup.Canvas, { GroupTransparency = 0 }, 0.16)
		Restyle(popup.Shadow, 0.2)
		Tween(popup.Scale, { Scale = scale }, 0.2, Enum.EasingStyle.Back)
		return popup
	end

	function Window:_OpenMenu(anchor, options)
		local values = options.Values or {}
		local itemHeight = 26
		local searchable = options.Searchable
		if searchable == nil then
			searchable = #values > 10
		end
		local widest = 0
		for _, value in ipairs(values) do
			widest = math.max(widest, MeasureText(tostring(value), 14))
		end
		local width = math.clamp(math.max(widest + 52, options.MinWidth or 0), 150, 320)
		local visible = math.clamp(#values, 1, 9)
		local height = 10 + (searchable and 34 or 0) + visible * itemHeight

		return self:_OpenPopup(anchor, width, height, function(canvas)
			local top = 5
			local query = ""
			local searchBox
			if searchable then
				local field = New("Frame", {
					Name = "Search",
					Position = UDim2.fromOffset(6, 6),
					Size = UDim2.new(1, -12, 0, 26),
					Theme = { BackgroundColor3 = "Field" },
					Parent = canvas,
				})
				Corner(field, 6)
				Stroke(field, "FieldStroke")
				IconImage({
					Icon = "search",
					IconSize = 13,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Theme = { ImageColor3 = "SubText" },
					Parent = field,
				})
				searchBox = New("TextBox", {
					PlaceholderText = "Filter",
					Text = "",
					TextSize = 13,
					Position = UDim2.fromOffset(27, 0),
					Size = UDim2.new(1, -34, 1, 0),
					ClipsDescendants = true,
					Theme = { TextColor3 = "Text", PlaceholderColor3 = "Tertiary" },
					Parent = field,
				})
				top = 38
			end

			local scroll = New("ScrollingFrame", {
				Name = "Items",
				Position = UDim2.fromOffset(0, top),
				Size = UDim2.new(1, 0, 1, -top - 5),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 3,
				ScrollBarImageTransparency = 0.4,
				VerticalScrollBarInset = Enum.ScrollBarInset.None,
				Theme = { ScrollBarImageColor3 = "Scrollbar" },
				Parent = canvas,
			})
			local listFrame = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = scroll,
			})
			Padding(listFrame, 0, 5, 0, 5)
			List(listFrame, nil, 0)

			local empty = New("TextLabel", {
				Text = #values == 0 and "No Items" or "No Matches",
				TextSize = 13,
				Size = UDim2.new(1, 0, 0, itemHeight),
				TextXAlignment = Enum.TextXAlignment.Center,
				Visible = #values == 0,
				LayoutOrder = 100000,
				Theme = { TextColor3 = "Tertiary" },
				Parent = listFrame,
			})

			local items = {}
			for index, value in ipairs(values) do
				local state = { Hovered = false }
				local item = New("TextButton", {
					Name = "Item",
					Size = UDim2.new(1, 0, 0, itemHeight),
					BackgroundTransparency = 1,
					LayoutOrder = index,
					Theme = {
						BackgroundColor3 = "Accent",
						BackgroundTransparency = function()
							return state.Hovered and 0 or 1
						end,
					},
					Parent = listFrame,
				})
				Corner(item, 5)
				local check = IconImage({
					Name = "Check",
					Icon = "check",
					IconSize = 12,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Theme = {
						ImageColor3 = function(t)
							return state.Hovered and t.SelectionText or t.Text
						end,
					},
					Parent = item,
				})
				local label = New("TextLabel", {
					Text = tostring(value),
					TextSize = 14,
					Position = UDim2.fromOffset(26, 0),
					Size = UDim2.new(1, -32, 1, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
					Theme = {
						TextColor3 = function(t)
							return state.Hovered and t.SelectionText or t.Text
						end,
					},
					Parent = item,
				})
				local entry = { Item = item, Check = check, Value = value, Text = tostring(value):lower() }
				table.insert(items, entry)
				local function Paint(duration)
					Restyle(item, duration)
					Restyle(check, duration)
					Restyle(label, duration)
				end
				item.MouseEnter:Connect(function()
					state.Hovered = true
					Paint(0.06)
				end)
				item.MouseLeave:Connect(function()
					state.Hovered = false
					Paint(0.1)
				end)
				item.MouseButton1Click:Connect(function()
					options.OnPick(value)
					if options.Multi then
						for _, other in ipairs(items) do
							other.Check.Visible = options.IsSelected(other.Value)
						end
					else
						self:_ClosePopup()
					end
				end)
				check.Visible = options.IsSelected(value)
			end

			if searchBox then
				searchBox:GetPropertyChangedSignal("Text"):Connect(function()
					query = searchBox.Text:lower()
					local shown = 0
					for _, entry in ipairs(items) do
						entry.Item.Visible = query == "" or entry.Text:find(query, 1, true) ~= nil
						if entry.Item.Visible then
							shown += 1
						end
					end
					empty.Visible = shown == 0
				end)
				task.defer(function()
					if searchBox.Parent then
						searchBox:CaptureFocus()
					end
				end)
			end
		end, { Align = options.Align })
	end

	----------------------------------------------------------------------------
	-- Tabs
	----------------------------------------------------------------------------

	local function MovePill(animate)
		local tab = Window.CurrentTab
		if not tab then
			Pill.Visible = false
			return
		end
		local y = (tab.Button.AbsolutePosition.Y - TabList.AbsolutePosition.Y) / Window:GetAbsoluteScale()
		local goal = UDim2.fromOffset(10, y)
		Pill.Visible = true
		if animate then
			Tween(Pill, { Position = goal }, 0.3, Enum.EasingStyle.Quint)
		else
			Pill.Position = goal
		end
	end

	local function UpdateNavigation()
		SetBackEnabled(Window.HistoryIndex > 1)
		SetForwardEnabled(Window.HistoryIndex < #Window.History)
	end

	local function UpdateToolbarDivider()
		local tab = Window.CurrentTab
		local scrolled = tab and tab.Page.CanvasPosition.Y > 1
		Tween(ToolbarDivider, { BackgroundTransparency = scrolled and 0 or 1 }, 0.2)
	end

	function Window:AddTabSection(title)
		New("TextLabel", {
			Name = "SectionTitle",
			Text = tostring(title),
			TextSize = 12,
			Weight = Enum.FontWeight.Bold,
			Size = UDim2.new(1, 0, 0, #Window.Tabs == 0 and TabOrder == 0 and 22 or 30),
			TextYAlignment = Enum.TextYAlignment.Bottom,
			LayoutOrder = NextTabOrder(),
			Theme = { TextColor3 = "Tertiary" },
			Children = { New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingBottom = UDim.new(0, 5) }) },
			Parent = TabList,
		})
		Window.LastTabSection = title
	end
	Window.AddSidebarSection = Window.AddTabSection

	function Window:AddTab(info)
		if type(info) ~= "table" then
			info = { Title = tostring(info) }
		end
		if info.Section and info.Section ~= Window.LastTabSection then
			Window:AddTabSection(info.Section)
		end
		local index = #Window.Tabs + 1
		local tab = setmetatable({
			Window = Window,
			Title = tostring(info.Title or ("Tab " .. index)),
			Index = index,
			Blocks = {},
			Rows = {},
			Order = 0,
			Selected = false,
			Hovered = false,
			Matches = true,
		}, TabMethods)
		tab.Tab = tab

		-- Sidebar entry
		local button = New("TextButton", {
			Name = tab.Title,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = NextTabOrder(),
			Theme = {
				BackgroundColor3 = "Hover",
				BackgroundTransparency = function(t)
					return (tab.Hovered and not tab.Selected) and t.HoverTransparency or 1
				end,
			},
			Parent = TabList,
		})
		Corner(button, 7)
		tab.Button = button

		local textOffset = 12
		local icon = info.Icon
		if icon and MacUI:GetIcon(icon) then
			if sidebarStyle == "Tile" then
				local color = ResolveColor(info.IconColor) or MacUI.TileColors[(index - 1) % #MacUI.TileColors + 1]
				IconTile(button, icon, color, 22, 6, 14, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 5, 0.5, 0),
				})
			else
				IconImage({
					Name = "Icon",
					Icon = icon,
					IconSize = 17,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Theme = {
						ImageColor3 = function(t)
							if tab.Selected then
								return t.SelectionText
							end
							return sidebarStyle == "Tinted" and MacUI.Accent or t.SubText
						end,
					},
					Parent = button,
				})
			end
			textOffset = 35
		end
		tab.Label = New("TextLabel", {
			Name = "Title",
			Text = tab.Title,
			TextSize = 14,
			Position = UDim2.fromOffset(textOffset, 0),
			Size = UDim2.new(1, -textOffset - 8, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Theme = {
				TextColor3 = function(t)
					return tab.Selected and t.SelectionText or t.Text
				end,
				TextTransparency = function()
					return (tab.Matches or tab.Selected) and 0 or 0.55
				end,
			},
			Parent = button,
		})
		tab.Badge = New("Frame", {
			Name = "Badge",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = rgb(255, 69, 58),
			Visible = false,
			ZIndex = 3,
			Parent = button,
		})
		Corner(tab.Badge, 9)
		Padding(tab.Badge, 0, 6, 0, 6)
		New("UISizeConstraint", { MinSize = Vector2.new(18, 18), Parent = tab.Badge })
		tab.BadgeLabel = New("TextLabel", {
			Text = "",
			TextSize = 11,
			Weight = Enum.FontWeight.Bold,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = Color3.new(1, 1, 1),
			Parent = tab.Badge,
		})
		if info.Badge then
			tab:SetBadge(info.Badge)
		end

		button.MouseEnter:Connect(function()
			tab.Hovered = true
			Restyle(button, 0.12)
		end)
		button.MouseLeave:Connect(function()
			tab.Hovered = false
			Restyle(button, 0.18)
		end)
		button.MouseButton1Click:Connect(function()
			Window:SelectTab(tab)
		end)
		button:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			if Window.CurrentTab == tab and not Window.PillMoving then
				MovePill(false)
			end
		end)

		-- Page
		tab.Page = New("ScrollingFrame", {
			Name = tab.Title,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 5,
			ScrollBarImageTransparency = 1,
			VerticalScrollBarInset = Enum.ScrollBarInset.None,
			Visible = false,
			Theme = { ScrollBarImageColor3 = "Scrollbar" },
			Parent = PageHost,
		})
		tab.Content = New("Frame", {
			Name = "Content",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = tab.Page,
		})
		Padding(tab.Content, 6, 22, 26, 22)
		List(tab.Content, nil, 0)

		local hideToken = 0
		tab.Page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if Window.CurrentTab ~= tab then
				return
			end
			UpdateToolbarDivider()
			hideToken += 1
			local token = hideToken
			Tween(tab.Page, { ScrollBarImageTransparency = 0.35 }, 0.1)
			task.delay(1.1, function()
				if token == hideToken and tab.Page.Parent then
					Tween(tab.Page, { ScrollBarImageTransparency = 1 }, 0.4)
				end
			end)
		end)
		table.insert(Window.Tabs, tab)
		if not Window.CurrentTab and config.AutoSelect ~= false then
			Window:SelectTab(tab)
		end
		return tab
	end

	function Window:SelectTab(target, fromHistory)
		local tab = type(target) == "number" and Window.Tabs[target] or target
		if not tab or tab.Window ~= Window then
			return
		end
		Window:_ClosePopup()
		if tab == Window.CurrentTab then
			return
		end
		local previous = Window.CurrentTab
		Window.CurrentTab = tab
		for _, other in ipairs(Window.Tabs) do
			local selected = other == tab
			if other.Selected ~= selected then
				other.Selected = selected
				Restyle(other.Button, 0.15)
				Restyle(other.Label, 0.15)
				local icon = other.Button:FindFirstChild("Icon")
				if icon then
					Restyle(icon, 0.15)
				end
			end
		end
		Window.PillMoving = previous ~= nil
		MovePill(previous ~= nil)
		task.delay(0.32, function()
			Window.PillMoving = false
			MovePill(false)
		end)

		if previous then
			previous.Page.Visible = false
		end
		tab.Page.Visible = true
		if previous then
			tab.Page.Position = UDim2.fromOffset(0, 10)
			Tween(tab.Page, { Position = UDim2.fromOffset(0, 0) }, 0.32, Enum.EasingStyle.Quint)
			PageFade.BackgroundTransparency = 0
			Tween(PageFade, { BackgroundTransparency = 1 }, 0.26, Enum.EasingStyle.Quad)
		end

		if not fromHistory then
			for i = #Window.History, Window.HistoryIndex + 1, -1 do
				table.remove(Window.History, i)
			end
			table.insert(Window.History, tab)
			Window.HistoryIndex = #Window.History
		end
		UpdateNavigation()
		UpdateToolbarDivider()
		EmptyState.Visible = Window.SearchQuery ~= "" and not tab.HasResults
	end

	function Window:GoBack()
		if Window.HistoryIndex > 1 then
			Window.HistoryIndex -= 1
			Window:SelectTab(Window.History[Window.HistoryIndex], true)
		end
	end

	function Window:GoForward()
		if Window.HistoryIndex < #Window.History then
			Window.HistoryIndex += 1
			Window:SelectTab(Window.History[Window.HistoryIndex], true)
		end
	end

	BackButton.MouseButton1Click:Connect(function()
		Window:GoBack()
	end)
	ForwardButton.MouseButton1Click:Connect(function()
		Window:GoForward()
	end)

	----------------------------------------------------------------------------
	-- Search
	----------------------------------------------------------------------------

	function Window:_ApplySearch()
		local query = Window.SearchQuery
		for _, tab in ipairs(Window.Tabs) do
			local count = tab:_ApplySearch(query)
			tab.HasResults = count > 0
			tab.Matches = query == "" or count > 0
			Restyle(tab.Label, 0.15)
		end
		local current = Window.CurrentTab
		if query ~= "" and current and not current.HasResults then
			for _, tab in ipairs(Window.Tabs) do
				if tab.HasResults then
					Window:SelectTab(tab)
					current = tab
					break
				end
			end
		end
		EmptyState.Visible = query ~= "" and current ~= nil and not current.HasResults
		EmptyTitle.Text = "No Results for “" .. SearchBox.Text .. "”"
	end

	function Window:Search(text)
		SearchBox.Text = tostring(text or "")
	end

	local searchToken = 0
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		SearchClear.Visible = SearchBox.Text ~= ""
		searchToken += 1
		local token = searchToken
		task.delay(0.08, function()
			if token ~= searchToken then
				return
			end
			Window.SearchQuery = SearchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
			Window:_ApplySearch()
		end)
	end)
	SearchBox.Focused:Connect(function()
		Tween(SearchStroke, { Transparency = 0.55 }, 0.15)
	end)
	SearchBox.FocusLost:Connect(function()
		Tween(SearchStroke, { Transparency = 1 }, 0.2)
	end)
	SearchClear.MouseButton1Click:Connect(function()
		SearchBox.Text = ""
	end)

	----------------------------------------------------------------------------
	-- Sidebar collapse
	----------------------------------------------------------------------------

	function Window:SetSidebarVisible(visible)
		Window.SidebarVisible = visible ~= false
		local width = Window.SidebarVisible and sidebarWidth or 0
		if Window.SidebarVisible then
			Sidebar.Visible = true
		end
		Tween(Sidebar, { Size = UDim2.new(0, width, 1, 0) }, 0.32)
		Tween(Main, { Position = UDim2.fromOffset(width, 0), Size = UDim2.new(1, -width, 1, 0) }, 0.32)
		Tween(Leading, { Position = UDim2.new(0, Window.SidebarVisible and 12 or 84, 0.5, 0) }, 0.32)
		if not Window.SidebarVisible then
			task.delay(0.33, function()
				if not Window.SidebarVisible then
					Sidebar.Visible = false
				end
			end)
		end
	end

	function Window:ToggleSidebar()
		Window:SetSidebarVisible(not Window.SidebarVisible)
	end

	SidebarButton.MouseButton1Click:Connect(function()
		Window:ToggleSidebar()
	end)

	----------------------------------------------------------------------------
	-- Dragging & resizing
	----------------------------------------------------------------------------

	local drag, resize
	local lastToolbarClick = 0
	local DragExclusions = { SidebarButton, BackButton, ForwardButton, Search, Lights }
	local function OverControl(position)
		for _, gui in ipairs(DragExclusions) do
			local topLeft, extent = gui.AbsolutePosition, gui.AbsoluteSize
			if gui.Visible
				and position.X >= topLeft.X
				and position.X <= topLeft.X + extent.X
				and position.Y >= topLeft.Y
				and position.Y <= topLeft.Y + extent.Y
			then
				return true
			end
		end
		return false
	end
	local function BeginDrag(input)
		if not IsPointer(input) or OverControl(input.Position) then
			return
		end
		local now = os.clock()
		if now - lastToolbarClick < 0.35 then
			lastToolbarClick = 0
			Window:SetMaximized(not Window.Maximized)
			return
		end
		lastToolbarClick = now
		if not Window.Maximized then
			drag = { Start = input.Position, Position = Root.Position }
		end
	end
	Toolbar.InputBegan:Connect(BeginDrag)
	SidebarDrag.InputBegan:Connect(BeginDrag)

	local Grip = New("TextButton", {
		Name = "ResizeGrip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 30,
		Visible = config.Resizable ~= false,
		Parent = Root,
	})
	Grip.InputBegan:Connect(function(input)
		if IsPointer(input) and not Window.Maximized then
			resize = { Start = input.Position, Size = Window.Size, Position = Root.Position }
		end
	end)

	Connect(UserInputService.InputChanged, function(input)
		if not IsMove(input) then
			return
		end
		if drag then
			local delta = input.Position - drag.Start
			local viewport = ScreenGui.AbsoluteSize
			local start = drag.Position
			local x = math.clamp(start.X.Offset + delta.X, -viewport.X / 2 + 60, viewport.X / 2 - 60)
			local y = math.clamp(start.Y.Offset + delta.Y, -viewport.Y / 2 + 30, viewport.Y / 2 - 30)
			Root.Position = UDim2.new(start.X.Scale, x, start.Y.Scale, y)
		elseif resize then
			local delta = input.Position - resize.Start
			local scale = Window.Scale
			local width = math.max(resize.Size.X + delta.X / scale, minSize.X)
			local height = math.max(resize.Size.Y + delta.Y / scale, minSize.Y)
			Window.Size = Vector2.new(width, height)
			Root.Size = UDim2.fromOffset(width, height)
			local grow = (Window.Size - resize.Size) * scale / 2
			Root.Position = resize.Position + UDim2.fromOffset(grow.X, grow.Y)
		end
	end)
	Connect(UserInputService.InputEnded, function(input)
		if IsPointer(input) then
			drag = nil
			resize = nil
		end
	end)

	----------------------------------------------------------------------------
	-- Window state: open / minimise / maximise / close
	----------------------------------------------------------------------------

	local function BeginTransition()
		AnimGroup.Visible = true
		AnimGroup.GroupTransparency = 0
		Holder.Parent = AnimGroup
	end

	local function EndTransition()
		Holder.Parent = Root
		AnimGroup.Visible = false
	end

	local transitionId = 0
	function Window:SetVisible(visible, instant)
		transitionId += 1
		local id = transitionId
		Window:_ClosePopup(true)
		if visible then
			Root.Visible = true
			BeginTransition()
			AnimGroup.GroupTransparency = 1
			RootScale.Scale = Window.Scale * 0.94
			WindowShadow.ImageTransparency = 1
			Tween(AnimGroup, { GroupTransparency = 0 }, instant and 0 or 0.28)
			ScaleTween = Tween(RootScale, { Scale = Window.Scale }, instant and 0 or 0.4, Enum.EasingStyle.Quint)
			Tween(WindowShadow, { ImageTransparency = MacUI.ThemeData.ShadowTransparency }, instant and 0 or 0.4)
			task.delay(instant and 0 or 0.4, function()
				if id == transitionId then
					EndTransition()
				end
			end)
		else
			BeginTransition()
			Tween(AnimGroup, { GroupTransparency = 1 }, instant and 0 or 0.22)
			ScaleTween = Tween(RootScale, { Scale = Window.Scale * 0.92 }, instant and 0 or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			Tween(WindowShadow, { ImageTransparency = 1 }, instant and 0 or 0.2)
			task.delay(instant and 0 or 0.26, function()
				if id == transitionId then
					Root.Visible = false
					EndTransition()
					RootScale.Scale = Window.Scale
				end
			end)
		end
	end

	function Window:Minimize()
		Window.Minimized = true
		Window:SetVisible(false)
		if config.ShowDock ~= false then
			Dock.Visible = true
			Dock.Position = UDim2.new(0.5, 0, 1, 90)
			Tween(Dock, { Position = UDim2.new(0.5, 0, 1, -26) }, 0.45, Enum.EasingStyle.Back)
		end
	end

	function Window:Restore()
		Window.Minimized = false
		Window:SetVisible(true)
		if Dock.Visible then
			Tween(Dock, { Position = UDim2.new(0.5, 0, 1, 90) }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.3, function()
				if not Window.Minimized then
					Dock.Visible = false
				end
			end)
		end
	end

	function Window:Toggle()
		if Window.Minimized then
			Window:Restore()
		else
			Window:Minimize()
		end
	end

	local restoreState
	function Window:SetMaximized(maximized)
		if maximized == Window.Maximized then
			return
		end
		Window.Maximized = maximized
		if maximized then
			restoreState = { Size = Window.Size, Position = Root.Position }
			local viewport = ScreenGui.AbsoluteSize
			local target = Vector2.new((viewport.X - 24) / Window.Scale, (viewport.Y - 24) / Window.Scale)
			Window.Size = target
			Tween(Root, { Size = UDim2.fromOffset(target.X, target.Y), Position = UDim2.fromScale(0.5, 0.5) }, 0.38)
		elseif restoreState then
			Window.Size = restoreState.Size
			Tween(Root, { Size = UDim2.fromOffset(restoreState.Size.X, restoreState.Size.Y), Position = restoreState.Position }, 0.38)
		end
	end

	function Window:SetTitle(text)
		Window.Title = tostring(text)
		TitleLabel.Text = Window.Title
		DockTip.Text = Window.Title
	end

	function Window:SetSubtitle(text)
		Window.SubTitle = tostring(text or "")
		SubtitleLabel.Text = Window.SubTitle
		SubtitleLabel.Visible = Window.SubTitle ~= ""
	end
	Window.SetSubTitle = Window.SetSubtitle

	function Window:SetMinimizeKey(key)
		if key == "None" or key == false then
			Window.MinimizeKey = nil
			return
		end
		if type(key) == "string" then
			local ok, keycode = pcall(function()
				return Enum.KeyCode[key]
			end)
			key = ok and keycode or nil
		end
		if typeof(key) == "EnumItem" then
			Window.MinimizeKey = key
		end
	end

	function Window:Notify(options)
		return MacUI:Notify(options)
	end

	----------------------------------------------------------------------------
	-- Dialog (macOS alert)
	----------------------------------------------------------------------------

	function Window:Dialog(options)
		options = options or {}
		Window:_ClosePopup(true)
		local dialog = { Closed = false }
		local overlay = New("TextButton", {
			Name = "Dialog",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 40,
			Theme = { BackgroundColor3 = "Dim" },
			Parent = Holder,
		})
		Corner(overlay, 12)
		local panelWidth = 280
		local panelHolder = New("Frame", {
			Name = "Panel",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.fromOffset(panelWidth, 200),
			ZIndex = 41,
			Parent = overlay,
		})
		local panelScale = New("UIScale", { Scale = 1.08, Parent = panelHolder })
		local panelShadow = Shadow(panelHolder, 30, function(t)
			return dialog.Closed and 1 or t.ShadowTransparency
		end)
		panelShadow.ImageTransparency = 1
		local panel = New("CanvasGroup", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			GroupTransparency = 1,
			ZIndex = 2,
			Theme = { BackgroundColor3 = "Menu" },
			Parent = panelHolder,
		})
		Corner(panel, 14)
		local border = New("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.new(1, -2, 1, -2),
			ZIndex = 20,
			Parent = panel,
		})
		Corner(border, 13)
		Stroke(border, "MenuStroke", 1, 0.1)
		local body = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = panel,
		})
		Padding(body, 20, 18, 16, 18)
		List(body, nil, 6, { HorizontalAlignment = Enum.HorizontalAlignment.Center })

		IconTile(body, options.Icon or config.Icon or "command", ResolveColor(options.IconColor or config.IconColor) or function()
			return MacUI.Accent
		end, 52, 13, 28, { LayoutOrder = 1 })
		New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 4), LayoutOrder = 2, Parent = body })
		New("TextLabel", {
			Text = tostring(options.Title or "Alert"),
			TextSize = 15,
			Weight = Enum.FontWeight.Bold,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 3,
			Theme = { TextColor3 = "Text" },
			Parent = body,
		})
		if options.Content and options.Content ~= "" then
			New("TextLabel", {
				Text = tostring(options.Content),
				TextSize = 13,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				LayoutOrder = 4,
				Theme = { TextColor3 = function(t)
					return t.Text:Lerp(t.SubText, 0.3)
				end },
				Parent = body,
			})
		end
		New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 8), LayoutOrder = 5, Parent = body })

		local buttons = options.Buttons or { { Title = "OK" } }
		local row = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 6,
			Parent = body,
		})
		local stacked = #buttons > 2
		List(row, stacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal, 8, {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		})

		function dialog:Close()
			if dialog.Closed then
				return
			end
			dialog.Closed = true
			Tween(panel, { GroupTransparency = 1 }, 0.15)
			Restyle(panelShadow, 0.15)
			Tween(panelScale, { Scale = 0.96 }, 0.15)
			Tween(overlay, { BackgroundTransparency = 1 }, 0.2)
			task.delay(0.21, function()
				overlay:Destroy()
			end)
		end

		local count = #buttons
		local buttonWidth = stacked and (panelWidth - 36) or math.floor((panelWidth - 36 - 8 * (count - 1)) / count)
		for index, spec in ipairs(buttons) do
			local primary = index == 1
			local style = spec.Style or (primary and "Primary" or "Default")
			local push = PushButton(row, spec.Title or "OK", style, 28)
			push.Instance.AutomaticSize = Enum.AutomaticSize.None
			push.Instance.Size = UDim2.fromOffset(buttonWidth, 28)
			push.Instance.TextSize = 13
			push.Instance.LayoutOrder = stacked and index or (count - index + 1)
			push.Instance.MouseButton1Click:Connect(function()
				dialog:Close()
				Spawn(spec.Callback)
			end)
		end

		panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			panelHolder.Size = UDim2.fromOffset(panelWidth, panel.AbsoluteSize.Y / (RootScale.Scale * panelScale.Scale))
		end)

		Tween(overlay, { BackgroundTransparency = MacUI.ThemeData.DimTransparency }, 0.2)
		Tween(panel, { GroupTransparency = 0 }, 0.18)
		Restyle(panelShadow, 0.25)
		Tween(panelScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		return dialog
	end

	----------------------------------------------------------------------------
	-- Traffic light actions, dock, keyboard shortcut
	----------------------------------------------------------------------------

	LightButtons.Close.MouseButton1Click:Connect(function()
		if config.ConfirmClose == false then
			MacUI:Destroy()
			return
		end
		Window:Dialog({
			Title = "Close " .. Window.Title .. "?",
			Content = "This unloads the interface. Your scripts keep running until you rejoin.",
			Icon = "power",
			IconColor = rgb(255, 69, 58),
			Buttons = {
				{ Title = "Close", Style = "Destructive", Callback = function()
					MacUI:Destroy()
				end },
				{ Title = "Cancel" },
			},
		})
	end)
	LightButtons.Minimize.MouseButton1Click:Connect(function()
		Window:Minimize()
	end)
	LightButtons.Zoom.MouseButton1Click:Connect(function()
		Window:SetMaximized(not Window.Maximized)
	end)

	Dock.MouseEnter:Connect(function()
		DockTip.Visible = true
		Tween(DockScale, { Scale = Window.Scale * 1.08 }, 0.2, Enum.EasingStyle.Back)
	end)
	Dock.MouseLeave:Connect(function()
		DockTip.Visible = false
		Tween(DockScale, { Scale = Window.Scale }, 0.2)
	end)
	Dock.MouseButton1Click:Connect(function()
		Window:Restore()
	end)

	Connect(UserInputService.InputBegan, function(input, processed)
		if processed or KeyCapture.Active or UserInputService:GetFocusedTextBox() then
			return
		end
		if Window.MinimizeKey and input.KeyCode == Window.MinimizeKey then
			Window:Toggle()
		end
	end)

	Connect(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), function()
		if Window.Maximized then
			local viewport = ScreenGui.AbsoluteSize
			Window.Size = Vector2.new((viewport.X - 24) / Window.Scale, (viewport.Y - 24) / Window.Scale)
			Root.Size = UDim2.fromOffset(Window.Size.X, Window.Size.Y)
		end
	end)

	function Window:Destroy()
		MacUI:Destroy()
	end

	UpdateNavigation()
	Window:SetVisible(true)
	return Window
end

--------------------------------------------------------------------------------
-- Teardown
--------------------------------------------------------------------------------

function MacUI:Destroy()
	if self.Unloaded then
		return
	end
	self.Unloaded = true
	for _, fn in ipairs(UnloadCallbacks) do
		SafeCall(fn)
	end
	for _, window in ipairs(self.Windows) do
		if window._ClosePopup then
			window:_ClosePopup(true)
		end
		for _, connection in ipairs(window.Connections) do
			connection:Disconnect()
		end
		for _, tab in ipairs(window.Tabs) do
			for _, row in ipairs(tab.Rows) do
				for _, connection in ipairs(row.Connections) do
					connection:Disconnect()
				end
			end
		end
		if window.ScreenGui then
			window.ScreenGui:Destroy()
		end
	end
	if NotificationGui then
		NotificationGui:Destroy()
	end
	table.clear(ThemeRegistry)
	table.clear(FontRegistry)
	table.clear(self.Options)
end
MacUI.Unload = MacUI.Destroy

return MacUI

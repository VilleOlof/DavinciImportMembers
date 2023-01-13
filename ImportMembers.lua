-- Made by: VilleOlof
-- https://github.com/VilleOlof
local _Version = "1.0.0"

--What folder to start in when choosing a CSV file, Probably would want it to be your downloads folder for use of ease
--Default is os.getenv('APPDATA')..[[/Blackmagic Design/DaVinci Resolve/]]
local FolderOpenPath = os.getenv('APPDATA')..[[/Blackmagic Design/DaVinci Resolve/]]

--This path should be where this script is located at. This is used when opening the script via it's gui. Useful when editing options
--Default is assuming [%appdata%/Blackmagic Design/DaVinci Resolve/Support/Fusion/Scripts/Edit/ImportMembers.lua]
local ScriptPath = os.getenv('APPDATA')..[[/Blackmagic Design/DaVinci Resolve/Support/Fusion/Scripts/Edit/ImportMembers.lua]]

--Decides what member teirs will be shown with a prefix inside of hard brackets before their name
--Default is {}
local DisplayedMemberTeirs = {}

--X,Y Screen Resolution, The Clipboard window will appear near the center of your screen with correct input
--Leaving this as an empty table will make the script auto-get the current resolution via powershell.
--Default is {1920, 1080}
local Resolution = {1920, 1080}

--You can specify your own members but it will look for the teirs automatically.
--You can override that if you fill this in.
--(Order may be weird in the auto one, specify the teirs if you want a specific order in the drop-down)
--Default is {}
local MemberTeirs = {}

--Decides what string will be placed if the teir doesnt match in the teir specific clipboards
-- Default is "\n"
local NonTeirGap = "\n"

--Will add a specific prefix/suffix on all member names (Goes before Teir Prefix/Suffix)
--Default is ""
local GlobalPrefix = ""
local GlobalSuffix = ""

--Will add a specific prefix/suffix depending on the teir (Goes after Teir Prefix/Suffix)
--["TeirName"] = "Prefix/Suffix"
--Default is {}
local TeirPrefix = {}
local TeirSuffix = {}

--Decides on what characters it will put before and after the teir if the specified teir is in "DisplayedMemberTeirs"
local TeirDisplayPrefix = "[" --Default is "["
local TeirDisplaySuffix = "] " --Default is "] "

--#######################

--Ends the script the user wants auto resolution and not windows since the resolution auto-fetch uses powershell
local platform = (FuPLATFORM_WINDOWS and "Windows") or (FuPLATFORM_MAC and "Mac") or (FuPLATFORM_LINUX and "Linux")
if platform == "Mac" or platform == "Linux" then 
    if not Resolution[1] then
        print("Platform Not Available")
        goto EndScript 
    end
end

--no written resolution, fetch it with powershell
if not Resolution[1] then
    local ResolutionCommand = [[powershell -WindowStyle Hidden -Command "& {(Get-WmiObject -Class Win32_VideoController).VideoModeDescription;}"]]
    local cmd = io.popen(ResolutionCommand); local resString = cmd:read("*a")

    --only works for 4 digit resolutions but who has a 720p monitor in 2023 helloo
    local width = tonumber(resString:sub(1,4)) 
    local height = tonumber(resString:sub(7,11))

    Resolution = {width, height}
end

--tack tack maxboxx
function CSVParseFile(filename)
	local file = io.open(filename, 'r')
	local data
	if file then
		data = CSVParse(file:read('*a'))
		file:close()
	end
	return data
end
-- Parses a CSV string
function CSVParse(str)
	local data = {}
	local inStr = false
	local current = ""
	local isAdded = false
	local pos = 1
	local i = 1
	local function addItem(line, next)
		if current then
			current = current .. line:sub(pos, i - 1)
			if not inStr then
				table.insert(data[#data], (current:gsub('""', '"')))
			else
				current = current .. '\n'
			end
		end
		pos = i + 1
		if not inStr then
			current = next
		end
	end
	for line in str:gmatch('([^\r\n]*)\r?\n?') do
		pos, i = 1, 1
		if not inStr then
			data[#data + 1] = {}
		end
		while i <= #line do
			local c = line:sub(i, i)
			if not inStr and c == ',' then
				addItem(line, "")
			elseif c == '"' then
				if inStr then
					if i + 1 <= #line and line:sub(i + 1, i + 1) == '"' then
						i = i + 1
					else
						inStr = false
						addItem(line, nil)
					end
				else
					inStr = true
					pos = i + 1
				end
			end
			i = i + 1
		end
		addItem(line, "")
	end
	if #data[#data] == 0 then
		data[#data] = nil
	end
	return data
end

local function ShowClipboardUI(FinalString, FinalTeirStrings)
    local ui = fu.UIManager
    local disp = bmd.UIDispatcher(ui)
    local W_width,W_height = 400,100
    
    win = disp:AddWindow({
        ID = 'ClipWin',
        WindowTitle = 'ImportMembers',
        Geometry = {Resolution[1] / 2.5, Resolution[2] / 2.5, W_width, W_height},
        Spacing = 10,
    
        ui:VGroup{
            ID = 'root',
            ui:HGroup{
                ui:Label{
                    ID = "TitleText",
                    Text = "Member Clipboards",
                    Font = ui:Font{
                        PixelSize = 20,
                        Bold = true,
                    },
                },
                ui:Button{
                    ID = "OpenScriptButton",
                    Text = "Open Script",
                    Weight = 0,
                    FixedSize = {85, 25}
                },
            },
            ui:ComboBox{
                ID = 'ClipboardDropdown',
                Text = 'Clipboards',
                Font = ui:Font{
                    PixelSize = 20,
                    Bold = true,
                },
            },
        },
    })
    
    function win.On.ClipWin.Close(ev)
        disp:ExitLoop()
    end
    
    local itm = win:GetItems()
    
    itm.ClipboardDropdown:AddItem("All Teirs")
    for index, string in ipairs(FinalTeirStrings) do
        itm.ClipboardDropdown:AddItem(MemberTeirs[index])
    end

    function win.On.ClipboardDropdown.CurrentIndexChanged(ev)
        local dropDown_index = itm.ClipboardDropdown.CurrentIndex+1

        if dropDown_index == 1 then bmd.setclipboard(FinalString)
        else bmd.setclipboard(FinalTeirStrings[dropDown_index-1]) end
    end

    function win.On.OpenScriptButton.Clicked(ev)
        bmd.openfileexternal("Open", ScriptPath)
    end
    
    win:Show()
    disp:RunLoop()
    win:Hide()
end

local function GetCSVFilePath(openPath)
    local CSVFile = fu:RequestFile(openPath, "", {
        FReqB_SeqGather = true, 
        FReqS_Filter = "Open CSV Files (*.csv)|*.csv", 
        FReqS_Title = "Choose .csv file"})

    if type(CSVFile) ~= "string" then return nil end --makes sure user choose a path
    local selectedPath = tostring(CSVFile)
    return selectedPath
end

local function ArrayContains(arr, value)
    for index, arrValue in ipairs(arr) do
        if arrValue == value then return true end
    end
    return false
end

--Main
local CSVFile = GetCSVFilePath(FolderOpenPath)

if CSVFile ~= nil then
    local CSVData = CSVParseFile(CSVFile)

    table.remove(CSVData,1) --remove csv header table
    table.remove(CSVData, #CSVData) --remove empty last table?

    --find all teirs so user dont have to manually add those
    if #MemberTeirs == 0 then
        for groupIndex, groupInfo in pairs(CSVData) do
            local teir = groupInfo[3]
            if ArrayContains(MemberTeirs, teir) == false then MemberTeirs[#MemberTeirs+1] = teir end
        end
    end

    local FinalString = ""

    for groupIndex, groupInfo in pairs(CSVData) do
    
        local name = groupInfo[1]
        local teir = groupInfo[3]
        if name == "" or name == nil then goto continue end
    
        for i, teirName in ipairs(DisplayedMemberTeirs) do
            --local teirName = MemberTeirs[index]
            if teir == teirName then 
                local TeirPrefixText = ""; local TeirSuffixText = ""
                if TeirPrefix[teirName] then TeirPrefixText = TeirPrefix[teirName] end 
                if TeirSuffix[teirName] then TeirSuffixText = TeirSuffix[teirName] end

                name = TeirPrefixText..TeirDisplayPrefix..teir..TeirDisplaySuffix..name..TeirSuffixText
                break
            end
        end 

        FinalString = FinalString..GlobalPrefix..name..GlobalSuffix.."\n"
        ::continue::
    end

    --seperate the teirs into different strings to be copied with empty space lines with some buttons depending on teir array
    local FinalTeirStrings = {}
    for groupIndex, groupInfo in pairs(CSVData) do

        local name = groupInfo[1]
        local teir = groupInfo[3]
        if name == "" or name == nil then goto continue end

        for index, teirName in ipairs(MemberTeirs) do
            if FinalTeirStrings[index] == nil then FinalTeirStrings[index] = "" end

            if teir == teirName then 
                local TeirPrefixText = ""; local TeirSuffixText = ""
                if TeirPrefix[teirName] then TeirPrefixText = TeirPrefix[teirName] end 
                if TeirSuffix[teirName] then TeirSuffixText = TeirSuffix[teirName] end

                local displayedName = GlobalPrefix..name..GlobalSuffix.."\n"
                if ArrayContains(DisplayedMemberTeirs, teirName) then
                    displayedName = GlobalPrefix..TeirPrefixText..TeirDisplayPrefix..teir..TeirDisplaySuffix..name..TeirSuffixText..GlobalSuffix.."\n" end

                FinalTeirStrings[index] = FinalTeirStrings[index]..displayedName
            else 
                FinalTeirStrings[index] = FinalTeirStrings[index]..NonTeirGap 
            end
        end
        ::continue::
    end

    ShowClipboardUI(FinalString, FinalTeirStrings)
end
::EndScript::
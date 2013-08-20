-- Main Program taken from Computercraft mod
local function printUsage()
	print( "Usages:" )
	print( "pastebin put <filename>" )
	print( "pastebin get <code> <filename>" )
	print( "pastebin update [<filename>]" )
end

local saveFileName = "listOfPrograms"

local installedPrograms = {}

local function loadInstalledPrograms()
	if fs.exists(saveFileName) then
		file = fs.open(saveFileName, "r")
		print("Installed Programs ... \n")
		for line in file.readLine do
			for name,code in string.gmatch(line, "([^=]+)=([^=]+)") do
				if not (shell.resolveProgram(name) == nil) then
				  	installedPrograms[name] = code
				  	print(name .. " = " .. code)
				end
			end
		end
		file.close()
	end
end

local function saveInstalledPrograms()
	file = fs.open(saveFileName, "w")
	for name, code in pairs(installedPrograms) do
		file.writeLine(name.."="..code)
	end
	file.close()
end

local function saveNewProgram(name, code)
	installedPrograms[name] = code
end

local function put(sFile)
	-- Upload a file to pastebin.com
	local sPath = shell.resolve( sFile )
	-- Determine file to upload
	if not fs.exists( sPath ) or fs.isDir( sPath ) then
		print( "No such file" )
		return
	end

	-- Read in the file
	local sName = fs.getName( sPath )
	local file = fs.open( sPath, "r" )
	local sText = file.readAll()
	file.close()

	-- POST the contents to pastebin
	write( "Connecting to pastebin.com... " )
	local key = "0ec2eb25b6166c0c27a394ae118ad829"
	local response = http.post(
		"http://pastebin.com/api/api_post.php",
		"api_option=paste&"..
		"api_dev_key="..key.."&"..
		"api_paste_format=lua&"..
		"api_paste_name="..textutils.urlEncode(sName).."&"..
		"api_paste_code="..textutils.urlEncode(sText)
		)

	if response then
		print( "Success." )

		local sResponse = response.readAll()
		response.close()

		local sCode = string.match( sResponse, "[^/]+$" )
		print( "Uploaded as "..sResponse )
		print( "Run \"pastebin get "..sCode.."\" to download anywhere" )
		saveNewProgram(sFile, sCode)
	else
		print( "Failed." )
	end
end

local function get(sCode, sFile)
	-- Download a file from pastebin.com
	-- Determine file to download
	-- local sCode = tArgs[2]
	-- local sFile = tArgs[3]
	saveNewProgram(sFile, sCode)
	local sPath = shell.resolve( sFile )
	if fs.exists( sPath ) then
		print( "File already exists" )
		return
	end

	-- GET the contents from pastebin
	write( "Connecting to pastebin.com... " )
	local response = http.get(
		"http://pastebin.com/raw.php?i="..textutils.urlEncode( sCode )
		)

	if response then
		print( "Success." )

		local sResponse = response.readAll()
		response.close()

		local file = fs.open( sPath, "w" )
		file.write( sResponse )
		file.close()

		print( "Downloaded as "..sFile )

	else
		print( "Failed." )
	end
end

local tArgs = { ... }

if not http then
	print( "Pastebin requires http API" )
	print( "Set enableAPI_http to 1 in mod_ComputerCraft.cfg" )
	return
end

loadInstalledPrograms()

local command = tArgs[1]
if command == "put" then
	if #tArgs < 2 then
		printUsage()
	  	return
	end
	local sFile = tArgs[2]
	put(sFile)
elseif command == "get" then
	if #tArgs < 3 then
		printUsage()
		return
	end
	local code = tArgs[2]
	local file = tArgs[3]
	get(code, file)
elseif command == "update" then
	if #tArgs < 2 then
		updateAllPrograms()
	else
		local program = tArgs[2]
		update(program)
	end
else
	printUsage()
	return
end

saveInstalledPrograms()
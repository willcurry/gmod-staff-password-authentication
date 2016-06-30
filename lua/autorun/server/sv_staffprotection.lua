require('hash')
require('tmysql4')

util.AddNetworkString("28988957987353255")
util.AddNetworkString("592385876")

-- Ranks that require authentication.
local ranks = {
	["admin"] = true,
	["admin+"] = true,
	["mod"] = true,
	["owner"] = true,
	["superadmin"] = true,
	["community manager"] = true
}
-- Ranks that require authentication.

-- Your SQL info.
local mysql_hostname = ''
local mysql_username = ''
local mysql_password = ''
local mysql_database = ''
local mysql_port = 3306
-- Your SQL info.

local db, err = tmysql.initialize(mysql_hostname, mysql_username, mysql_password, mysql_database, mysql_port)

db:Query([[CREATE TABLE IF NOT EXISTS protection(
		SteamID VARCHAR( 20 ),
		Code VARCHAR( 120 ),
		PlayerName VARCHAR( 120 ),
		Salt VARCHAR( 120 ),
		PRIMARY KEY ( SteamID )
	)
]])

local function salt()
	local holder = ""
	local salt_chars = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"};

	for i = 1, 16 do
		local text = salt_chars[math.random(#salt_chars)]
		holder = holder .. text
	end

	return holder
end

local function setCode(ply, code)
	if err then print("[CG SQL] " .. err) return end
	if !code then return end

	local sid = ply:SteamID()
	local name = ply:Nick()
	local salt = salt()
	local hashedCode = hash.MD5(hash.SHA256(code .. salt))
	
	ply:ChatPrint("Code has been saved!")
	db:Query("REPLACE into protection (`SteamID`, `Code`, `PlayerName`, `Salt`) VALUES('"..sid.."', '"..hashedCode.."', '"..name.."', '"..salt.."');")
end

concommand.Add("set_code", function(ply, cmd, args)
	if !IsValid(ply) then return end
	if !ranks[ply.rank] then return end
	if ply.salt then return end

	setCode(ply, args[1])
end)

local function getSalt(ply, callback)
	if err then print("[Protection SQL] " .. err) return end
	if ( !IsValid( ply ) ) then return end

	local sid = ply:SteamID()
	db:Query("SELECT Salt from protection WHERE SteamID = '"..sid.."'", function(results)
		local row = results[1].data[1]
		
		if row then
			callback(row.salt)
		else
			callback(nil)
		end
	end)
end

local function getCode(ply, code, callback)
	if err then print("[Protection SQL] " .. err) return end
	if !code or !ply.salt then return end

	local sid = ply:SteamID()
	db:Query("SELECT Code from protection WHERE SteamID = '"..sid.."'", function(results)
		local row = results[1].data[1]
		if row then
			callback(row.code)
		else
			callback(nil)
		end
	end)
end

hook.Add("PlayerAuthed", "ULXProtection", function(ply)
	timer.Simple(3, function()
		ply.rank = ply:GetUserGroup()	
		if ranks[ply:GetUserGroup()] then
			getSalt(ply, function(salt)
				if !salt then
					ply:ChatPrint("You must set a code!")
				else
					net.Start("28988957987353255")
					net.Send(ply)
					ply.salt = salt
				end
			end)
			ply:SetUserGroup("user")
		end
	end)
end)

local function checkCode(l, ply)
	if !IsValid(ply) then return end
	
	local code = net.ReadString()
	getCode(ply, code, function(hashCode)
		if hash.MD5(hash.SHA256(code .. ply.salt)) == hashCode then
			ply:SetUserGroup(ply.rank)
			ply.salt = nil
		else
			ply:Kick("Wrong code")
			return
		end
	end)
end
net.Receive("592385876", checkCode)
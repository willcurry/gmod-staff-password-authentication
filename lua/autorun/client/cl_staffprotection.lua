local function ui()
	local bg = vgui.Create("DFrame")
	bg:SetSize(200, 150)
	bg:Center()
	bg:SetTitle("Staff Member Authentication")
	bg:MakePopup()
	bg:ShowCloseButton( false )
	
	local codeEnter = vgui.Create("DTextEntry", bg)
	codeEnter:SetSize(200, 50)
	codeEnter:SetPos(0, 50)
	codeEnter.OnEnter = function( self )
		local code = self:GetValue()
		if !code then return end
		net.Start("592385876")
		net.WriteString(code)
		net.SendToServer()
		bg:Close()
	end
end

local function codeEnter(len, ply)
	timer.Simple(3, function()
		ui()
	end)
end
net.Receive("28988957987353255", codeEnter)
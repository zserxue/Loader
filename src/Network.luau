-- bridgenet2 wrapper for network functionality
local Network = {}
Network.__index = Network

function Network.new(BridgeNet2, isServer: boolean)
	local self = setmetatable({}, Network)

	self.IsServer = isServer
	self.Bridges = {}
	self.BridgeNet2 = BridgeNet2

	return self
end

function Network:GetBridge(name: string)
	if self.Bridges[name] then
		return self.Bridges[name]
	end

	local bridge = self.BridgeNet2.ServerBridge(name)

	if not self.IsServer then
		bridge = self.BridgeNet2.ClientBridge(name)
	end

	self.Bridges[name] = bridge

	return bridge
end

function Network:On(name: string, callback)
	local bridge = self:GetBridge(name)

	return bridge:Connect(callback)
end

function Network:Fire(name: string, ...)
	local bridge = self:GetBridge(name)

	bridge:Fire(...)
end

function Network:FireClient(player, name: string, ...)
	assert(self.IsServer, "FireClient can only be called from the server")

	local bridge = self:GetBridge(name)

	bridge:Fire(player, ...)
end

function Network:FireAll(name: string, ...)
	assert(self.IsServer, "FireAll can only be called from the server")

	local bridge = self:GetBridge(name)

	bridge:FireAll(...)
end

return Network

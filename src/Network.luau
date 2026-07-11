--!strict

local Network = {}
Network.__index = Network

export type Network = {
	IsServer: boolean,
	Events: { [string]: any },

	Get: (self: Network, name: string) -> any,
	On: (self: Network, name: string, callback: (...any) -> ()) -> any,

	Fire: (self: Network, name: string, ...any) -> (),
	FireClient: (self: Network, player: Player, name: string, ...any) -> (),
	FireAll: (self: Network, name: string, ...any) -> (),
}

function Network.new(QuickNet, definitions, isServer: boolean): Network
	local self = setmetatable({}, Network)

	self.IsServer = isServer
	self.Events = {}

	for name, schema in definitions do
		self.Events[name] = QuickNet:register(name, table.unpack(schema))
	end

	return self
end

function Network:Get(name: string)
	local event = self.Events[name]

	assert(event, "Unknown network event: " .. name)

	return event
end

function Network:On(name: string, callback: (...any) -> ())
	local event = self:Get(name)

	if self.IsServer then
		return event.OnServerEvent:Connect(callback)
	else
		return event.OnClientEvent:Connect(callback)
	end
end

function Network:Fire(name: string, ...: any)
	local event = self:Get(name)

	if self.IsServer then
		event:FireAllClients(...)
	else
		event:FireServer(...)
	end
end

function Network:FireClient(player: Player, name: string, ...: any)
	assert(self.IsServer, "FireClient can only run on server")

	self:Get(name):FireClient(player, ...)
end

function Network:FireAll(name: string, ...: any)
	assert(self.IsServer, "FireAll can only run on server")

	self:Get(name):FireAllClients(...)
end

return Network

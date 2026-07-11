--!nocheck
--[[
	Network Wrapper
	===============

	This module is a lightweight wrapper around ByteNet packets.

	Setup:
	1. Define your packets in a shared Definitions module.
	2. Pass that table into Loader.Start().
	3. Access packets through loader.Network.

	Example Definitions:

		return {
			Damage = ByteNet.definePacket(...),
			Equip = ByteNet.definePacket(...),
		}

	Sending:

		loader.Network:Fire("Damage", {
			Player = player,
			Amount = 25,
		})

		loader.Network:FireClient(player, "Damage", {
			Player = player,
			Amount = 25,
		})

	Receiving:

		loader.Network:On("Damage", function(data)
			print(data.Player)
			print(data.Amount)
		end)

	This wrapper does not create or register packets.
	It stores the ByteNet packet objects and provides
	a consistent API for the rest of the code.
]]

local Network = {}
Network.__index = Network

local Types = require(script.Parent.Types)

function Network.new(definitions, isServer: boolean): Types.Network
	local self = setmetatable({}, Network)

	self.IsServer = isServer
	self.Events = definitions

	return self
end

function Network:Get(name: string)
	local packet = self.Events[name]

	assert(packet, "Unknown network packet: " .. name)

	return packet
end

function Network:On(name: string, callback)
	local packet = self:Get(name)

	return packet.listen(callback)
end

function Network:Fire(name: string, ...)
	local packet = self:Get(name)

	if self.IsServer then
		packet.sendToAll(...)
	else
		packet.send(...)
	end
end

function Network:FireClient(player: Player, name: string, ...)
	assert(self.IsServer, "FireClient can only run on server")

	self:Get(name).sendTo(..., player)
end

function Network:FireAll(name: string, ...)
	assert(self.IsServer, "FireAll can only run on server")

	self:Get(name).sendToAll(...)
end

return Network

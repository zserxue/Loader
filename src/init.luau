--!nocheck
local Packages = script.Parent

local Signal = require(Packages.Signal)

local SignalRegistry = require(script.SignalRegistry)
local Network = require(script.Network)
local Types = require(script.Types)

local Loader = {}
Loader.__index = Loader

local _instance: Types.Loader? = nil

local function timeMs()
	return os.clock() * 1000
end

function Loader.Start(folders: Instance | { Instance }, networkDefinitions: Types.NetworkDefinitions): Loader
	if _instance then
		return _instance
	end

	local self = setmetatable({}, Loader) :: any

	self.Modules = {}
	self.ModuleList = {}

	self.Signals = SignalRegistry.new(Signal)

	self.Network = Network.new(networkDefinitions, game:GetService("RunService"):IsServer())

	_instance = self

	local folderList: { Instance }

	if typeof(folders) == "Instance" then
		folderList = { folders }
	else
		folderList = folders
	end

	for _, folder in folderList do
		for _, obj in folder:GetChildren() do
			if obj:IsA("ModuleScript") then
				local module = require(obj)

				self.Modules[obj.Name] = module

				table.insert(self.ModuleList, {
					Name = obj.Name,
					Ref = module,
				})
			end
		end
	end

	self:InitAll()
	self:StartAll()

	return self
end

function Loader.Instance(): Types.Loader
	assert(_instance, "Loader has not started")

	return _instance
end

function Loader:GetModule(name: string)
	return self.Modules[name]
end

function Loader:GetSignal(name: string)
	return self.Signals:Get(name)
end

function Loader:InitAll()
	table.sort(self.ModuleList, function(a, b)
		return (a.Ref.Priority or 0) > (b.Ref.Priority or 0)
	end)

	for _, entry in self.ModuleList do
		local module = entry.Ref

		if module.Init then
			local start = timeMs()

			local success, err = pcall(function()
				module:Init(self.Modules, self)
			end)

			local duration = timeMs() - start

			if success then
				print(string.format("[%.2fms] %s initialized", duration, entry.Name))
			else
				warn(entry.Name, "Init failed:", err)
			end
		end
	end
end

function Loader:StartAll()
	for _, entry in self.ModuleList do
		local module = entry.Ref

		if module.Start then
			task.spawn(function()
				local success, err = pcall(function()
					module:Start()
				end)

				if not success then
					warn(entry.Name, "Start failed:", err)
				end
			end)
		end
	end
end

return Loader

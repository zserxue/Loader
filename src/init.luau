local Signal = require(script.Parent.Parent.Packages.Signal)
local BridgeNet2 = require(script.Parent.Parent.Packages.BridgeNet2)

local SignalRegistry = require(script.SignalRegistry)
local Network = require(script.Network)

local Loader = {}
Loader.__index = Loader

local _instance

local function timeMs()
	return os.clock() * 1000
end

function Loader.Start(folders: Instance | { Instance })
	if _instance then
		return _instance
	end

	local self = setmetatable({}, Loader)

	self.Modules = {}
	self.ModuleList = {}

	self.Signals = SignalRegistry.new(Signal)

	self.Network = Network.new(BridgeNet2, game:GetService("RunService"):IsServer())

	_instance = self

	local folderList

	if typeof(folders) == "Instance" then
		folderList = { folders }
	else
		folderList = folders
	end

	for _, folder in ipairs(folderList) do
		for _, obj in ipairs(folder:GetChildren()) do
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

function Loader.Instance()
	assert(_instance, "Loader has not started")

	return _instance
end

function Loader:GetModule(name)
	return self.Modules[name]
end

function Loader:GetSignal(name)
	return self.Signals:Get(name)
end

function Loader:InitAll()
	table.sort(self.ModuleList, function(a, b)
		return (a.Ref.Priority or 0) > (b.Ref.Priority or 0)
	end)

	for _, entry in ipairs(self.ModuleList) do
		local module = entry.Ref

		if type(module.Init) == "function" then
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
	for _, entry in ipairs(self.ModuleList) do
		local module = entry.Ref

		if type(module.Start) == "function" then
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

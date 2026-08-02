--!nocheck
local RunService = game:GetService("RunService")
local Packages = script.Parent

local Signal = require(Packages.Signal)

local SignalRegistry = require(script.SignalRegistry)
local Types = require(script.Types)

local Debug = RunService:IsStudio()
local Sort, Spawn, Format = table.sort, task.spawn, string.format

local Loader = {}
Loader.__index = Loader

local _instance: Types.Loader? = nil

local function timeMs(): number
	return os.clock() * 1000
end

function Loader.Start(folders: Instance | { Instance }): Types.Loader
	if _instance then
		return _instance
	end

	local self = setmetatable({}, Loader) :: any

	self.Modules = {}
	self.ModuleList = {}

	self.State = {
		Character = nil,
		Humanoid = nil,
	}

	self.Signals = SignalRegistry.new(Signal)

	_instance = self

	local folderList: { Instance }

	if typeof(folders) == "Instance" then
		folderList = { folders }
	else
		folderList = folders
	end

	for _, folder in folderList do
		for _, object in folder:GetChildren() do
			if not object:IsA("ModuleScript") then
				continue
			end

			assert(
				self.Modules[object.Name] == nil,
				Format("Duplicate module '%s'", object.Name)
			)

			local ok, module = pcall(require, object)

			if not ok then
				warn(Format(
					"Failed to require %s\n%s",
					object:GetFullName(),
					tostring(module)
				))
				continue
			end

			self.Modules[object.Name] = module

			self.ModuleList[#self.ModuleList + 1] = {
				Name = object.Name,
				Ref = module,
			}
		end
	end

	self:InitAll()
	self:StartAll()

	return self
end

function Loader.Instance(): Types.Loader
	assert(_instance, "Loader has not been started.")
	return _instance
end

function Loader:GetModule(name: string): Types.Module?
	return self.Modules[name]
end

function Loader:GetSignal(name: string)
	return self.Signals:Get(name)
end

function Loader:SetState(key: string, value: any)
	self.State[key] = value
end

function Loader:GetState(key: string): any
	return self.State[key]
end

function Loader:SetCharacter(character: Model?)
	self.State.Character = character

	if character then
		self.State.Humanoid = character:FindFirstChildOfClass("Humanoid")
	else
		self.State.Humanoid = nil
	end
end

function Loader:GetCharacter(): Model?
	return self.State.Character
end

function Loader:GetHumanoid(): Humanoid?
	return self.State.Humanoid
end

function Loader:InitAll()
	Sort(self.ModuleList, function(a, b)
		return (a.Ref.Priority or 0) > (b.Ref.Priority or 0)
	end)

	for _, entry in self.ModuleList do
		local module = entry.Ref

		if not module.Init then
			continue
		end

		local start = 0

		if Debug then
			start = timeMs()
		end

		local success, err = pcall(
			module.Init,
			module,
			self.Modules,
			self
		)

		if success then
			if Debug then
				print(Format(
					"[%.2fms] %s initialized",
					timeMs() - start,
					entry.Name
				))
			end
		else
			warn(Format(
				"%s Init failed:\n%s",
				entry.Name,
				tostring(err)
			))
		end
	end
end

function Loader:StartAll()
	for _, entry in self.ModuleList do
		local module = entry.Ref

		if not module.Start then
			continue
		end

		Spawn(function()
			local success, err = pcall(module.Start, module)

			if not success then
				warn(Format(
					"%s Start failed:\n%s",
					entry.Name,
					tostring(err)
				))
			end
		end)
	end
end

return Loader
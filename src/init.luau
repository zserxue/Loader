local Loader = {}
Loader.__index = Loader

local _instance

export type Module = {
	Init: (self: Module, modules: { [string]: any }) -> ()?,
	Start: (self: Module) -> ()?,
	Priority: number?,
}

export type LoaderType = {
	Modules: { [string]: Module },
	ModuleList: { { Name: string, Ref: Module } },
	Character: Model?,

	InitAll: (self: LoaderType) -> (),
	StartAll: (self: LoaderType) -> (),
	Require: (self: LoaderType, name: string) -> Module?,
	SetCharacter: (self: LoaderType, character: Model?) -> (),
}

local function timeMs()
	return os.clock() * 1000
end

function Loader.Start(folders: Instance | { Instance }): LoaderType
	if _instance then
		return _instance
	end

	local self = setmetatable({}, Loader)

	self.Modules = {}
	self.ModuleList = {}
	self.Character = nil

	_instance = self

	local folderList: { Instance }

	if typeof(folders) == "Instance" then
		folderList = { folders }
	else
		folderList = folders
	end

	for _, folder in ipairs(folderList) do
		for _, obj in ipairs(folder:GetChildren()) do
			if obj:IsA("ModuleScript") then
				local ref = require(obj)

				self.Modules[obj.Name] = ref
				self.ModuleList[#self.ModuleList + 1] = {
					Name = obj.Name,
					Ref = ref,
				}
			end
		end
	end

	self:InitAll()
	self:StartAll()

	return self
end

function Loader.Instance(): LoaderType
	assert(_instance, "Loader has not been started yet. Call Loader.Start() first.")
	return _instance
end

function Loader:SetCharacter(character: Model?)
	self.Character = character
end

function Loader:InitAll()
	table.sort(self.ModuleList, function(a, b)
		local pa = a.Ref.Priority or 0
		local pb = b.Ref.Priority or 0
		return pa > pb
	end)

	for _, entry in ipairs(self.ModuleList) do
		local name = entry.Name
		local module = entry.Ref

		if type(module.Init) == "function" then
			local start = timeMs()

			local success, err = pcall(function()
				module:Init(self.Modules)
			end)

			local duration = timeMs() - start

			if success then
				print(string.format("[%.2fms] %s", duration, name))
			else
				warn(string.format("[%.2fms] %s FAILED: %s", duration, name, err))
			end
		end
	end
end

function Loader:StartAll()
	for _, entry in ipairs(self.ModuleList) do
		local module = entry.Ref

		if type(module.Start) == "function" then
			module:Start()
		end
	end
end

function Loader:Require(name: string): Module?
	return self.Modules[name]
end

return Loader

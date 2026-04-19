local Loader = {}
Loader.__index = Loader

export type Module = {
	Init: (self: Module, modules: { [string]: any }) -> ()?,
	Start: (self: Module) -> ()?,
	Priority: number?,
}

export type LoaderType = {
	Modules: { [string]: Module },
	ModuleList: { { Name: string, Ref: Module } },

	Load: (self: LoaderType, folder: Instance) -> (),
	InitAll: (self: LoaderType) -> (),
	StartAll: (self: LoaderType) -> (),
	Get: (self: LoaderType, name: string) -> Module,
}

local function timeMs()
	return os.clock() * 1000
end

--/ Constructor
function Loader.new(): LoaderType
	local self = setmetatable({}, Loader)

	self.Modules = {}
	self.ModuleList = {}

	return self
end

--/ Methods
function Loader:Load(folder: Instance)
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

function Loader:Get(name: string)
	return self.Modules[name]
end

return Loader

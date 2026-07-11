export type NetworkDefinitions = {
	[string]: { any },
}

export type Module = {
	Priority: number?,
	Init: ((modules: { [string]: any }, loader: Loader) -> ())?,
	Start: (() -> ())?,
}

export type ModuleEntry = {
	Name: string,
	Ref: Module,
}

export type Loader = {
	Modules: { [string]: Module },
	ModuleList: { { Name: string, Ref: Module } },

	Network: any,

	GetModule: (self: Loader, name: string) -> Module?,
	GetSignal: (self: Loader, name: string) -> any,

	InitAll: (self: Loader) -> (),
	StartAll: (self: Loader) -> (),
}

export type Network = {
	IsServer: boolean,
	Events: { [string]: any },

	Get: (self: Network, name: string) -> any,
	On: (self: Network, name: string, callback: (...any) -> ()) -> any,

	Fire: (self: Network, name: string, ...any) -> (),
	FireClient: (self: Network, player: Player, name: string, ...any) -> (),
	FireAll: (self: Network, name: string, ...any) -> (),
}

return {}

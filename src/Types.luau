export type Module = {
	Init: ((modules: { [string]: any }, loader: any) -> ())?,
	Start: (() -> ())?,
	Priority: number?,
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

return {}

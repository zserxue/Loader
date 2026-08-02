--!strict

export type Module = {
	Priority: number?,

	Init: ((self: Module, modules: { [string]: Module }, loader: Loader) -> ())?,
	Start: ((self: Module) -> ())?,
}

export type ModuleEntry = {
	Name: string,
	Ref: Module,
}

export type LoaderState = {
	Character: Model?,
	Humanoid: Humanoid?,

	[string]: any,
}

export type Loader = {
	Modules: { [string]: Module },
	ModuleList: { ModuleEntry },

	State: LoaderState,

	Signals: any,

	GetModule: (self: Loader, name: string) -> Module?,
	GetSignal: (self: Loader, name: string) -> any,

	SetState: (self: Loader, key: string, value: any) -> (),
	GetState: (self: Loader, key: string) -> any,

	SetCharacter: (self: Loader, character: Model?) -> (),
	GetCharacter: (self: Loader) -> Model?,
	GetHumanoid: (self: Loader) -> Humanoid?,

	InitAll: (self: Loader) -> (),
	StartAll: (self: Loader) -> (),
}

return {}
local SignalRegistry = {}
SignalRegistry.__index = SignalRegistry

function SignalRegistry.new(Signal)
	local self = setmetatable({}, SignalRegistry)

	self.Signal = Signal
	self.Signals = {}

	return self
end

function SignalRegistry:Get(name: string)
	if not self.Signals[name] then
		self.Signals[name] = self.Signal.new()
	end

	return self.Signals[name]
end

function SignalRegistry:Destroy()
	for _, signal in pairs(self.Signals) do
		signal:Destroy()
	end

	table.clear(self.Signals)
end

return SignalRegistry

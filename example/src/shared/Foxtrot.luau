local module = {}
module.priority = 5

function module.init()
	print(`[INIT] My name is {script.Name} and my priority is {module.priority}.`)
end

function module.start()
	print(`[START] My name is {script.Name} and my priority is {module.priority}.`)
end

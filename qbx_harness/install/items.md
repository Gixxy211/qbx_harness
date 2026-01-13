## qb-inventory

```lua
harness                      = { name = 'harness', label = 'Race Harness', weight = 1000, type = 'item', image = 'harness.png', unique = true, useable = true, shouldClose = true, combinable = nil, description = 'Racing Harness so no matter what you stay in the car!' },

removal_tool                 = { name = 'removal_tool', label = 'Removal Tool', weight = 1000, type = 'item', image = 'screwdriverset.png', unique = false, useable = true, shouldClose = false, combinable = nil, description = 'A Harness Removal Tool' },
```

## ox_inventory

```lua
	["removal_tool"] = {
		label = "Removal Tool",
		weight = 1000,
		stack = true,
		close = false,
		description = "A Harness Removal Tool",
		client = {
			image = "screwdriverset.png",
		}
	},

	["harness"] = {
		label = "Race Harness",
		weight = 1000,
		stack = false,
		close = true,
		description = "Racing Harness so no matter what you stay in the car!",
		client = {
			image = "harness.png",
		}
	},
```
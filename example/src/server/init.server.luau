local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lambda = require("../../lib")

print("Requiring modules from server")
lambda(ReplicatedStorage)
print("Successsfully loaded modules from server")

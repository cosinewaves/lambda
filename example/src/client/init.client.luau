local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lambda = require("../../lib")

print("Requiring modules from client")
lambda(ReplicatedStorage)
print("Successsfully loaded modules from client")

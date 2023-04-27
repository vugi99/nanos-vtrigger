

-- All the entities that can trigger overlap events
local Moving_Entities = {}
for k, v in pairs(debug.getregistry().classes) do
    local meta = getmetatable(v)
    if (meta and meta.__call) then
        if (v.__function.GetLocation) then
            table.insert(Moving_Entities, v.__name)
        end
    end
end

All_VTriggers = {}
local Trigger_ID = 0

local Coordaxis = {
    "X",
    "Y",
    "Z",
}


Package.Export("VTrigger", {})


function VTrigger_Constructor(location, rotation, extent, trigger_type, is_visible, color, overlap_only_classes)
    if (location and rotation and extent and trigger_type and color) then
        local trigger = setmetatable({}, VTrigger.prototype)

        overlap_only_classes = overlap_only_classes or Moving_Entities

        trigger.InitValues = {
            location = location,
            rotation = rotation,
            extent = extent,
            trigger_type = trigger_type,
            is_visible = is_visible,
            color = color,
            overlap_only_classes = overlap_only_classes,
        }
        trigger.Stored = {}
        trigger.Stored.Values = {}
        trigger.Valid = true
        trigger.Sub_Callbacks = {}
        trigger.Overlapping_Entities = {}

        Trigger_ID = Trigger_ID + 1
        trigger.ID = Trigger_ID

        local l_count = table_last_count(All_VTriggers)
        All_VTriggers[l_count + 1] = trigger

        VTrigger_CallEvent_Internal(trigger, "Spawn", trigger)

        return trigger
    end
end
setmetatable(VTrigger, {
    __call = function (self, ...)
        return VTrigger_Constructor(...)
    end,
})

VTrigger.__index = VTrigger
VTrigger.prototype = {}
VTrigger.prototype.__index = VTrigger.prototype
VTrigger.prototype.constructor = VTrigger


function table_count(ta)
    local count = 0
    for k, v in pairs(ta) do count = count + 1 end
    return count
end

function table_last_count(ta)
    local count = 0
    for i, v in ipairs(ta) do
        if v then
            count = count + 1
        end
    end
    return count
end



function VTrigger.prototype:IsValid(is_from_self)
    local valid = self.Valid
    if (not valid and is_from_self) then
        error("This entity has been destroyed")
    end
    return valid
end

function VTrigger.prototype:GetID()
    if self:IsValid(true) then
        return self.ID
    end
end


function VTrigger.prototype:SetValue(key, value)
    if self:IsValid(true) then
        if (not self.Stored.Values[key] or self.Stored.Values[key] ~= value) then
            self.Stored.Values[key] = value
            VTrigger_CallEvent_Internal(self, "ValueChange", self, key, value)
            return true
        end
    end
end

function VTrigger.prototype:GetValue(key)
    if self:IsValid(true) then
        if self.Stored.Values[key] then
            return self.Stored.Values[key]
        end
    end
end

function VTrigger.prototype:GetLocation()
    if self:IsValid(true) then
        return self.InitValues.location
    end
end

function VTrigger.prototype:GetRotation()
    if self:IsValid(true) then
        return self.InitValues.rotation
    end
end

function VTrigger.prototype:SetLocation(location)
    if self:IsValid(true) then
        self.InitValues.location = location
        return true
    end
end

function VTrigger.prototype:SetRotation(rotation)
    if self:IsValid(true) then
        self.InitValues.rotation = rotation
        return true
    end
end

function VTrigger.prototype:SetExtent(extent)
    if self:IsValid(true) then
        self.InitValues.extent = extent
        return true
    end
end

function VTrigger.prototype:Destroy()
    if self:IsValid(true) then
        VTrigger_CallEvent_Internal(self, "Destroy", self)
        self.Valid = false
        for k, v in pairs(All_VTriggers) do
            if v == self then
                All_VTriggers[k] = nil
                break
            end
        end
        return true
    end
end

function VTrigger.prototype:Subscribe(event, callback)
    if self:IsValid(true) then
        if not self.Sub_Callbacks[event] then
            self.Sub_Callbacks[event] = {}
        end
        self.Sub_Callbacks[event][callback] = callback
        return true
    end
end

function VTrigger.prototype:Unsubscribe(event, callback)
    if self:IsValid(true) then
        if self.Sub_Callbacks[event] then
            if self.Sub_Callbacks[event][callback] then
                self.Sub_Callbacks[event][callback] = nil
                return true
            end
        end
    end
end

function VTrigger.prototype:__eq(other)
    if other.ID then
        if other.ID == self.ID then
            return true
        end
    end
    return false
end

function VTrigger.prototype:ForceOverlapChecking()
    if self:IsValid(true) then
        for k2, v2 in pairs(self.Overlapping_Entities) do
            if v2 then
                if not v2:IsValid() then
                    self.Overlapping_Entities[k2] = nil
                else
                    v2:SetValue("OverlappingToThisTrigger", false)
                end
            end
        end

        local trigger_loc = self:GetLocation()
        if self.InitValues.trigger_type == TriggerType.Sphere then
            local distance_from_sphere = self.InitValues.extent.X^2
            for i, v in ipairs(self.InitValues.overlap_only_classes) do
                if self:IsValid() then
                    for k2, v2 in pairs(_ENV[v].GetPairs()) do
                        local entity_location = v2:GetLocation()
                        if trigger_loc:DistanceSquared(entity_location) <= distance_from_sphere then
                            self:InternalInTrigger(v2)
                            if not self:IsValid() then
                                break
                            end
                        end
                    end
                end
            end
        elseif self.InitValues.trigger_type == TriggerType.Box then
            local trigger_rot = self:GetRotation()
            local coord_vectors = {
                X = trigger_rot:GetForwardVector(),
                Y = trigger_rot:GetRightVector(),
                Z = trigger_rot:GetUpVector(),
            }

            local extent = self.InitValues.extent
            local MinLoc, MaxLoc = Vector(trigger_loc.X, trigger_loc.Y, trigger_loc.Z), Vector(trigger_loc.X, trigger_loc.Y, trigger_loc.Z)
            local length_Vector = Vector()
            local local_Vector = Vector()
            for i, v in ipairs(Coordaxis) do
                MinLoc = MinLoc - coord_vectors[v] * extent[v]
                MaxLoc = MaxLoc + coord_vectors[v] * extent[v]
                length_Vector[v] = extent[v]^2
                local_Vector[v] = extent[v]/length_Vector[v]
            end

            --Debug.DrawPoint(Vector(MinLoc.X, MinLoc.Y, MinLoc.Z), Color.RED, 0.01, 10)
            --Debug.DrawPoint(Vector(MaxLoc.X, MaxLoc.Y, MaxLoc.Z), Color.RED, 0.01, 10)

            for i, v in ipairs(self.InitValues.overlap_only_classes) do
                if self:IsValid() then
                    for k2, v2 in pairs(_ENV[v].GetPairs()) do
                        local entity_location = v2:GetLocation()
                        if IsPointInCube(entity_location, MinLoc, MaxLoc) then
                            self:InternalInTrigger(v2)
                            if not self:IsValid() then
                                break
                            end
                        end
                    end
                end
            end
        end

        if self:IsValid() then
            for k2, v2 in pairs(self.Overlapping_Entities) do
                if v2 then
                    if v2:IsValid() then
                        if (not v2:GetValue("OverlappingToThisTrigger") or not v2:GetValue("OverlappingToThisTrigger") == self:GetID()) then
                            self.Overlapping_Entities[k2] = nil
                            VTrigger_CallEvent_Internal(self, "EndOverlap", self, v2)
                            if not self:IsValid() then
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

function VTrigger.prototype:InternalInTrigger(entity)
    if self:IsValid(true) then
        if self.Overlapping_Entities[entity:GetID()] then
            entity:SetValue("OverlappingToThisTrigger", self:GetID())
        else
            self.Overlapping_Entities[entity:GetID()] = entity
            entity:SetValue("OverlappingToThisTrigger", self:GetID())
            VTrigger_CallEvent_Internal(self, "BeginOverlap", self, entity)
        end
    end
end

function VTrigger.GetPairs()
    return All_VTriggers
end

function VTrigger.GetAll()
    local tbl = {}
    for k, v in pairs(VTrigger.GetPairs()) do
        table.insert(tbl, v)
    end
    return tbl
end

function VTrigger.GetByIndex(index)
    if All_VTriggers[index] then
        return All_VTriggers[index]
    end
end


Global_Sub_Callbacks = {}

function VTrigger.Subscribe(event, callback)
    if not Global_Sub_Callbacks[event] then
        Global_Sub_Callbacks[event] = {}
    end
    Global_Sub_Callbacks[event][callback] = callback
    return true
end

function VTrigger.Unsubscribe(event, callback)
    if Global_Sub_Callbacks[event] then
        if Global_Sub_Callbacks[event][callback] then
            Global_Sub_Callbacks[event][callback] = nil
            return true
        end
    end
end

function VTrigger_CallEvent_Internal(trigger, event, ...)
    if Global_Sub_Callbacks[event] then
        for k, v in pairs(Global_Sub_Callbacks[event]) do
            if v then
                v(...)
            end
        end
    end

    if trigger.Sub_Callbacks[event] then
        for k, v in pairs(trigger.Sub_Callbacks[event]) do
            if v then
                v(...)
            end
        end
    end
end


Client.Subscribe("Tick", function(ds)
    for k, v in pairs(All_VTriggers) do
        if v:IsValid() then
            v:ForceOverlapChecking()
            if v:IsValid() then
                if v.InitValues.is_visible then
                    if v.InitValues.trigger_type == TriggerType.Sphere then
                        Debug.DrawSphere(v:GetLocation(), v.InitValues.extent.X, 25, v.InitValues.color, 0.01, 0)
                    elseif v.InitValues.trigger_type == TriggerType.Box then
                        Debug.DrawBox(v:GetLocation(), v.InitValues.extent, v:GetRotation(), v.InitValues.color, 0.01, 0)
                    end
                end
            end
        end
    end
end)

function IsPointInCube(loc, MinLoc, MaxLoc)
    --[[for i, v in ipairs(Coordaxis) do
        local ToPoint = loc - cube_loc
        local vector = ToPoint * local_Vector[v]
        if math.sqrt(vector.X ^2 + vector.Y^2 + vector.Z^2) > length_Vector[v] then
            return false
        end
    end]]--
    for i, v in ipairs(Coordaxis) do
        if loc[v] < MinLoc[v] or loc[v] > MaxLoc[v] then
            return false
        end
    end
    return true
end
# nanos-vtrigger


### How to import
```lua
-- Server to make sure the client will download the package
Package.RequirePackage("vtrigger")

-- Client
Package.RequirePackage("vtrigger")
```

### Triggers you spawned can only be used in your package, you can't use vtriggers from other packages.

### Refer to the [Trigger docs](https://docs.nanos.world/docs/scripting-reference/classes/trigger)

### Functions List
* VTrigger(location, rotation, extent, trigger_type, is_visible, color)
* trigger:IsValid()
* trigger:GetID() - This returns an unique trigger ID and is not unique if you compare it with nanos entities IDs.
* trigger:SetValue(key, value)
* trigger:GetValue(key)
* trigger:GetLocation()
* trigger:GetRotation()
* trigger:SetLocation(location)
* trigger:SetRotation(rotation)
* trigger:SetExtent(extent)
* trigger:Destroy()
* trigger:Subscribe(event, callback)
* trigger:Unsubscribe(event, callback)
* vtrigger == other_vtrigger
* trigger:ForceOverlapChecking()
* VTrigger.GetPairs()
* VTrigger.GetAll()
* VTrigger.GetByIndex(index)
* VTrigger.Subscribe(event, callback)
* VTrigger.Unsubscribe(event, callback)
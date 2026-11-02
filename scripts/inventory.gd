extends Node
## Local prototype inventory. Server-side validation will replace client authority in multiplayer.

signal changed(items: Dictionary)
var items: Dictionary = {}

func add_item(item_id: String, amount: int) -> void:
    items[item_id] = int(items.get(item_id, 0)) + amount
    changed.emit(items)

func remove_item(item_id: String, amount: int) -> bool:
    var current := int(items.get(item_id, 0))
    if current < amount:
        return false
    items[item_id] = current - amount
    changed.emit(items)
    return true

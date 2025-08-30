class_name ItemAction
extends Resource

enum TYPE {INSTANTLY, BUFF}

## Define a ação que um item pode realizar, como curar, aumentar atributos, etc.
@export var action_type: TYPE = TYPE.INSTANTLY
## O atributo que será afetado pela ação do item
@export var attribute: ItemAttribute
@export var duration: float = 0.0

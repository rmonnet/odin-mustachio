package mustachio

import "core:encoding/json"
import "core:fmt"
import "core:strings"

lookup :: proc(v: json.Value, key: string) -> (value: json.Value, ok: bool) {

	if key == "" { return }
	v_as_obj, is_obj := v.(json.Object)
	if !is_obj { return }

	if idx := strings.index(key, "."); idx > -1 {
		key1 := key[0:idx]
		return lookup(v_as_obj[key1], key[idx + 1:len(key)])
	}

	value, ok = v_as_obj[key]
	return
}

primitive_to_string :: proc(v: json.Value, allocator := context.allocator) -> string {

	#partial switch value in v {
	case json.Integer:
		return fmt.aprintf("%d", v, allocator = allocator)
	case json.Float:
		if value == f64(int(value)) {
			return fmt.aprintf("%d", int(value), allocator = allocator)
		} else {
			return fmt.aprintf("%f", value, allocator = allocator)
		}
	case json.Boolean:
		return fmt.aprintf("%t", value, allocator = allocator)
	case json.String:
		return fmt.aprintf("%s", value, allocator = allocator)
	}
	return ""
}

is_primitive :: proc(v: json.Value) -> bool {

	return !(is_object(v) || is_array(v))
}

is_object :: proc(v: json.Value) -> bool {

	_, is_object := v.(json.Object)
	return is_object
}

is_array :: proc(v: json.Value) -> bool {

	_, is_array := v.(json.Array)
	return is_array
}

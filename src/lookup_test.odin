package mustachio

import "core:encoding/json"
import "core:testing"

load_json :: proc() -> json.Value {

	data := `
{
    "name": "robert",
    "age": 63,
    "temperature": 80.5,
    "retired": true,
    "fav_numbers": [1, 7, 42],
    "fav_singers": ["Pat Benatar", "Andie Case", "J. P. Capdevielle"]
    "others": {
        "animal": "dog",
        "car": "mustang",
        "gears": {
            "camera": "xt3",
            "lens": "xf30-150mm"}
    }
}
`

	json_data, err := json.parse(transmute([]u8)data)
	ensure(err == .None)
	return json_data
}

@(test)
test_lookup_string_value :: proc(t: ^testing.T) {

	json_data := load_json()
	defer json.destroy_value(json_data)
	name, ok := lookup(json_data, "name")
	testing.expect(t, ok)
	name_as_str := primitive_to_string(name)
	defer delete(name_as_str)
	testing.expect_value(t, name_as_str, "robert")
}

@(test)
test_lookup_missing_value :: proc(t: ^testing.T) {

	json_data := load_json()
	defer json.destroy_value(json_data)
	_, ok := lookup(json_data, "badname")
	testing.expect(t, !ok)
}

@(test)
test_lookup_int_value :: proc(t: ^testing.T) {

	json_data := load_json()
	defer json.destroy_value(json_data)
	age, ok := lookup(json_data, "age")
	testing.expect(t, ok)
	age_as_str := primitive_to_string(age)
	defer delete(age_as_str)
	testing.expect_value(t, age_as_str, "63")
}

@(test)
test_lookup_float_value :: proc(t: ^testing.T) {

	json_data := load_json()
	defer json.destroy_value(json_data)
	temp, ok := lookup(json_data, "temperature")
	testing.expect(t, ok)
	temp_as_str := primitive_to_string(temp)
	defer delete(temp_as_str)
	testing.expect_value(t, temp_as_str, "80.500")
}

@(test)
test_lookup_bool_value :: proc(t: ^testing.T) {

	json_data := load_json()
	defer json.destroy_value(json_data)
	retired, ok := lookup(json_data, "retired")
	testing.expect(t, ok)
	retired_as_str := primitive_to_string(retired)
	defer delete(retired_as_str)
	testing.expect_value(t, retired_as_str, "true")
}

@(test)
test_lookup_primitive :: proc(t: ^testing.T) {

	json_data := load_json()
	defer json.destroy_value(json_data)
	retired, ok := lookup(json_data.(json.Object)["name"], "name")
	testing.expect(t, !ok)
}

@(test)
test_lookup_nested :: proc(t: ^testing.T) {

	json_data := load_json()
	defer json.destroy_value(json_data)
	camera, ok := lookup(json_data, "others.gears.camera")
	testing.expect(t, ok)
	camera_as_str := primitive_to_string(camera)
	defer delete(camera_as_str)
	testing.expect_value(t, camera_as_str, "xt3")
}

@(test)
test_lookup_nested_badname :: proc(t: ^testing.T) {

	json_data := load_json()
	defer json.destroy_value(json_data)
	camera, ok := lookup(json_data, "others.gear.camera")
	testing.expect(t, !ok)
}

@(test)
test_lookup_nested_not_an_object :: proc(t: ^testing.T) {

	json_data := load_json()
	defer json.destroy_value(json_data)
	camera, ok := lookup(json_data, "retired.age")
	testing.expect(t, !ok)
}

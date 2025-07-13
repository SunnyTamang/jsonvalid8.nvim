#!/usr/bin/env python3
import sys
import json
import traceback
from jsonschema import Draft7Validator, SchemaError

if len(sys.argv) != 3:
    print(json.dumps({"error": "Usage: validate_jsonschema.py <schema.json> <data.json>"}))
    sys.exit(1)

schema_path = sys.argv[1]
data_path = sys.argv[2]

try:
    with open(schema_path, 'r') as f:
        schema = json.load(f)
    with open(data_path, 'r') as f:
        data = json.load(f)
except Exception as e:
    print(json.dumps({"error": f"Failed to read files: {str(e)}"}))
    sys.exit(1)

try:
    validator = Draft7Validator(schema)
    errors = sorted(validator.iter_errors(data), key=lambda e: list(e.path))
    if not errors:
        print(json.dumps({"valid": True}))
    else:
        print(json.dumps({
            "valid": False,
            "errors": [
                {
                    "message": e.message,
                    "path": list(e.path),
                    "schema_path": list(e.schema_path)
                } for e in errors
            ]
        }))
    sys.exit(0)
except SchemaError as e:
    print(json.dumps({"error": f"Invalid schema: {str(e)}"}))
    sys.exit(1)
except Exception as e:
    print(json.dumps({"error": f"Unexpected error: {str(e)}", "trace": traceback.format_exc()}))
    sys.exit(1) 
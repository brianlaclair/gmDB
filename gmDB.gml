// gmDB
// Version: WIP
// Author: Brian LaClair
// License: MIT

function gmDB () constructor {
    
    store = {};

    create = function (table, definition = {}) 
    {
        // Check if it already exists
        if (!is_undefined(struct_get(self.store, table))) {
            return false;
        }

        struct_set(self.store, table, new self.table(definition));
        return true;
    }

    table = function (_definition = {}, _rows = []) constructor {

        definition  = _definition;
        rows        = _rows;
        
        __definitionArray = struct_get_names(self.definition);
        __definitionCount = array_length(self.__definitionArray);
        
        getColumns = function () {
            return struct_get_names(self.definition);
        }

        size = function () {
            var count = 0;
            if (is_array(self.rows)) {
                count = array_length(self.rows);
            }
            return count;
        }

        insert = function(row) {
            if (!is_struct(row)) {
                return false;
            }

            var _row        = {};
            for (var _i = 0; _i < self.__definitionCount; _i++) {

                var _input      = struct_get(row,               self.__definitionArray[_i]); 
                var _expected   = struct_get(self.definition,   self.__definitionArray[_i]);

                // Handle callbacks
                if (variable_struct_exists(_expected, "callback")) { 
                    _input = _expected.callback();
                }

                if (variable_struct_exists(_expected, "auto_increment") && is_undefined(_input) && _expected.type == "number" && _expected.auto_increment) {
                    _input = 0;

                    if (array_length(self.rows)) {
                        _input = struct_get(array_last(self.rows), self.__definitionArray[_i]);
                        _input++;
                    }
                }

                // Type of input does not match expected type
                // and the input exists while the field is not nullable
                if (!_expected.nullable && is_undefined(_input)) {
                    return false;
                }

                if (typeof(_input) != _expected.type && !_expected.nullable) {
                    return false;
                }

                var _value = _input;

                struct_set(_row, self.__definitionArray[_i], _value);
            }

            array_push(self.rows, _row);

            return true;
        }

        select = function (values = [])
        {
            var _return = [];

            // if the values struct is empty, we're trying to get each discrete value
            if (!array_length(values)) {
                values = self.getColumns();
            }

            var _rows        = self.rows;
            var _rowsCount   = array_length(_rows);    

            for (var _i = 0; _i < _rowsCount; _i++) {
                var _row = _rows[_i];
                var _entry = {};
                for (var _v = 0; _v < array_length(values); _v++) {
                    struct_set(_entry, values[_v], variable_struct_exists(_row, values[_v]) ? struct_get(_row, values[_v]) : undefined);
                }
                array_push(_return, _entry);
            }

            return _return;
        }

        toString = function () {
            return json_stringify({
                definition: self.definition,
                rows: self.rows
            });
        }
    }

    exists = function (table)
    {
        if (!struct_exists(self.store, table)) {
            return false;
        }
        
        return true;
    }

    // ABST
    insert = function (table, row)
    {
        _tablePointer = struct_get(self.store, table);
        return _tablePointer.insert(row);
    }
    
    // ABST
    select = function (table, values = []) 
    {
        var _return = [];
        if (self.exists(table)) {
            _return = struct_get(self.store, table).select(values);
        }
        return _return;
    }
}
// gmDB
// Version: 1.0 ( 2025.04.03 )
// Author: Brian LaClair
// License: MIT

/**
* Creates a new gmDB instance.
* 
* @return {Struct.gmDB}
*/
function gmDB () constructor {
    
    store   = {};

    /**
    * Returns the current database store as a JSON string.
    * @return {String} JSON string representing the database.
    */
    save = function() {
        return json_stringify(self.store);
    }
    
    /**
    * Loads a database from a JSON string.
    * Reconstructs tables and their rows.
    *
    * @param {String} dbBlob - JSON string representing a dumped database.
    * @param {Bool} [loadConfig=false] - Use the input to construct the table definitions.
    * @return {Bool} True if loading was successful, false otherwise.
    */
    load = function(dbBlob, loadConfig = false) {
        var parsed;
        try {
            parsed = json_parse(dbBlob);
        } catch(e) {
            return false;
        }
        
        if (loadConfig) {
            self.store = {};
        }

        var tableNames = struct_get_names(parsed);

        for (var _i = 0; _i < array_length(tableNames); _i++) {
            if (variable_struct_exists(parsed, tableNames[_i])) {
                var tableData = struct_get(parsed, tableNames[_i]);

                if (loadConfig) {
                    var newTable = new self.table(tableData.definition, tableData.rows);
                    struct_set(self.store, tableNames[_i], newTable);
                } else if (struct_exists(self.store, tableNames[_i])) {
					struct_get(self.store, tableNames[_i]).rows = [];
					for (var _rows = 0; _rows < array_length(tableData.rows); _rows++) {
						array_push(struct_get(self.store, tableNames[_i]).rows, tableData.rows[_rows]);	
					}
                }
            }
        }

        return true;
    }

    /**
    * Creates a new table object.
    *
    * @constructor
    * @param {Struct} [_definition={}] The table definition.
    * @param {Array} [_rows=[]] The initial rows for the table.
    */
    table = function (_definition = {}, _rows = []) constructor {
        /**
        * The table definition object.
        * @type {Object}
        */
        definition  = _definition;

        /**
        * The array of row objects for this table.
        * @type {Array}
        */
        rows        = _rows;
        
        __definitionArray = struct_get_names(self.definition);
        __definitionCount = array_length(self.__definitionArray);
        
        /** 
        * Inserts a row into the table.
        * @function
        * @private
        * @param {Struct} row - The row data to insert.
        * @return {Bool} True if insertion was successful, false otherwise.
        */
        __insert = function(row) {
            if (!is_struct(row)) {
                return false;
            }

            var newRow = {};
        
            for (var i = 0; i < self.__definitionCount; i++) {
                var fieldName = self.__definitionArray[i];
                var inputValue   = struct_get(row, fieldName);
                var fieldDef     = struct_get(self.definition, fieldName);
                
                var nullable     = struct_get(fieldDef, "nullable");
                nullable         = is_undefined(nullable) ? true : nullable;
        
                if (is_undefined(inputValue) && variable_struct_exists(fieldDef, "callback")) {
                    inputValue = method_call(fieldDef.callback); 
                }

                if (is_undefined(inputValue) && variable_struct_exists(fieldDef, "auto_increment") && fieldDef.type == "number" && fieldDef.auto_increment)
                {
                    inputValue = 0;
                    if (array_length(self.rows)) {
                        var lastRowValue = struct_get(array_last(self.rows), fieldName);
                        inputValue = lastRowValue + 1;
                    }
                }
        
                if (!nullable && is_undefined(inputValue)) {
                    return false;
                }
        
                if (!nullable && typeof(inputValue) != fieldDef.type) {
                    return false;
                }
        
                struct_set(newRow, fieldName, inputValue);
            }

            array_push(self.rows, newRow);
            return true;
        }

        /**
        * Selects rows from the table.
        *
        * @function
        * @private
        * @return {Struct} A result object containing the table's rows.
        */
        __select = function () {
            return new self.result(self.rows, self);
        }

        /**
        * Constructs a result set from a table query.
        *
        * @constructor
        * @param {Array} [_res=[]] The initial result rows.
        * @param {Struct} [_parentTable=undefined] Reference to the parent table. 
        * @returns {Struct}
        */
        result = function (_res = [], _parentTable = undefined) constructor {
            /**
            * The array of rows in the result set.
            * @type {Array}
            */
            result          = _res;

            /** 
            * Reference to the parent table from which this result set was generated. 
            * @type {table} 
            */
            parentTable     = _parentTable;
            
            /** 
            * Filters the result set using provided condition functions. 
            *
            * @function
            * @param {Array.<Function>|Function} [conditions] A single function, or an Array of functions that each return a boolean.
            * @return {Struct.gmDB$$table$$result} The result object after filtering.
            */
            where = function (conditions) {
                if (!is_array(conditions)) {
                    conditions = [conditions];
                }
                var conditionsLength = array_length(conditions);
                for (var i = 0; i < conditionsLength; i++) {
                    var filtered = [];
                    var resLength = array_length(self.result);
                    for (var r = 0; r < resLength; r++) {
                        if (conditions[i](self.result[r])) {
                            array_push(filtered, self.result[r]);
                        }
                    }
                    self.result = filtered;
                }
                return self;
            }

            /**
            * Removes (deletes) the rows in the result set from the parent table.
            *
            * @function 
            * @return {Struct.gmDB$$table$$result} The result object after deletion.
            */
            remove = function() {
                var resLength = array_length(self.result);
                for (var i = 0; i < resLength; i++) {
                    var rowToDelete = self.result[i];
                    var newRows = [];
                    var parentRows = parentTable.rows;
                    var parentRowsLength = array_length(parentRows);
                    for (var j = 0; j < parentRowsLength; j++) {
                        if (parentRows[j] != rowToDelete) {
                            array_push(newRows, parentRows[j]);
                        }
                    }
                    parentTable.rows = newRows;
                }
                self.result = [];
                return self;
            }

            /**
            * Updates the rows in the result set with new values.
            *
            * @function
            * @param {Struct} updateData - Object with keys and their new values.
            * @return {Struct.gmDB$$table$$result} The result object after updating.
            */
            update = function (updateData) {
                var tableDef    = parentTable.definition;
                var keys        = struct_get_names(updateData);
                var numKeys     = array_length(keys);

                for (var i = 0; i < array_length(self.result); i++) {
                    var row = self.result[i];

                    for (var j = 0; j < numKeys; j++) {
                        var key = keys[j];
                        var newVal = struct_get(updateData, key);
                        var fieldDef = struct_get(tableDef, key);

                        if (is_undefined(fieldDef)) {
                            continue;
                        }

                        if (typeof(newVal) == "method") {
                            newVal = method_call(newVal, [row]);
                        }

                        var nullable = struct_get(fieldDef, "nullable");
                        nullable = is_undefined(nullable) ? true : nullable;
                        
                        if (!nullable && is_undefined(newVal)) {
                            continue;
                        }
                        
                        if (!nullable && typeof(newVal) != fieldDef.type) {
                            continue;
                        }
                        
                        struct_set(row, key, newVal);
                    }
                }
                return self;
            };

            /**
            * Returns a read-only array of the current result set
            *
            * @function getResult(...) 
            * @param {String} [columns...]     
            * @return {Array<Struct>} Read-only version of result set.
            */
            getResult = function() { 
                var _return   = [];
                var _itemKeys = [];
                var itemCount = argument_count;
                
                if (itemCount) {
                    for (var _i = 0; _i < itemCount; _i++) {
                        array_push(_itemKeys, string(argument[_i]));
                    }
                } else {
                    _itemKeys = parentTable.__definitionArray;
                }

                for (var _r = 0; _r < array_length(self.result); _r++) {
                    var _thisItem       = {};
                    var _thisItemKeys   = struct_get_names(self.result[_r]);
                    _thisItemKeys       = array_intersection(_thisItemKeys, _itemKeys);
                    
                    for (var _ik = 0; _ik < array_length(_thisItemKeys); _ik++) {
                        struct_set(_thisItem, _thisItemKeys[_ik], variable_struct_get(self.result[_r], _thisItemKeys[_ik]));
                    }
                    
                    array_push(_return, _thisItem);
                }
                
                return _return;
            }

            /**
            * Returns the number of rows in the result set.
            *
            * @function
            * @return {Real} The count of rows.
            */
            getSize = function () {
                var count = 0;
                if (is_array(self.result)) {
                    count = array_length(self.result);
                }
                return count;
            }
        }
    }

    /**
    * Creates a new table in the database.
    *
    * @function
    * @param {String} table - The name of the table.
    * @param {Struct} [definition={}] The table definition.
    * @return {Bool} True if the table was created, false if it already exists.
    */
    create = function (table, definition = {}) {
        if (!is_undefined(struct_get(self.store, table))) {
            return false;
        }
        struct_set(self.store, table, new self.table(definition));
        return true;
    }
 
    /**
    * Checks if a table exists in the database.
    *
    * @function
    * @param {String} table - The name of the table.
    * @return {Bool} True if the table exists, false otherwise.
    */
    exists = function (table) {
        return struct_exists(self.store, table);
    }

    /**
    * Inserts a row into a specified table.
    *
    * @function
    * @param {String} table - The name of the table.
    * @param {Struct} row - The row data to insert.
    * @return {Bool} True if insertion was successful, false otherwise.
    */
    insert = function (table, row) {
        var tablePointer = struct_get(self.store, table);
        if (is_undefined(tablePointer)) {
            return false;
        }
        return tablePointer.__insert(row);
    }
    
    /**
    * Selects rows from a specified table.
    *
    * @function
    * @param {String} table - The name of the table.
    * @return {Struct.gmDB$$table$$result} A result object containing the rows, or void if the table doesn't exist.
    */
    select = function (table) {
        if (self.exists(table)) {
            return struct_get(self.store, table).__select();
        }
    }

}

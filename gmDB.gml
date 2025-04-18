// gmDB
// Version: 1.0 ( 2025.04.03 )
// Author: Brian LaClair, Shortbread
// License: MIT

#region Define Data Types

	enum gmDB_type {
		number,
		string,
		array,
		bool,
		int32,
		int64,
		ptr,
		undefined,
		method,
		struct,
		object,
		sprite,
		room,
		path,
		shader,
		sequence,
		particle_system,
		sound,
		tileset,
		timeline,
		animcurve,
		font,
		instance,
	}

	// Store list of types and their names
	global.__gmdb_type_list = [];
	global.__gmdb_type_list[gmDB_type.number] = "number";
	global.__gmdb_type_list[gmDB_type.string] = "string";
	global.__gmdb_type_list[gmDB_type.array] = "array";
	global.__gmdb_type_list[gmDB_type.bool] = "bool";
	global.__gmdb_type_list[gmDB_type.int32] = "int32";
	global.__gmdb_type_list[gmDB_type.int64] = "int64";
	global.__gmdb_type_list[gmDB_type.ptr] = "ptr";
	global.__gmdb_type_list[gmDB_type.undefined] = "undefined";
	global.__gmdb_type_list[gmDB_type.method] = "method";
	global.__gmdb_type_list[gmDB_type.struct] = "struct";
	global.__gmdb_type_list[gmDB_type.object] = "object";
	global.__gmdb_type_list[gmDB_type.sprite] = "sprite";
	global.__gmdb_type_list[gmDB_type.room] = "room";
	global.__gmdb_type_list[gmDB_type.path] = "path";
	global.__gmdb_type_list[gmDB_type.shader] = "shader";
	global.__gmdb_type_list[gmDB_type.sequence] = "sequence";
	global.__gmdb_type_list[gmDB_type.particle_system] = "particle_system_resource";
	global.__gmdb_type_list[gmDB_type.sound] = "sound";
	global.__gmdb_type_list[gmDB_type.tileset] = "tileset";
	global.__gmdb_type_list[gmDB_type.timeline] = "timeline";
	global.__gmdb_type_list[gmDB_type.animcurve] = "animcurve";
	global.__gmdb_type_list[gmDB_type.font] = "font";
	global.__gmdb_type_list[gmDB_type.instance] = "instance";

#endregion

/**
* Creates a new gmDB instance.
* 
* @return {Struct.gmDB}
*/
function gmDB () constructor {
	
    store = {};
	
	/**
	* Returns the type of the value given using gmDB_type enum values
	* @return {enum.gmDB_type} gmDB_type enum
	*/
	static __get_type = function(_value) {
		var _type_string;
		if (is_handle(_value)) {
			var _handle_str = string(_value);
			_type_string = string_copy(_handle_str, 5, string_pos_ext(" ",_handle_str,5) - 5);
		} else {
			_type_string = typeof(_value);
		}
		return array_get_index(global.__gmdb_type_list, _type_string);
	}

    /**
    * Returns the current database store as a JSON string.
    * @return {String} JSON string representing the database.
    */
    static save = function() {
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
    static load = function(_dbBlob, _loadConfig = false) {
        var parsed;
        try {
            parsed = json_parse(_dbBlob);
        } catch(e) {
            return false;
        }
        
        if (_loadConfig) {
            self.store = {};
        }

        var tableNames = struct_get_names(parsed);

        for (var _i = 0; _i < array_length(tableNames); _i++) {
            if (variable_struct_exists(parsed, tableNames[_i])) {
                var tableData = struct_get(parsed, tableNames[_i]);

                if (_loadConfig) {
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
    static table = function (_definition = {}, _rows = []) constructor {
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
        static __insert = function(_row) {
            if (!is_struct(_row)) {
                return false;
            }

            var newRow = {};
        
            for (var i = 0; i < self.__definitionCount; i++) {
                var fieldName	= self.__definitionArray[i];
                var inputValue  = struct_get(_row, fieldName);
                var fieldDef    = struct_get(self.definition, fieldName);
                var nullable    = struct_get(fieldDef, "nullable") ?? true;
        
                if (is_undefined(inputValue) && variable_struct_exists(fieldDef, "callback")) {
                    inputValue = method_call(fieldDef.callback); 
                }

                if (is_undefined(inputValue) && variable_struct_exists(fieldDef, "auto_increment") && fieldDef.type == gmDB_type.number && fieldDef.auto_increment) {
                    inputValue = 0;
                    if (array_length(self.rows)) {
                        var lastRowValue = struct_get(array_last(self.rows), fieldName);
                        inputValue = lastRowValue + 1;
                    }
                }
				
				if ((nullable && is_undefined(inputValue)) || (gmDB.__get_type(inputValue) == fieldDef.type)) {
					struct_set(newRow, fieldName, inputValue);
				} else {
					return false;
				}
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
        static __select = function () {
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
        static result = function (_res = [], _parentTable = undefined) constructor {
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
            static where = function (conditions) {
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
            static remove = function() {
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
            static update = function (updateData) {
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

                        var nullable = struct_get(fieldDef, "nullable") ?? true;
						
						if ((nullable && is_undefined(newVal)) || (gmDB.__get_type(newVal) == fieldDef.type)) {
							struct_set(row, key, newVal);
						} else {
							continue;
						}
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
            static getResult = function() { 
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
            static getSize = function () {
                return is_array(self.result) ? array_length(self.result) : 0;
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
    static create = function (_table, _definition = {}) {
        if (!is_undefined(struct_get(self.store, _table))) {
            return false;
        }
        struct_set(self.store, _table, new self.table(_definition));
        return true;
    }
 
    /**
    * Checks if a table exists in the database.
    *
    * @function
    * @param {String} table - The name of the table.
    * @return {Bool} True if the table exists, false otherwise.
    */
    static exists = function (_table) {
        return struct_exists(self.store, _table);
    }

    /**
    * Inserts a row into a specified table.
    *
    * @function
    * @param {String} table - The name of the table.
    * @param {Struct} row - The row data to insert.
    * @return {Bool} True if insertion was successful, false otherwise.
    */
    static insert = function (_table, _row) {
        var tablePointer = struct_get(self.store, _table);
        return is_undefined(tablePointer) ? false : tablePointer.__insert(_row);
    }
    
    /**
    * Selects rows from a specified table.
    *
    * @function
    * @param {String} table - The name of the table.
    * @return {Struct.gmDB$$table$$result} A result object containing the rows, or void if the table doesn't exist.
    */
    static select = function (_table) {
        if (self.exists(_table)) {
            return struct_get(self.store, _table).__select();
        }
    }

}

// Initialise the static functions
var _init = new gmDB();
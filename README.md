# gmDB 🗃️

A lightweight, fast, in-memory, and schema-aware database for [GameMaker](https://gamemaker.io/) projects.  

**Version:** 1.0  
**Author:** Brian LaClair  
**License:** [MIT](LICENSE)


## ✨ Features

- Create multiple named tables with strict schemas
- Insert, query, update, and remove rows
- Save and load database state as JSON
- Chainable, expressive query API
- Auto-increment fields and default callbacks
- 100% native GameMaker code – no extensions or dependencies


## 🚀 Getting Started

### ✅ Create a new database

```gml
var db = new gmDB();
```

### 📄 Define and create a table

```gml
var playerTable = {
    id: { type: "number", auto_increment: true, nullable: false },
    name: { type: "string", nullable: false },
    score: { type: "number", nullable: false }
};

db.create("players", playerTable);
```

### ➕ Insert rows

```gml
db.insert("players", { name: "Alice", score: 1200 });
db.insert("players", { name: "Bob", score: 980 });
```

### 🔍 Query rows

```gml
var result = db.select("players").where(function(row) {
    return row.score > 1000;
});

show_debug_message("High scorers: " + string(result.getSize()));
```

### ✏️ Update rows

```gml
result.update({ score: function(row) { return row.score + 100; } });
```

### ❌ Delete rows

```gml
result.remove();
```

### 💾 Save & Load

```gml
var saveData = db.save(); // returns a JSON string
// Save to file or buffer

db.load(saveData); // Load from a previously saved string
```

---

## 🧠 Table Schema Notes

Each field in a table schema is an object with:
- `type`: `"number"`, `"string"`, [and many more](https://manual.gamemaker.io/monthly/en/#t=GameMaker_Language%2FGML_Reference%2FVariable_Functions%2Ftypeof.htm)
- `nullable`: (optional, default `true`)
- `auto_increment`: (optional, for numeric fields)
- `callback`: (optional, function returning a default value)

Example:

```gml
{
    name: { type: "string", nullable: false },
    score: { type: "number", auto_increment: false, nullable: false },
    created_at: { type: "string", callback: function() { return date_time_string(); } }
}
```

## 🛠 API Reference

### Database (`gmDB`)
| Method | Description |
|--------|-------------|
| `create(name, definition)` | Creates a new table |
| `exists(name)` | Returns `true` if the table exists |
| `insert(name, row)` | Inserts a row into a table |
| `select(name)` | Selects rows from a table |
| `save()` | Returns the entire DB as JSON |
| `load(json, loadConfig)` | Loads JSON into the DB (optional `loadConfig`) |

### Query Result
Returned from `db.select(table)`

| Method | Description |
|--------|-------------|
| `where(fn)` | Filters rows using a function or array of functions |
| `update(struct)` | Updates fields for all rows in the result |
| `remove()` | Deletes matching rows from the parent table |
| `getResult(columns...)` | Returns matching rows (optionally filtered to specific columns, denoted by infinite string parameters) |
| `getSize()` | Returns the number of matched rows |


## 📦 Use Cases

- In-memory data structures for player data, enemies, or levels
- Save/load state to disk or cloud
- Powerful use cases in server-side GameMaker applications
- Replace spreadsheets for test-level configs
- Modding APIs with user-editable structured data


## 📚 Example

```gml
var db = new gmDB();

db.create("inventory", {
    id: { type: "number", auto_increment: true, nullable: false },
    item: { type: "string", nullable: false },
    qty: { type: "number", nullable: false }
});

db.insert("inventory", { item: "Potion", qty: 5 });
db.insert("inventory", { item: "Elixir", qty: 2 });

var potions = db.select("inventory").where(function(row) {
    return row.item == "Potion";
});

potions.update({ qty: function(row) { return row.qty + 1; } });

show_debug_message(potions.getResult()); // [{"id":0,"item":"Potion","qty":6}]
```

---

gmDB is a work-in-progress - please feel free to create an Issue or open a Pull Request if you'd like to contribute!
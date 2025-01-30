# gmDB

**Version:** WIP  
**Author:** Brian LaClair  
**License:** MIT

## Warning

gmDB is very much a work-in-progress. While the documentation below covers it's current capabilities, you should expect that breaking changes will occur often as development continues.
There are big ticket items that are currently completely missing, primarily:

- **WHERE**: Missing clause
- **UPDATE/SET**: Missing clause
- **JOIN**: Missing clause
- **Dump / Load**: The state of any gmDB should be dump-able and re-load-able
- **SQL**: All features should be accessible through SQL queries

To that end, it would be advisable to avoid using this code in it's current state for anything beyond tinkering and/or contributing to the project.

## Overview

gmDB is a lightweight, in-memory database system for GameMaker, designed to provide structured data storage and retrieval capabilities within GameMaker projects. It allows for the creation of tables with defined schemas, insertion of structured data, and basic querying capabilities.

## Features

- **Table Creation**: Define tables with structured fields and constraints.
- **Row Insertion**: Supports type validation, auto-increment fields, and nullable constraints.
- **Data Selection**: Retrieve specific columns from stored records.
- **In-Memory Storage**: Keeps all data within a structured format for fast access.

## Installation

To use `gmDB` in your GameMaker project:

1. Copy the `gmDB` script into your GameMaker project.
2. Create an instance of `gmDB` in your game object.

```gml
var database = new gmDB();
```

## Usage

### Creating a Table
To create a table with a specific schema:

```gml
database.create("players", {
    id: { type: "number", auto_increment: true },
    name: { type: "string", nullable: false },
    score: { type: "number", nullable: false }
});
```

### Inserting Data
To insert a new row into a table:

```gml
database.insert("players", {
    name: "Alice",
    score: 1200
});
```

### Selecting Data
Retrieve all rows and specific columns:

```gml
var all_players = database.select("players");
var player_scores = database.select("players", ["name", "score"]);
```

### Checking if a Table Exists

```gml
if (database.exists("players")) {
    show_debug_message("Table exists!");
}
```

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

## Contributing

Contributions are welcome! If you find any bugs or have suggestions for improvements, feel free to open an issue or submit a pull request.

## Acknowledgments

Developed by Brian LaClair.


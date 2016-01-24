---
layout: default
title: DeepDive Application's Structure and Operations
---

# DeepDive Application

## Structure

A DeepDive application is a directory that contains the following files and directories:

* `app.ddlog`

    Schema, extractors, and inference rules written in our higher-level language, [DDlog][], are put in this file.

* `db.url`

    A URL representing the database configuration is supposed to be stored in this file.
    For example, the following URL can be the line stored in it:

    ```
    postgresql://user:password@localhost:5432/database_name
    ```

    [SSL connections for PostgreSQL](https://jdbc.postgresql.org/documentation/91/ssl.html) can be enabled by setting parameter `ssl` as true in the URL, e.g.:

    ```
    postgresql://user:password@localhost:5432/database_name?ssl=true
    ```

    If you use a self-signed certificate, you may want to disable validation with an extra `sslfactory` parameter:

    ```
    postgresql://user:password@localhost:5432/database_name?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory
    ```

* `deepdive.conf`

    Extra configuration not expressed in the DDlog program is in this file.
    Extractors, and inference rules can be also be written in [HOCON][] syntax in this file, although DDlog is the recommended way.
    See the [Configuration Reference](configuration.md) for full details.

* `schema.sql`

    Data-Definition Language (DDL) statements for setting up the underlying database tables should be kept in this file.
    This may be omitted when the application is written in DDlog.

* `input/`

    Any data to be processed by this application is suggested to be kept under this directory.

    * `init.sh`

        In addition to the data files, there should be an executable script that knows how to load the data here to the database once its tables are created.

* `udf/`

    Any user-defined function (UDF) code is suggested to be kept under this directory.
    They can be referenced from deepdive.conf with path names relative to the application root.

* `run/`

    Each run of the DeepDive application has a corresponding subdirectory under this directory whose name contains the timestamp when the run was started, e.g., `run/20150618/223344.567890/`.
    All output and log files that belong to the run are kept under that subdirectory.
    There are a few symbolic links with mnemonic names to the most recently started run, last successful run, last failed run for handy access.

[DDlog]: ddlog
[HOCON]: https://github.com/typesafehub/config/blob/master/HOCON.md#readme "Human Optimized Configuration Object Notation"


## Operations

There are several operations that are frequently performed on a DeepDive application.
Any of the following command can be run under any subdirectory of a DeepDive application to perform a certain operation.

To see all options for each command, such as specifying alternative configuration file for running, see the online help message with the `deepdive help` command.  For example:

```bash
deepdive help run
```

### Initializing Database

```bash
deepdive initdb [TABLE]
```

This command initializes the underlying database configured for the application by creating necessary tables and loading the initial data into them.
If `TABLE` is not given, it makes sure the following:

1. The configured database is created.
2. The tables defined in `schema.sql` (for deepdive application) or `app.ddlog` (for ddlog application) are created.
3. The data that exists under `input/` is loaded into the tables with the help of `init.sh`.

If `TABLE` is given, it will make sure the following:

1. The configured database is created.
2. The given table is created.
3. The data that exists under `input/` is loaded into the `TABLE` with the help of `init_TABLE.sh`.


### Running Pipelines

```bash
deepdive run
```

This command runs the `default` pipeline defined in `deepdive.conf`.
It creates a new directory for the run under `run/`, which is first pointed by `run/RUNNING`, then pointed by `run/LATEST` after the run finishes successfully, or by `run/ABORTED` when it was unsuccessfully finished.

Optionally, the name of the pipeline can be specified as a command line argument to run it instead.
For example, the following command runs `my_pipeline` instead of `default`:

```bash
deepdive run my_pipeline
```


### Running SQL Queries

```bash
deepdive sql
```

This command opens a SQL prompt for the underlying database configured for the application.

Optionally, the SQL query can be passed as a command line argument to run and print its result to standard output.
For example, the following command prints the number of sentences per document:

```bash
deepdive sql "SELECT doc_id, COUNT(*) FROM sentences GROUP BY doc_id"
```

To get the result as tab-separated values (TSV), or comma-separated values (CSV), use the following command:

```bash
deepdive sql eval "SELECT doc_id, COUNT(*) FROM sentences GROUP BY doc_id" format=tsv
deepdive sql eval "SELECT doc_id, COUNT(*) FROM sentences GROUP BY doc_id" format=csv header=1
```

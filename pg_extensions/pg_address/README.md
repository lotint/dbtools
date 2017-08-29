# pg_address

## How to install this extension

1. Clone this repo
2. Install postgres dev files `sudo apt-get install postgresql-server-dev-9.6`
3. Go to folder `pg_extensions/pg_address` (current folder) and run `make install`

## How to enable this extension in db

```sql
CREATE EXTENSION pg_address;
```

## How to update extension to new version

```sql
ALTER EXTENSION pg_extension UPDATE;
```

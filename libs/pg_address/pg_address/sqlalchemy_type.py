
import asyncio
import psycopg2
from psycopg2 import extras
from sqlalchemy import event, types, func, cast
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.sql.expression import FunctionElement
from sqlalchemy.ext.compiler import compiles


def register_type(engine):
    @event.listens_for(engine, 'connect')
    def receive_connect(dbapi_connection, connection_record):
        extras.register_composite(
            'pg_address',
            connection_record.connection
        )


@asyncio.coroutine
def get_caster(name, conn):
    cur = yield from conn.cursor()

    # Use the correct schema
    if '.' in name:
        schema, tname = name.split('.', 1)
    else:
        tname = name
        schema = 'public'

    # column typarray not available before PG 8.3
    typarray = conn.server_version >= 80300 and "typarray" or "NULL"

    # get the type oid and attributes
    yield from cur.execute("""\
        SELECT t.oid, %s, attname, atttypid
        FROM pg_type t
        JOIN pg_namespace ns ON typnamespace = ns.oid
        JOIN pg_attribute a ON attrelid = typrelid
        WHERE typname = %%s AND nspname = %%s
            AND attnum > 0 AND NOT attisdropped
        ORDER BY attnum;
    """ % typarray, (tname, schema))

    recs = [rec for rec in (yield from cur.fetchall())]

    if not recs:
        raise psycopg2.ProgrammingError(
            "PostgreSQL type '%s' not found" % name)

    type_oid = recs[0][0]
    array_oid = recs[0][1]
    type_attrs = [(r[2], r[3]) for r in recs]

    caster = extras.CompositeCaster(
        tname, type_oid, type_attrs,
        array_oid=array_oid, schema=schema)

    class FactoryCaster(extras.CompositeCaster):

        @classmethod
        def _from_db(cls, name, conn):
            return caster

    return FactoryCaster


def async_register_type(engine):
    with (yield from engine) as conn:
        factory = yield from get_caster('pg_address', conn._connection)
        extras.register_composite(
            'pg_address',
            None,
            globally=True,
            factory=factory,
        )


class Array(FunctionElement):
    name = 'array'


@compiles(Array)
def compile(element, compiler, **kw):
    return 'ARRAY[%s]' % compiler.process(element.clauses)


class PgAddressMixin:

    def _process_dict(self, value, type_):
        return func.ROW(
            value.get('country'),
            value.get('region'),
            value.get('city'),
            value.get('zip_code'),
            value.get('street'),
            value.get('num'),
            type_=type_
        )


class PgAddressType(PgAddressMixin, types.UserDefinedType,):

    def get_col_spec(self, **kw):
        return 'pg_address'

    def bind_expression(self, bindvalue):
        return self._process_dict(bindvalue.value, self)

    def result_processor(self, dialect, coltype):
        def process(value):
            return {
                'country': value.country,
                'region': value.region,
                'zip_code': value.zip_code,
                'city': value.city,
                'street': value.street,
                'num': value.num,
            }
        return process


class PgAddressArrayType(PgAddressMixin, ARRAY):

    def __init__(self, *args, **kwargs):
        kwargs['item_type'] = PgAddressType
        super().__init__(*args, **kwargs)

    def get_col_spec(self, **kw):
        return 'pg_address[]'

    def bind_expression(self, bindvalue):
        values = [
            self._process_dict(item, self.item_type)
            for item in bindvalue.value
        ]
        return cast(Array(*values, type_=self), self)

    def result_processor(self, dialect, coltype):
        item_proc = self.item_type.dialect_impl(dialect).\
            result_processor(dialect, coltype)

        def process(value):
            return [
                item_proc(item)
                for item in value
            ]
        return process

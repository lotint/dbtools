
import psycopg2
from sqlalchemy import event, types, func, cast
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.sql.expression import FunctionElement
from sqlalchemy.ext.compiler import compiles


def register_type(engine):
    @event.listens_for(engine, 'connect')
    def receive_connect(dbapi_connection, connection_record):
        psycopg2.extras.register_composite(
            'pg_address',
            connection_record.connection
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


import psycopg2
from sqlalchemy import event, types, func


def register_type(engine):
    @event.listens_for(engine, 'connect')
    def receive_connect(dbapi_connection, connection_record):
        psycopg2.extras.register_composite(
            'pg_address',
            connection_record.connection
        )


class PgAddressType(types.UserDefinedType):

    def get_col_spec(self, **kw):
        return 'pg_address'

    def bind_expression(self, bindvalue):
        value = bindvalue.value
        return func.ROW(
            value.get('country'),
            value.get('region'),
            value.get('city'),
            value.get('zip_code'),
            value.get('street'),
            value.get('num'),
            type_=self,
        )

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

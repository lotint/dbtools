
import os
import unittest

from sqlalchemy import create_engine, MetaData, Table, Column, Integer

from pg_address import register_type, PgAddressType


DB_URI = os.environ.get('DB_URI', 'postgresql://localhost/')


class TestPgAddress(unittest.TestCase):

    def setUp(self):
        self.metadata = MetaData()
        self.engine = create_engine(DB_URI)
        self.connection = self.engine.connect()
        self.tr = self.connection.begin()
        register_type(self.engine)

    def tearDown(self):
        self.tr.rollback()

    def test_type(self):
        table = Table(
            'test_addr', self.metadata,
            Column('id', Integer, primary_key=True),
            Column('addr', PgAddressType),
        )
        table.drop(bind=self.engine, checkfirst=True)
        table.create(bind=self.engine)

        iq = table.insert().values(
            addr={
                'country': 'Germany',
                'region': 'Reg1',
                'city': 'Berlin',
                'street': 'Str1',
                'num': '44m,2',
                'zip_code': '13597'
            }
        )
        self.engine.execute(iq)

        sq = table.select()
        cur = self.engine.execute(sq)
        row = cur.fetchone()

        self.assertEqual(
            row['addr'],
            {
                'country': 'Germany',
                'region': 'Reg1',
                'city': 'Berlin',
                'street': 'Str1',
                'num': '44m,2',
                'zip_code': '13597'
            }
        )

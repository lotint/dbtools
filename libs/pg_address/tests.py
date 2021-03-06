
import os
import unittest

from sqlalchemy import (
    create_engine, MetaData, Table, Column, Integer, text, bindparam)

from pg_address import register_type, PgAddressType, PgAddressArrayType


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
        addr = {
            'country': 'Germany',
            'region': 'Reg1',
            'city': 'Berlin',
            'street': 'Str1',
            'num': '44m,2',
            'zip_code': '13597',
            'suburb': 'Sub',
            'lat': 52.13,
            'lon': 12.2,
        }
        table = Table(
            'test_addr', self.metadata,
            Column('id', Integer, primary_key=True),
            Column('addr', PgAddressType),
        )
        table.drop(bind=self.engine, checkfirst=True)
        table.create(bind=self.engine)

        iq = table.insert().values(addr=addr)
        self.engine.execute(iq)

        sq = table.select()
        cur = self.engine.execute(sq)
        row = cur.fetchone()

        self.assertEqual(row['addr'], addr)

    def test_type_with_none(self):
        table = Table(
            'test_addr', self.metadata,
            Column('id', Integer, primary_key=True),
            Column('addr', PgAddressType),
        )
        table.drop(bind=self.engine, checkfirst=True)
        table.create(bind=self.engine)

        iq = table.insert().values(addr=None)
        self.engine.execute(iq)

        sq = table.select()
        cur = self.engine.execute(sq)
        row = cur.fetchone()

        self.assertIsNone(row['addr'])

    def test_type_in_array(self):
        addrs = [{
            'country': 'Germany',
            'region': 'Reg1',
            'city': 'Berlin',
            'street': 'Str1',
            'num': '44m,2',
            'zip_code': '13597',
            'suburb': 'Sub',
            'lat': 52.13,
            'lon': 12.2,
        }]

        table = Table(
            'test_addrs', self.metadata,
            Column('id', Integer, primary_key=True),
            Column('addrs', PgAddressArrayType),
        )
        table.drop(bind=self.engine, checkfirst=True)
        table.create(bind=self.engine)

        iq = table.insert().values(addrs=addrs)
        self.engine.execute(iq)

        sq = table.select()
        cur = self.engine.execute(sq)
        row = cur.fetchone()
        self.assertEqual(row['addrs'], addrs)

    def test_type_in_array_with_none(self):
        table = Table(
            'test_addrs', self.metadata,
            Column('id', Integer, primary_key=True),
            Column('addrs', PgAddressArrayType),
        )
        table.drop(bind=self.engine, checkfirst=True)
        table.create(bind=self.engine)

        iq = table.insert().values(addrs=None)
        self.engine.execute(iq)

        sq = table.select()
        cur = self.engine.execute(sq)
        row = cur.fetchone()
        self.assertIsNone(row['addrs'])

    def test_raw_queries(self):
        addrs = [{
            'country': 'Germany',
            'region': 'Reg1',
            'city': 'Berlin',
            'street': 'Str1',
            'num': '44m,2',
            'zip_code': '13597',
            'suburb': 'Sub',
            'lat': 52.13,
            'lon': 12.2,
        }]
        table = Table(
            'test_addrs', self.metadata,
            Column('id', Integer, primary_key=True),
            Column('addrs', PgAddressArrayType),
        )
        table.drop(bind=self.engine, checkfirst=True)
        table.create(bind=self.engine)

        query = 'INSERT INTO test_addrs VALUES (:id, :addrs);'
        stmt = text(query).bindparams(
            bindparam('id', value=1, type_=Integer),
            bindparam('addrs', value=addrs, type_=PgAddressArrayType),
        )
        self.engine.execute(stmt)

        sq = table.select()
        cur = self.engine.execute(sq)
        row = cur.fetchone()
        self.assertEqual(row['addrs'], addrs)

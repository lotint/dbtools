
from setuptools import setup

setup(
    name='pg_address',
    version='0.0.4',
    description='SqlAlchemy type for pg_address postgres type',
    packages=['pg_address'],
    install_requires=[
        'psycopg2-binary>=2.7.5',
        'SQLAlchemy>=1.1.4',
    ],
)

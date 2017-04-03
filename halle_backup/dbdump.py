import psycopg2
import argparse

from datetime import datetime, timedelta


parser = argparse.ArgumentParser()
parser.add_argument('db', type=str)

args = parser.parse_args()
db = args.db


def get_table_p_name(table, date):
    if 'fast_' in table:
        return table + '_p_{}_{:0>2}'.format(
            date.year, date.strftime('%U'))
    else:
        return table + '_p_{}_{}'.format(
            date.year, (date.month - 1) // 3 + 1)


conn = psycopg2.connect(
    'postgresql://lot_export:Mi0gaoyM3o@localhost:5432/{}'.format(db))

cur = conn.cursor()

cur.execute("""
    SELECT relname
    FROM pg_stat_all_tables
    WHERE schemaname='public';
""")

table_to_backup = set()
partition_table = set()
partition_table_diff = set()
for table in cur.fetchall():
    if '_p_' in table[0]:
        partition_table.add(table[0])
        partition_table_diff.add(table[0].split('_p_')[0])
    else:
        table_to_backup.add(table[0])

table_to_backup = table_to_backup ^ partition_table_diff

cur_date = datetime.now()
cur_quarter = (cur_date.month - 1) // 3 + 1
quarter_first_day = datetime(cur_date.year, 3 * cur_quarter - 2, 1)

for table in partition_table_diff:
    part_table = get_table_p_name(table, cur_date)

    if part_table in partition_table:
        table_to_backup.add(part_table)

    part_table = None
    if 'fast_' in table and cur_date.weekday() == 0:
        part_table = get_table_p_name(
            table, cur_date.date() - timedelta(minutes=1))
    elif 'full_' in table and cur_date.date() == quarter_first_day:
        part_table = get_table_p_name(
            table, quarter_first_day - timedelta(minutes=1))
    if part_table in partition_table:
        table_to_backup.add(part_table)


print(' '.join(table_to_backup))

cur.close()
conn.close()


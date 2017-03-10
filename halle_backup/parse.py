import argparse

parser = argparse.ArgumentParser()
parser.add_argument('db', type=str)

args = parser.parse_args()
print(args.db)


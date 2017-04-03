import argparse
import yaml


def parse_args():
    parser = argparse.ArgumentParser(description='Parse config from yaml')
    subparsers = parser.add_subparsers()

    pars_portals = subparsers.add_parser('sections', help='Get list of sections')
    pars_portals.set_defaults(func=sections_list)

    pars_portals = subparsers.add_parser('get', help='Get section var')
    pars_portals.add_argument('section', type=str, help='Section name')
    pars_portals.add_argument('key', type=str, help='Key')
    pars_portals.set_defaults(func=section_var)

    parser.add_argument('filename', type=str, help='Config file')
    return parser.parse_args()


def read_yaml(filename):
    with open(filename) as fl:
        return yaml.load(fl)


def get_sections_list(filename):
    data = read_yaml(args.filename)
    return ' '.join(list(data.keys()))


def sections_list(args):
    printout(get_sections_list(args.filename))


def get_section_var(data, section, key):
    return data[section][key]


def section_var(args):
    data = read_yaml(args.filename)
    printout(get_section_var(data, args.section, args.key))


def printout(data):
    print(data)


if __name__ == '__main__':
    args = parse_args()
    args.func(args)


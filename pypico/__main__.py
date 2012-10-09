import pypico, sys
import argparse

parser = argparse.ArgumentParser(prog='pypico')
parser.add_argument('code_file',nargs=1,help='path to Python module which contains get_pico')
parser.add_argument('data_file',nargs=1,help='output data file')

parser.add_argument('--args',nargs='*',metavar='<args>',help='args to pass to get_pico(*args)')
parser.add_argument('--existing_pico',nargs=1,metavar='<data_file>',help='redo an existing data file')

if not sys.argv[1:]: parser.print_help()
else:
    args = vars(parser.parse_args())
    pypico.create_pico(args['code_file'][0],args['data_file'][0],args=args['args'] or [], existing_pico=args['existing_pico'][0])
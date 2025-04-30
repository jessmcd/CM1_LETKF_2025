#
# set a variable to tell plotting scripts how to use the files in this directory
#
# each set of shape files can have its own color, and linethickness.  

import os, sys

cwd = os.getcwd() + "/fsrc"

try:
    import fpython2
except:
    print("\n Cannot import fpython2, trying to compile....")
    ret = os.system("cd fsrc ; fcompile.py -f gnu ; cd ..")
    try:
        import fpython2
    except ImportError:
        sys.exit(-1)
  
try:
    import recursive2d
except:
    print("\n Cannot import recursive2d, compiling....")
    ret = os.system("cd fsrc ; fcompile_recurv.py ; cd ..")
    try:
        import recursive2d
    except ImportError:
        sys.exit(-1)
try:
    import cressman
except:
    print("\n Cannot import cressman, compiling....")
    ret = os.system("cd fsrc ; fcompile_cress.py ; cd ..")
    print("\n Cannot import cressman, compiling....")
    try:
        import cressman
    except ImportError:
        sys.exit(-1)
  

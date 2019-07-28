
import os
from distutils.core import setup, Extension

if "MODEL_DIR" not in os.environ:
    print( "set env variable MODEL_DIR as the model you want to run" )
    exit()
m_dir = os.environ["MODEL_DIR"]
c_files = ['pyvgg.c', 'tw_vgg10.c']
c_files += [ m_dir + "/" + f for f in os.listdir(m_dir) if f[-2:] == ".c" ]

module1 = Extension('pyvgg',
                    define_macros = [('PYTHON_MOD', '1'),
                                     ('D3_PREC', '6')],
                    include_dirs = [m_dir],
                    sources = c_files )

setup (name = 'pyvgg',
       version = '1.0',
       description = 'Python package for model in ' + m_dir,
       ext_modules = [module1])

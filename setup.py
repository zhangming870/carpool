from cx_Freeze import setup, Executable

# Dependencies are automatically detected, but it might need
# fine tuning.
build_options = {'packages': ['fuzzy', 'argparse'], 'excludes': [],'includes': []}

base = 'console'

executables = [
    Executable('PreProcessor.py', base=base)
]

setup(name='PreProcessor',
      version = '1.0',
      description = '',
      options = {'build_exe': build_options},
      executables = executables)
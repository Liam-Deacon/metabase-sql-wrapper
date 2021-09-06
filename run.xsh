#!/usr/bin/env python

import subprocess
import signal
import os

from pathlib import Path


class Process:
    """
    Process class catches the signals and wait for the process end or interrupt.
    """
    stop_now = False
    def __init__(self, cmd):
        for s in [signal.SIGINT, signal.SIGTERM]:
            signal.signal(s, self.proc_terminate)

        proc = subprocess.Popen(cmd, shell=True)
        self.proc = proc
        self.pid = proc.pid
        proc.wait()

    def proc_terminate(self, signum, frame):
        print(f'*** CATCH: signum={signum}, stopping the process...')
        self.proc.terminate()
        self.stop_now = True

if __name__ == '__main__':
    print('*** Metabase SQL wrapper')

    metabase_jar = '/app/metabase.jar'

    metabase_db_path = Path(os.environ.get('MB_DB_FILE', '/data/metabase'))

    if metabase_db_path.exists():
        print(f'*** Metabase DB path: {metabase_db_path}')
    else:
        metabase_db_path.parent.mkdir(exists_ok=True, parents=True)
        print(f'*** Metabase DB path created: {metabase_db_path}')

    metabase_db_file = metabase_db_path / metabase_db_path.name

    init_sql_file = Path(os.environ.get('MB_DB_INIT_SQL_FILE', 'db.h2'))

    if init_sql_file.exists():
        if metabase_db_path.exists():
            print(f'*** Database path {metabase_db_path} exists, SKIP creating database from {init_sql_file}')
        else:
            print(f'*** Create database {metabase_db_file} from {init_sql_file}')
            Process(f"java -cp {metabase_jar} org.h2.tools.RunScript -url jdbc:h2:{metabase_db_file} -script {init_sql_file}")
            print('*** Creating DONE')
    else:
        print(f'*** MB_DB_INIT_SQL_FILE {init_sql_file} not found, SKIP')

    p = Process('/app/run_metabase.sh')

    save_sql_file = os.environ.get('MB_DB_SAVE_TO_SQL_FILE')
    if save_sql_file:
        print(f'*** Saving database {metabase_db_file} to {save_sql_file}')
        Process(f"java -cp {metabase_jar} org.h2.tools.Script -url jdbc:h2:{metabase_db_file} -script {save_sql_file}")
        print('*** Saving DONE')

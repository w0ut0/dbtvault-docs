from distutils import dir_util
from pathlib import Path

from invoke import task, Context


def reset_and_copy(src_dir, tgt_dir):
    if Path(tgt_dir).exists():
        dir_util.remove_tree(tgt_dir)

    dir_util.copy_tree(src_dir, tgt_dir)


def trim_sql_files_in_path(tgt_dir: Path):
    for path in Path(tgt_dir).rglob('*.sql'):
        with open(path, "r") as f:
            lines = f.readlines()

        delete_linebreak = True

        with open(path, 'w') as f:
            for line in lines:
                if "-- Generated by dbtvault." not in line and not line.isspace():
                    f.write(line)
                elif delete_linebreak and line.isspace():
                    pass
                elif "-- Generated by dbtvault." in line:
                    pass
                else:
                    f.write(line)
                    delete_linebreak = False


@task
def dbt_run_twice(c, target='snowflake'):
    with c.cd('./docs_snippets'):
        c.run('dbt clean')
        c.run(f'dbt build --target={target} --full-refresh')
        c.run(f'dbt build --target={target}')


@task
def copy_samples(c):
    targets = ['snowflake', 'bigquery', 'sqlserver']

    for target in targets:
        print(f"Running dbt with {target}...")

        dbt_run_twice(c, target=target)

        tgt_compiled = f'./docs/assets/snippets/compiled/{target}'
        tgt_models = f'./docs/assets/snippets/models/{target}'

        reset_and_copy('./docs_snippets/target/compiled/docs_snippets/models/',
                       tgt_compiled)

        reset_and_copy('./docs_snippets/models/',
                       tgt_models)

        trim_sql_files_in_path(tgt_compiled)
        trim_sql_files_in_path(tgt_models)


if __name__ == '__main__':
    copy_samples(Context())

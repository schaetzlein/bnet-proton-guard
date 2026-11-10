# Contributing

Thanks for helping to keep Battle.net running on Linux!

## Reporting problems

Open an issue with the bug report template. The output of `bnet-proton-guard --check`
and an excerpt from a `PROTON_LOG=1` run help the most. Please remove personal data
(user names in paths, account names) before posting.

## Development

You need `bash`, [ShellCheck](https://www.shellcheck.net/) and [bats-core](https://github.com/bats-core/bats-core).

```sh
make lint   # shellcheck
make test   # bats tests in tests/
```

The tests build a fake Steam library, Battle.net prefix and Proton builds in a temporary
directory, so they never touch your real Steam installation. Please keep it that way:
new tests must only work below `$BATS_TEST_TMPDIR`.

## Pull requests

- Keep changes focused; one topic per pull request.
- Add or update tests for changed behaviour.
- Code, comments, docs and commit messages are in English.
- Add an entry to the `Unreleased` section of `CHANGELOG.md` if users notice the change.

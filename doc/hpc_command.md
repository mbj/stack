<div class="hidden-warning"><a href="https://docs.haskellstack.org/"><img src="https://cdn.jsdelivr.net/gh/commercialhaskell/stack/doc/img/hidden-warning.svg"></a></div>

# The `stack hpc` commands

~~~text
stack hpc COMMAND

Available commands:
  report                   Generate unified HPC coverage report from tix files
                           and project targets
~~~

Code coverage is a measure of the degree to which the source code of a program
is executed when a test suite is run.
[Haskell Program Coverage (HPC)](https://ku-fpg.github.io/software/hpc/) is a
code coverage tool for Haskell that is provided with GHC. Code coverage is
enabled by passing the `--coverage` flag to `stack build`.

The following refers to the local HPC root directory. Its location can be
obtained by command:

~~~text
stack path --local-hpc-root
~~~

## Usage

`stack test --coverage` is quite streamlined for the following use-case:

1.  You have test suites which exercise your local packages.

2.  These test suites link against your library, rather than building the
    library directly. Coverage information is only given for libraries, ignoring
    the modules which get compiled directly into your executable. A common case
    where this doesn't happen is when your test suite and library both have
    something like `hs-source-dirs: src/`. In this case, when building your test
    suite you may also be compiling your library, instead of just linking
    against it.

When your project has these properties, you will get the following:

1.  Textual coverage reports in the build output.

2.  A unified textual and HTML report, considering the coverage on all local
    libraries, based on all of the tests that were run.

3.  An index of all generated HTML reports, in `index.html` in the local
    HPC root directory.

## The `stack hpc report` command

The `stack hpc report` command generates a report for a selection of targets and
`.tix` files. For example, if we have three different packages with test suites,
packages `A`, `B`, and `C`, the default unified report will have coverage from
all three. If we want a unified report with just two, we can instead command:

~~~text
stack hpc report A B
~~~

This will output a textual report for the combined coverage from `A` and `B`'s
test suites, along with a path to the HTML for the report.  To further
streamline this process, you can pass the `--open` option, to open the report in
your browser.

This command also supports taking extra `.tix` files.  If you've also built an
executable, against exactly the same library versions of `A`, `B`, and `C`, then
you could command the following:

~~~text
stack exec -- an-exe
stack hpc report A B C an-exe.tix
~~~

This report will consider all test results as well as the newly generated
`an-exe.tix` file.  Since this is a common use-case, there is a convenient flag
to use all stored results - `stack hpc report --all an-exe.tix`.

## The `extra-tix-files` directory

During the execution of the build, you can place additional tix files in the
`extra-tix-files` subdirectory in the local HPC root directory, in order for
them to be included in the unified report. A couple caveats:

1.  These tix files must be generated by executables that are built against the
    exact same library versions. Also note that, on subsequent builds with
    coverage, the local HPC root directory will be recursively deleted. It
    just stores the most recent coverage data.

2.  These tix files will not be considered by `stack hpc report` unless listed
    explicitly by file name.

## Implementation details

Most users can get away with just understanding the above documentation.
However, advanced users may want to understand exactly how `--coverage` works:

1. The GHC option `-fhpc` gets passed to all local packages.  This tells GHC to
   output executables that track coverage information and output them to `.tix`
   files. `the-exe-name.tix` files will get written to the working directory of
   the executable.

   When switching on this flag, it will usually cause all local packages to be
   rebuilt (see issue
   [#1940](https://github.com/commercialhaskell/stack/issues/1940)).

2. Before the build runs with `--coverage`, the contents of the local HPC root
   directory gets deleted. This prevents old reports from getting mixed
   with new reports. If you want to preserve report information from multiple
   runs, copy the contents of this path to a new directory.

3. Before a test run, if a `test-name.tix` file exists in the package directory,
   it will be deleted.

4. After a test run, it will expect a `test-name.tix` file to exist. This file
   will then get loaded, modified, and outputted to
   `pkg-name/test-name/test-name.tix` in the local HPC root directory.

   The `.tix` file gets modified to remove coverage file that isn't associated
   with a library. So, this means that you won't get coverage information for
   the modules compiled in the `executable` or `test-suite` stanza of your Cabal
   file. This makes it possible to directly union multiple `*.tix` files from
   different executables (assuming they are using the exact same versions of the
   local packages).

   If there is enough popular demand, it may be possible in the future to give
   coverage information for modules that are compiled directly into the
   executable. See issue
   [#1359](https://github.com/commercialhaskell/stack/issues/1359).

5. Once we have a `.tix` file for a test, we also generate a textual and HTML
   report for it. The textual report is sent to the terminal. The index of the
   test-specific HTML report is available `pkg-name/test-name/index.html` in the
   local HPC root directory.

6. After the build completes, if there are multiple output `*.tix` files, they
   get combined into a unified report. The index of this report will be
   available at `combined/all/index.html` in the local HPC root directory.

7. Finally, an index of the resulting coverage reports is generated. It links to
   the individual coverage reports (one for each test-suite), as well as the
   unified report. This index is available at `index.html` in the local HPC root
   directory.
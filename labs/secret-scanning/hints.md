# Lab Hints

Start by putting the key in the repository. Creating a new file in the
`sirli-depo` folder is enough — you do not need to commit, because the `dir`
command looks at what is on disk.

Once the key is there, run a scan. Finding nothing is expected: gitleaks does
not know the `SPS-` format. That "clean" result is the starting point of the
exercise.

Your own rule goes into a `.gitleaks.toml` file at the root of the repository.
If gitleaks sees a file by that name in the folder it is scanning, it uses it
automatically — you do not have to pass a flag.

A rule needs at least three fields: an `id`, a `description` and a `regex`
describing the key. Rules are written under a `[[rules]]` heading — double
square brackets, because there can be more than one.

If you write the regular expression between `'''` triple quotes you avoid
having to escape backslashes.

Finally, check this: after adding your own rule, is the GitHub token in the
repository still being found? If it is not, your configuration file has
disabled the default rules — look at the `[extend]` section.

> Need more? The [solution](solution.md) is here.

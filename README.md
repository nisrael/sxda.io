# sxda.io

Personal reference blog, built with [Zola](https://www.getzola.org/).

## Usage

```shell
zola serve   # live preview at http://127.0.0.1:1111
zola build   # build to public/
zola check   # validate internal/external links
```

Search (via [Pagefind](https://pagefind.app/)) is built from the `public/` output, not from `zola serve`, so the search box won't return results during `zola serve` until you've run this at least once:

```shell
zola build && pagefind --site public
```

To quickly add a new post:

```shell
scripts/new-post.sh
```

To edit from the web without a local checkout, use GitHub's web editor (press `.` on this repo, or go to [github.dev/nisrael/sxda.io](https://github.dev/nisrael/sxda.io)) and open a pull request — the `pages-deploy` workflow builds and checks every PR, and deploys on merge to `main`.

Comments on posts are powered by [giscus](https://giscus.app/), backed by this repo's GitHub Discussions.

Dark mode uses [Carbonfox](https://github.com/EdenEast/nightfox.nvim) colors; code block highlighting in dark mode uses `extra/carbonfox-dark-theme.json`, vendored (MIT) from [keifererikson/vscode-nightfox](https://github.com/keifererikson/vscode-nightfox). Light mode uses IBM Carbon's "White" theme tokens and the `github-light` highlighting theme.

## License

The site's code (templates, CSS, JavaScript, build config) is published under the [MIT](LICENSE) License. The written content (the posts and the about page) is published under [CC BY 4.0](LICENSE-CONTENT).

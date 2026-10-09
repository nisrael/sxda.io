# sxda.io

Personal reference blog, built with [Zola](https://www.getzola.org/).

## Usage

```shell
zola serve   # live preview at http://127.0.0.1:1111
zola build   # build to public/
zola check   # validate internal/external links
```

To quickly add a new post:

```shell
scripts/new-post.sh
```

To edit from the web without a local checkout, use GitHub's web editor (press `.` on this repo, or go to [github.dev/nisrael/sxda.io](https://github.dev/nisrael/sxda.io)) and open a pull request — the `pages-deploy` workflow builds and checks every PR, and deploys on merge to `main`.

Comments on posts are powered by [giscus](https://giscus.app/), backed by this repo's GitHub Discussions.

## License

This work is published under the [MIT](LICENSE) License.

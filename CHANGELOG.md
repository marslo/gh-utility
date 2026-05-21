## [1.2.0](https://github.com/marslo/gh-utility/compare/v1.1.0...v1.2.0) (2026-05-21)

### feat

* feat(fzf-preview): use percentage-based dynamic preview window re-sizing; update pre-commit workflow to distinguish between push and pull_request events

### chore

* chore: update the prompt format

### ci

* ci: fix the 'Node.js 20 actions are deprecated' issue in pre-commit workflow

## [1.1.0](https://github.com/marslo/gh-utility/compare/v1.0.0...v1.1.0) (2026-05-19)

### CI/CD

* ci: disable precommit automatic upgrade via PR
  Signed-off-by: marslo <marslo.jiao@gmail.com>
* ci(workflow): using pre-commit workflow instead of pre-commit application, to disable PR auto creation
  Signed-off-by: marslo <marslo.jiao@gmail.com>

### Code Refactoring

* refactor: refactor gh-preview to reduce redundancy
  Signed-off-by: marslo <marslo.jiao@gmail.com>

### Features

* feat(issue): add issue list and preview
  Signed-off-by: marslo <marslo.jiao@gmail.com>

## 1.0.0 (2026-05-07)

### Features

* **bash_completion:** merge gh-new and gh-ops bash_completion into one, to avoid `__start_gh` mutual exclusion ([b39897b](https://github.com/marslo/gh-utility/commit/b39897b4c63762d7a1e99879817a909a302437f2))
* **init:** add the utility/libs script and tools for gh-ops and gh-new; it will be the submoudle of those extensions ([1f3d763](https://github.com/marslo/gh-utility/commit/1f3d763aa5d57ddef705f3fe1dda6b6187bab80e))

### Others

* enable automatic completion after `--` ([b99f4be](https://github.com/marslo/gh-utility/commit/b99f4be85fc6c60ff524b6c35dede3bcc8a38a44))
* enhance automatic completion after `--` for `gh new` ([e0aec1d](https://github.com/marslo/gh-utility/commit/e0aec1d1e962c5bd19fb193cc1ba660f927c1759))

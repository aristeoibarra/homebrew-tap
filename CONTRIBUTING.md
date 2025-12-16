# Contributing

Guide for adding new formulas to this tap.

## Adding a New PyPI Formula

### 1. Generate the Formula

For Python packages on PyPI, use `homebrew-pypi-poet` to generate dependencies:

```bash
pip install homebrew-pypi-poet
poet <package-name>
```

Or manually download and hash:

```bash
# Download the package
pip download --no-binary :all: --no-deps -d /tmp/deps <package-name>

# Get SHA256
shasum -a 256 /tmp/deps/<package-name>-*.tar.gz
```

### 2. Create the Formula File

Create `Formula/<package-name>.rb`:

```ruby
# typed: false
# frozen_string_literal: true

class PackageName < Formula
  include Language::Python::Virtualenv

  desc "Short description of the package"
  homepage "https://github.com/user/repo"
  url "https://files.pythonhosted.org/packages/source/p/package-name/package_name-1.0.0.tar.gz"
  sha256 "sha256hash"
  license "MIT"
  head "https://github.com/user/repo.git", branch: "main"

  depends_on "python@3.12"

  # Add resources for each dependency
  resource "dependency-name" do
    url "https://files.pythonhosted.org/packages/source/d/dependency/dependency-1.0.0.tar.gz"
    sha256 "sha256hash"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/package-name --version")
  end
end
```

### 3. Test Locally

```bash
# Install from source
brew install --build-from-source Formula/<package-name>.rb

# Verify it works
<package-name> --version

# Run audit
brew audit --strict Formula/<package-name>.rb
```

### 4. Set Up Automatic Updates (Optional)

To automatically update the formula when a new version is released:

#### In the source repository:

Add to your release workflow:

```yaml
- name: Trigger Homebrew tap update
  uses: peter-evans/repository-dispatch@v3
  with:
    token: ${{ secrets.TAP_REPO_TOKEN }}
    repository: aristeoibarra/homebrew-tap
    event-type: update-<package-name>
    client-payload: '{"version": "${{ github.ref_name }}"}'
```

#### In this repository:

Add a new workflow trigger in `.github/workflows/update-formula.yml`:

```yaml
on:
  repository_dispatch:
    types: [new-release, update-<package-name>]
```

And add a case in the workflow to handle the new formula.

### 5. Update README

Add your formula to the table in README.md:

```markdown
| [package-name](https://github.com/user/repo) | Description | `brew install package-name` |
```

## Formula Naming Conventions

- Use lowercase with hyphens: `my-package`
- Match the PyPI/GitHub name when possible
- Avoid prefixes like `python-` (Homebrew convention)

## Testing Changes

Before pushing:

```bash
# Audit the formula
brew audit --strict Formula/<package-name>.rb

# Test installation
brew install --build-from-source Formula/<package-name>.rb

# Run formula tests
brew test <package-name>
```

## Directory Structure

```
homebrew-tap/
├── Formula/
│   ├── nextdns-blocker.rb
│   └── <new-formula>.rb
├── scripts/
│   └── update-pypi-formula.sh
├── .github/
│   └── workflows/
│       └── update-formula.yml
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

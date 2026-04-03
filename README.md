# LATdx CLI

**Speed up your Salesforce Apex tests, 2x to 20x faster.**

LATdx delivers near real-time feedback so you can stay in your flow and ship confidently, without waiting on slow test cycles.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Nebulity/latdx-cli/main/install.sh | bash
```

Install a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/Nebulity/latdx-cli/main/install.sh | bash -s -- 0.15.2
```

Custom install directory:

```bash
LATDX_INSTALL_DIR=/usr/local/bin curl -fsSL https://raw.githubusercontent.com/Nebulity/latdx-cli/main/install.sh | bash
```

### Platforms

| Platform | Asset |
|----------|-------|
| macOS Apple Silicon | `latdx-darwin-arm64` |
| macOS Intel | `latdx-darwin-x64` |
| Linux x64 | `latdx-linux-x64` |
| Linux ARM64 | `latdx-linux-arm64` |
| Windows x64 | `latdx-win-x64.exe` |

### Manual download

Download binaries directly from the [Releases](https://github.com/Nebulity/latdx-cli/releases) page.

### Verify downloads

Each release includes `SHA256SUMS` and a `SHA256SUMS.minisig` signature. To verify:

```bash
# SHA256 checksum
shasum -a 256 -c SHA256SUMS

# Minisign signature (if minisign is installed)
minisign -Vm SHA256SUMS -p minisign.pub
```

## Quick start

```bash
# Run tests for a specific class
latdx test run -n MyApexTest -o my-org

# Run tests from local files
latdx test run --file src/classes/MyApexTest.cls -o my-org

# See all options
latdx --help
```

## Documentation

Visit [latdx.com](https://latdx.com) for full documentation.

## Issues

Found a bug or have a feature request? [Open an issue](https://github.com/Nebulity/latdx-cli/issues/new/choose).

## License

LATdx is proprietary software. See [LICENSE](LICENSE) for details.

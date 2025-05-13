# ShareLaTeX Docker Setup

This repository contains a Dockerfile for setting up a ShareLaTeX environment with a full TeX Live installation and additional tools like Inkscape.

## Features

- **Base Image**: Uses the official `sharelatex/sharelatex` image.
- **TeX Live**: Installs the full TeX Live distribution (`scheme-full`) for comprehensive LaTeX support.
- **Inkscape**: Adds Inkscape for handling SVG graphics.
- **Shell Escape**: Enables shell-escape by default for LaTeX documents requiring it.

## Prerequisites

- Internet connection to download required packages.
- WSL installed on your system. ([Install](https://learn.microsoft.com/de-de/windows/wsl/install))
- Docker installed on your system. ([Install](https://docs.docker.com/engine/install/ubuntu/))

## Build from Source

1. Clone this repository:
    ```bash
    git clone https://git.serv.eserver.icu/ewbc/sharelatexfull.git
    cd sharelatexfull
    ```

2. Build the Docker image:
    ```bash
    docker build -t sharelatexfull .
    ```

## Adding this repository to your Overleaf Toolkit

### Manual Installation

1. Follow the steps from the [Overleaf Quickstart Guide](https://github.com/overleaf/toolkit/blob/master/doc/quick-start-guide.md)

2. Before running `bin/up` go to `config/overleaf.rc` and make the following changes:
    ```bash
    OVERLEAF_IMAGE_NAME=sharelatex/sharelatex
    ```
    to
    ```bash
    OVERLEAF_IMAGE_NAME=git.serv.eserver.icu/ewbc/sharelatexfull
    ```

3. After you made the changes you can now start Overleaf using `bin/up` (Use `bin/up -d` for detaching the output)

4. Go to http://127.0.0.1/launchpad on first run

### Automatic Installation [experimental]

```bash
curl -sSL https://git.serv.eserver.icu/ewbc/sharelatexfull/raw/branch/main/scripts/overleaf_automated_install.sh | bash
```
After the Installation you may launch `overleaf_manager_script.sh` or open the the Overleaf Manager Shortcut in Windows Start 

## Customization

- **TeX Live Updates**: The Dockerfile updates TeX Live to the latest version during the build process.
- **Additional Packages**: Modify the `tlmgr install` command in the Dockerfile to include any additional LaTeX packages you need.

## Notes

- The `update-tlmgr-latest.sh` script is used to ensure the latest version of `tlmgr` is installed.
- The `texmf.cnf` file is updated to enable shell-escape by default.

## Troubleshooting

- If you encounter issues with missing LaTeX packages, ensure that the `scheme-full` installation was successful.
- For any other issues, check the container logs:
  ```bash
  docker logs sharelatex
  ```

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

- [ShareLaTeX](https://github.com/sharelatex/sharelatex) for the base Docker image.
- [CTAN](https://ctan.org/) for TeX Live resources.

ARG SHARELATEX_VERSION=latest
FROM sharelatex/sharelatex:${SHARELATEX_VERSION}

RUN wget "https://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh" \
    && sh update-tlmgr-latest.sh \
    && tlmgr --version

RUN tlmgr update texlive-scripts

RUN tlmgr update --all

RUN tlmgr install scheme-full

RUN tlmgr path add

RUN apt-get update && apt-get upgrade -y \
    && apt-get install inkscape -y

RUN TEXLIVE_FOLDER=$(find /usr/local/texlive/ -type d -name '20*') \
    && echo % enable shell-escape by default >> /$TEXLIVE_FOLDER/texmf.cnf \
    && echo shell_escape = t >> /$TEXLIVE_FOLDER/texmf.cnf
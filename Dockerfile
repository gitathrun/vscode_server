# For c++/java programming
# With Code-Server
# 0.3 with c++
# 0.4 with c++, cmake, java extension pack, mainly for JNI programming

FROM ubuntu:16.04

# the maintainer information
LABEL maintainer "Teng Fu <teng.fu@teleware.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libcurl3-dev \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python-dev \
        rsync \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev \
        wget \
        curl \
        git \
        && \
    rm -rf /var/lib/apt/lists/* 


# for NodeJS installation
# Node SDK
RUN curl -sL https://deb.nodesource.com/setup_11.x | bash -
RUN apt-get update && apt-get install --no-install-recommends -y \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# for code-server installation
# Packages

# -------------------------------------------
# Anaconda installation
# https://github.com/ContinuumIO/docker-images/blob/master/anaconda/Dockerfile
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion

# download and install the anaconda
# anaconda 2 is python 2.7
# anaconda 3 is python 3.6 (after 4.2.0 is python 3.6, below is python3.5)
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-5.2.0-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc


# part of the tensorflow dockder file for tensorflow build
# line 53-67
RUN pip --no-cache-dir install \
        keras_applications\
        keras_preprocessing\
        mock \
        && \
    python -m ipykernel.kernelspec


# -- setup bazel and download tf 1.13 ----
#--------------custom tensorflow build/install-------------------------
# Set up Bazel.

# Running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# The easiest solution is to set up a bazelrc file forcing --batch.
RUN echo "startup --batch" >>/etc/bazel.bazelrc
# Similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
    >>/etc/bazel.bazelrc
# Install the most recent bazel release.
ENV BAZEL_VERSION 0.20.0
WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Download and build TensorFlow.
# check the branch, here it is 1.13
RUN git clone --branch=r1.13 --depth=1 https://github.com/tensorflow/tensorflow.git
WORKDIR /tensorflow

# -- setup bazel and download tf 1.13 ----


# must be after env installatin
# Code-Server
RUN apt-get update && apt-get install --no-install-recommends -y \
    bsdtar \
    openssl \
    locales \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

ENV CODE_VERSION="1.696-vsc1.33.0"
RUN curl -sL https://github.com/codercom/code-server/releases/download/${CODE_VERSION}/code-server${CODE_VERSION}-linux-x64.tar.gz | tar --strip-components=1 -zx -C /usr/local/bin code-server${CODE_VERSION}-linux-x64/code-server

# setup extension path
# for Linux:
# Linux $HOME/.vscode/extensions
# here $HOME = "/root"

ENV VSCODE_EXTENSIONS "/root/.vscode/extensions"

# download c++ extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/cpptools \
    && curl -JLs --retry 5 https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode/vsextensions/cpptools/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/cpptools extension

# add in 0.4 jdk and jre
RUN apt-get update && apt-get install --no-install-recommends -y \
    default-jdk \
    default-jre

# add in 0.4 download java extension pack extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/vscode-java-pack \
    && curl -JLs --retry 5 https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscjava/vsextensions/vscode-java-pack/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/vscode-java-pack extension
# add in 0.4 cmake installation
RUN pip --no-cache-dir install cmake

# Set up our notebook config.
COPY jupyter_notebook_config.py /root/.jupyter/

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
COPY run_jupyter.sh /
RUN chmod +x /run_jupyter.sh

# the default volume shared with host machine directory
# in the docker run 
# use docker run -v <absolute path of local folder>:/app
RUN mkdir /app

# workspace directory
WORKDIR /app

# Jupyter Notebook
EXPOSE 6006

# Code-Server
EXPOSE 8888

# this code-server with no password access, if you wish to have the password access
# please change this CMD according to "code-server --help"
CMD ["code-server", "-N", "-p", "8888", "-e", "/root/.vscode/extensions"]

# automatic run this bash file 
# because it is currently installed with anaconda, so must specified the bash's path
# CMD [ "/bin/bash", "/run_jupyter.sh", "--allow-root"]
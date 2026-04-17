FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

# Update and install base packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      cmake \
      gdb \
      build-essential \
      libopencv-dev \
      libzmq3-dev \
      libpoco-dev \
      libfmt-dev \
      libsdbus-c++2 \
      libsdbus-c++-dev \
      pkg-config \
      libusb-1.0-0-dev \
      curl \
      git \
      openssh-client \
      wget \
      ca-certificates \
      gnupg \
      lsb-release \
      lintian \
      unzip \
 && rm -rf /var/lib/apt/lists/*

# Install .NET 10 SDK
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
 && chmod +x dotnet-install.sh \
 && ./dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet \
 && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
 && rm dotnet-install.sh

# Install Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
 && apt-get install -y nodejs \
 && rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash \
 && mv /root/.bun/bin/bun /usr/local/bin/ \
 && chmod +x /usr/local/bin/bun

# Clean up to reduce image size
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/locale/* \
 && apt-get clean

# Set PATH for .NET
ENV PATH="${PATH}:/usr/share/dotnet"
ENV DOTNET_ROOT="/usr/share/dotnet"

# Verify installations
RUN dotnet --version \
 && node --version \
 && bun --version \
 && pkg-config --modversion sdbus-c++

WORKDIR /workspace

CMD ["/bin/bash"]

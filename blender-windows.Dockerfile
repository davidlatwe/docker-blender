# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019

ARG VERSION=3.4
ARG BRANCH=blender-v3.4-release
ARG PYVER=3.10.8
ARG VSYEAR=2019

SHELL ["cmd", "/S", "/C"]


# Install Build Tools (Desktop development with C++)
#
COPY vs_collect.cmd C:/
ADD https://aka.ms/vscollect.exe                    vs_collect.exe
ADD https://aka.ms/vs/16/release/vs_buildtools.exe  vs_buildtools.exe
ADD https://aka.ms/vs/16/release/channel            vs_channel.chman

RUN call vs_collect.cmd vs_buildtools.exe --quiet --wait --norestart --nocache install `
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\%VSYEAR%\BuildTools" `
        --channelUri        C:\vs_channel.chman `
        --installChannelUri C:\vs_channel.chman `
        --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
        --remove Microsoft.VisualStudio.Component.Windows81SDK
# Cleanup
RUN del /q vs_collect.exe vs_buildtools.exe vs_channel.chman


# Install nuget, chocolatey
#
ADD https://aka.ms/nugetclidl  nuget.exe
RUN @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command `
    "[System.Net.ServicePointManager]::SecurityProtocol = 3072; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" `
    && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

# Install Git, SlikSVN, Python
#
RUN choco install -y git.install --params "'/GitAndUnixToolsOnPath'"
RUN choco install -y sliksvn --package-parameters="/AddToPath"
RUN nuget.exe install python -ExcludeVersion -Version %PYVER% -OutputDirectory . `
    && setx /M PATH "%PATH%;C:\python\tools;C:\python\tools\Scripts"


# Git clone Blender source
#
RUN mkdir blender-build `
    && cd blender-build `
    && git clone --depth 1 --branch %BRANCH% https://github.com/blender/blender.git `
    && cd blender `
    && git submodule update --init

# Apply patch
#
COPY blender-windows.patch C:/
ENV BLENDER_VERSION $VERSION
RUN cd blender-build/blender `
    && git apply C:/blender-windows.patch

# Download libraries. NOTE: "svn: E175012: Connection timed out" may happen.
#
RUN cd blender-build/blender `
    && echo y| make.bat 2019b update


WORKDIR blender-build/blender
# Starts the developer command prompt CMD shell.
ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat", "&&", "cmd.exe"]

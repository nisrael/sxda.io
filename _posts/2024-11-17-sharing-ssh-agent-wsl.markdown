---
layout: post
title:  "Sharing the ssh agent between Windows and WSL"
date:   2024-11-17 18:01:00 +0100
categories: tooling
tags: ssh gpg wsl article
---

## tl;dr

To use the same SSH keys in Windows and WSL2 without storing the keys unencrypted on disk:

* use SSH in Windows Terminal[^28]
* don't use the ssh agent, that is installed as a service (`Set-Service -Name ssh-agent -StartupType Disabled`)
* use a password manager, that provides a ssh-agent service ([KeePass with KeeAgent](#keepass-with-keeagent) as a free and customizable solution or [1Password](#1password) for convenience)
* in WSL2, use `ssh.exe` instead of `ssh`

> ssh.exe works fine, but I feel weird about calling the Windows exe from within WSL. Instead, I could use the "obvious" solution of using systemd to provide a socket and let it do the "dirty" work of calling a windows binary. In this case a binary that pipes the data from the socket to a service running on Windows. [See below for my preferred solution](#my-preferred-solution).
>
> My preferred solution is not the "best" solution. Instead of using 1Password (for convenience) it is also possible to use a much more secure solution and create the ssh key on an air gapped PC, store it on a YubiKey (better 2!) and use the described [GPG4Win](#gpg4win) and [WSL2](#wsl2-with-gpg-agent) setup.
>
{: .prompt-tip }

[^28]: https://learn.microsoft.com/en-us/windows/terminal/tutorials/ssh

## Introduction

Until several years ago, when working on your windows desktop and wanting to remote to your linux machines, PuTTY together with its companion Pageant was the tool of choice. Before opening the first ssh session you could load your encrypted ssh key into pageant, enter the key's password and use it for key based authentication during your Windows session. For me, PuTTY was one of the first things to install after setting up a new Windows machine.

Then Microsoft included Win32 OpenSSH in Windows 10 1803 in 2019 and released Windows Terminal in 2020. I don't think that I replaced PuTTY right away but since some years I can't think of a better way to use ssh on a Windows machine. Of course, I am using WSL2 in Windows Terminal, too. But everytime I wanted to use ssh there, I was reminded that I had to set up the openssh key first. That's not a big deal, you just have to copy the key file from your Windows `$USERPROFILE/.ssh` directory to your WSL2 distributions `~/.ssh` directory. That always brought to my attention that I, being lazy, placed an unencrypted key file there because I didn't want to enter the password for every connection again and I could not remember the syntax of adding the key to the ssh agent. Shame on me! Don't ever do that! All of that is not really a problem, and it is possible to set it up correctly, here and there but it is not very convenient.

Obviously, I am not alone with this "problem" and some smart people found solutions for this. I remembered reading in a comment somewhere that WSL2 would support systemd and that that would lead to an easier solution. Problem: I couldn't remember where it was and at first I was not able to find the comment again. It turns out, that was because the comment wasn't about an ssh agent but about a gist with a script setting a some tools to use the Windows gpg agent in WSL2. Because it was so hard to find this comment and I really liked the solution the author figured out, I decided to write an article about it and show how use it not only for the gpg agent, but for some ssh agents as well. But first, I would like to understand why it is not working right out of the box.

## SSH clients and agents

### Win32 OpenSSH

According to the wiki "ssh-agent will be reimplemented for Windows as a Windows service, running as LocalSystem".[^1]

It uses the named pipe `#define AGENT_PIPE_ID L"\\\\.\\pipe\\openssh-ssh-agent"`.[^2]

> **Supported options**
> * Windows named pipe: `\\.\pipe\openssh-ssh-agent`
    {: .prompt-info }

[^1]: https://github.com/PowerShell/Win32-OpenSSH/wiki/About-Win32-OpenSSH-and-Design-Details#security-model-in-windows

[^2]: https://github.com/PowerShell/openssh-portable/blob/5622b51825b997bc5a958923f837bd1442fa05d0/contrib/win32/win32compat/ssh-agent/agent.c#L48

### PuTTY, Pageant and Plink

From the PuTTY manual, we know that "Windows's own port of OpenSSH uses the same mechanism as Pageant to talk to its SSH agent (Windows named pipes). This means that Windows OpenSSH can talk directly to Pageant, if it knows where to find Pageant's named pipe."[^3] The name is generated randomly every time pageant is started. But there is a command line option for Pageant to let it create a file with the generated name in it, which can be included in the Win32 Open SSH configuration file.

Start Pageant with:

```shell
pageant --openssh-config %USERPROFILE%\.ssh\pageant.conf
```

And put the include statement in `%USERPROFILE%\.ssh\config`:
```
[...]
Include pageant.conf
[...]
```

According to the PuTTY manual[^4], Pageant also supports Unix-domain sockets (AF_UNIX), which are supported in Windows since 1803[^5], by starting it with:

```shell
pageant --unix %USERPROFILE%\.ssh\agent.sock
```

If I understand it correctly, then PuTTY, Pageant and Plink nowadays use named pipes for IPC, but still support the formerly used method of `WM_COPYDATA` (explanation[^10]), to not break compatibility with older and third party clients.[^11]

[^10]: https://labs.withsecure.com/publications/abusing-putty-and-pageant-through-native-functionality
[^11]: https://git.tartarus.org/?p=simon/putty.git;a=commit;h=cf29125fb464169d1bab88a0bc9c18a4ca5a983a

> **Supported options**
> * Windows named pipe, generated randomly and exported in `%USERPROFILE%\.ssh\pageant.conf`
> * Unix-domain socket (AF_UNIX): `%USERPROFILE%\.ssh\agent.sock`
> * WM_COPYDATA
    {: .prompt-info }

> AF_UNIX sockets are only protected against access by Windows filesystem security.
{: .prompt-warning }

[^3]: https://the.earth.li/~sgtatham/putty/0.80/htmldoc/Chapter9.html#pageant-cmdline-openssh
[^4]: https://the.earth.li/~sgtatham/putty/0.80/htmldoc/Chapter9.html#pageant-cmdline-unix
[^5]: https://devblogs.microsoft.com/commandline/af_unix-comes-to-windows/

### Cygwin/MSYS OpenSSH

A MSYS/Cygwin version of OpenSSH is installed, e.g. by Git for Windows. Both Cygwin and MSYS don't support real Unix-domain sockets, instead they emulate a socket by opening a TCP port on the loopback interface and writing the port number and a secret to a file, only with a slight difference, the character 's' between the port and the secret:[^6]

Cygwin:
```
!<socket >59108 s 282F93E1-9E2D051A-46B57EFC-64A1852F
```

MSYS:
```
!<socket >59108 282F93E1-9E2D051A-46B57EFC-64A1852F
```

The installation of Git for Windows also installs a tool called ssh-pageant, which "is a tiny tool for Windows that allows you to use SSH keys from PuTTY's Pageant in Cygwin and MSYS shell environments."[^7]

> **Supported options**
> * Cygwin/MSYS socket emulation
> * Pageant named pipe with ssh-pageant
    {: .prompt-info }

[^6]: https://stackoverflow.com/questions/23086038/what-mechanism-is-used-by-msys-cygwin-to-emulate-unix-domain-sockets
[^7]: https://github.com/cuviper/ssh-pageant

### Gpg4Win

It may seem odd, to include Gpg4Win here, being gpg and obviously not ssh. But both use public key cryptography, and it turns out, that a gpg subkey marked with the authenticate capability can be used as a ssh key.
In the gnupg agent documentation, it says: "On Windows support for the native ssh implementation must be enabled using the option enable-win32-openssh-support. For using gpg-agent as a replacement for PuTTY’s Pageant, the option enable-putty-support must be enabled."[^8]

So, we can add the options to `%USERPROFILE%\AppData\Roaming\gnupg\gpg-agent.conf`:

```
enable-ssh-support
enable-putty-support
enable-win32-openssh-support
```

The 'sockets' provided by gnupg use the "so-called Assuan protocol. This protocol is used for IPC between most newer GnuPG components."[^9] Interestingly, the created file looks quiet similar to the socket emulation of cygwin, by being a text file with a TCP port bound to localhost and a secret, but in a slightly different format. The tcp port number is followed by a newline and the secret:

```
49586
Ù3P§+¥ò9üqd)Î”H‘
```
> **Supported options**
> * Windows named pipe: `//./pipe/openssh-ssh-agent`
> * LibAssuan Socket:
    >   * `%USERPROFILE%\AppData\Local\gnupgp\S.gpg-agent.ssh`
>   * `%USERPROFILE%\AppData\Local\gnupgp\S.gpg-agent.extra`
>   * `%USERPROFILE%\AppData\Local\gnupgp\S.scdaemon`
>   * `%USERPROFILE%\AppData\Local\gnupgp\S.gpg-agent`
      {: .prompt-info }

> It is not necessary to store the GPG and SSH keys (encrypted!) on disk. It is also possible to store them securely on an HSM like the YubiKey[^27] and still use the gpg-agent (and scdaemon) to access the cryptographic functions.
>
{: .prompt-tip }

[^8]: https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html
[^9]: https://gnupg.org/software/libassuan/index.html
[^27]: https://developers.yubico.com/PGP/SSH_authentication/Windows.html

### WSL in general

The openssh-client and tools in WSL only support Unix-domain sockets for inter process communication with an [ssh-agent](https://man7.org/linux/man-pages/man1/ssh-agent.1.html).[^21] This path to the socket is best configured via the environment variable 'SSH_AUTH_SOCK'. This way it is used by [ssh](https://man7.org/linux/man-pages/man1/ssh.1.html) and [ssh-add](https://man7.org/linux/man-pages/man1/ssh-add.1.html). It is also possible to specify the path to the socket via '~/.ssh/config', which is then used by ssh only:[^20]

```
IdentityAgent
  Specifies the Unix-domain socket used to communicate with
  the authentication agent.

  This option overrides the SSH_AUTH_SOCK environment
  variable and can be used to select a specific agent.
  Setting the socket name to none disables the use of an
  authentication agent.  If the string "SSH_AUTH_SOCK" is
  specified, the location of the socket will be read from
  the SSH_AUTH_SOCK environment variable.  Otherwise if the
  specified value begins with a ‘$’ character, then it will
  be treated as an environment variable containing the
  location of the socket.
```

> **Supported options**
> * Unix-domain sockets (mostly only inside of WSL, see below for details)
    {: .prompt-info }


[^20]: https://man7.org/linux/man-pages/man5/ssh_config.5.html
[^21]: https://man7.org/linux/man-pages/man1/ssh.1.html

### WSL1 < Windows 1803

Before Windows 1803 and the support for Unix-domain sockets, there was no simple way to use ssh agents running on Windows by program running in WSL1. But it was and is possible to run Windows program from WSL and vice versa. It is also possible, and that is the clever idea, for these applications to interact through stdin/stdout. It is, e.g. possible to use grep and cut on WSL together with the Windows ipconfig.exe, by piping the output: `ipconfig.exe | grep IPv4 | cut -d: -f2`[^12]
The great tool [npiperelay](https://github.com/jstarks/npiperelay) uses this functionality, together with other tools, like [socat](https://linux.die.net/man/1/socat).

> npiperelay is a tool that allows you to access a Windows named pipe in a way that is more compatible with a variety of command-line tools. With it, you can use Windows named pipes from the Windows Subsystem for Linux (WSL).[^13]

> Socat is a command line based utility that establishes two bidirectional byte streams and transfers data between them.[^14]

In this scenario npiperelay acts as a bridge between Windows named pipes and stdin/stdout and socat acts as a bridge between stdin/stdout and Unix-domain sockets.

[^12]: https://learn.microsoft.com/en-us/windows/wsl/filesystems#interoperability-between-windows-and-linux-commands
[^13]: https://github.com/jstarks/npiperelay
[^14]: https://linux.die.net/man/1/socat

> **Supported options**
> * Windows named pipe with the help of npiperelay
> * Unix-domain sockets with the help of socat
> * Many other options with the help of socat and other command line tools
    {: .prompt-info }

### WSL1 >= Windows 1803

With Windows Insider build 17093, there came support for Unix-domain sockets in Windows.[^5] A little bit later a blog about using this to allow communications between Windows and WSL programs was published.[^15]

> **Supported options**
> * Unix-domain sockets (AF_UNIX)
> * the options from WSL1 < Windows 1803
    {: .prompt-info }

[^15]: https://devblogs.microsoft.com/commandline/windowswsl-interop-with-af_unix/

### WSL2 with gpg-agent

WSL1 uses a translation layer between Linux and Windows system calls. WSL2 uses a virtualized Linux kernel instead. Unfortunately Unix-domain sockets can't be shared between WSl2 and Windows because of that.[^16] The options, we already know from WSL1 before Windows 1803 are still working.
But among others[^17], there is a great feature in WSL2, that we can use to improve the interoperability of WSL2 and Windows and that is systemd[^18].

The post, that I mentioned in the introduction and that took me some time finding again, is the one of [demonbane](https://github.com/demonbane) regarding a script called ['gpg-agent-relay'](https://gist.github.com/andsens/2ebd7b46c9712ac205267136dc677ac1):

> I've been using this for a couple of years now with few enough headaches that I never tried to look for a better way. But with systemd support now in WSL I decided to see if I could simplify this approach and I found that I could do it all just using systemd and npiperelay. Turns out I could so I packaged it all up in [wsl-gpg-systemd](https://github.com/demonbane/wsl-gpg-systemd) if anyone is interested in giving it a shot. [^19]

Of course, I had used systemd for starting and stopping services, adding them to the system and getting information about it. But besides that I hadn't much thought about it. (That's not quite true, because I always wanted to look into what systemd has to do with name resolution, but haven't done so just yet.)
It turns out, systemd not only handles system services, but user services as well. And it can take care of socket creation and starting a program when someone accesses the socket. So, with this functionality, systemd will replace socat in the setup. A special requirement demonbane had, for his solution was, that he was using gnupg, which uses the libassuan sockets and that npiperelay was written originally for Windows named pipes. But there is a [fork of npiperelay by NZSmartie](https://github.com/NZSmartie/npiperelay), in which the author added this functionality.[^20]

Per socket, there are two systemd file required. One is for defining the socket and one for defining the service that provides the in-/ouput for the socket, that's (the Windows program) npiperelay. The system user file go to `~/.config/systemd/user`:

**gpg-agent-ssh.socket**
```ini
[Unit]
Description=GnuPG cryptographic agent (ssh-agent emulation)
Documentation=man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)

[Socket]
ListenStream=%t/gnupg/S.gpg-agent.ssh
SocketMode=0600
DirectoryMode=0700
Accept=true

[Install]
WantedBy=sockets.target
```

The `%t` in the path to the socket refers to the 'XDG_RUNTIME_DIR'.[^22] Get the path by running:

```shell
echo $XDG_RUNTIME_DIR
```

**gpg-agent-ssh@.service**
```ini
[Unit]
Description=gpg4win to WSL connector for SSH
Requires=gpg-agent-ssh.socket

[Service]
Type=simple
ExecStart=%h/.local/bin/npiperelay.exe -ei -s '//./pipe/openssh-ssh-agent'
StandardInput=socket

[Install]
WantedBy=default.target
```

> For each socket unit, a matching service unit must exist, describing the service to start on incoming traffic on the socket (see systemd.service(5) for more information about .service units). The name of the .service unit is by default the same as the name of the .socket unit, but can be altered with the Service= option described below. Depending on the setting of the Accept= option described below, this .service unit must either be named like the .socket unit, but with the suffix replaced, unless overridden with Service=; or it must be a template unit named the same way. Example: a socket file foo.socket needs a matching service foo.service if Accept=no is set. If Accept=yes is set, a service template foo@.service must exist from which services are instantiated for each incoming connection.[^21]

The [npiperelay.exe](https://github.com/NZSmartie/npiperelay/releases/download/v0.1/npiperelay.exe) from the releases page must be downloaded and saved somewhere in the Windows filesystem. This is a requirement of WSL. For convenience (and because it is the path in the service template) a symlink should be created in the `~/.local/bin` directory.
The systemd unit files can be activated by reloading the systemd manager configuration and enabling the socket unit with the '--now' option. The last command checks the status of the socket.

```shell
systemctl daemon-reload --user
systemctl enable --user --now gpg-agent-ssh.socket
systemctl status --user gpg-agent-ssh.socket
```

The best thing about this solution is that you hand over all the trouble about starting and stopping the programs to set up the socket and the communication to a software, which was written for this job.

[Below, you can find my preferred solution, where I modified this to work together with 1Password (or KeeAgent).](#my-preferred-solution)

[^16]: https://github.com/microsoft/WSL/issues/8321#issuecomment-1110263384
[^17]: https://learn.microsoft.com/en-us/windows/wsl/compare-versions
[^18]: https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/
[^19]: https://gist.github.com/andsens/2ebd7b46c9712ac205267136dc677ac1?permalink_comment_id=4684560#gistcomment-4684560
[^20]: https://github.com/NZSmartie/npiperelay
[^21]: https://www.freedesktop.org/software/systemd/man/latest/systemd.socket.html
[^22]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html#variables

### 1Password

[1Password](https://1password.com) supports managing SSH keys and can acts as a Win32 OpenSSH compatible ssh-agent.[^24] Instead of adding the keys on the startup to the agent, the keys are stored in the regular 1Password password safe and confirmation is required, when a programs requests access to it. If storing your passwords in the cloud (US or EU) is ok for you, then this is a really comfortable solution.
There is also a description on how to set up the WSL environment to use the Win32 OpenSSH ssh.exe instead of the Linux one.[^25] But I would prefer to use the "native" ones in WSL with the help of the systemd bridge solution.

> **Supported options**
> * Windows named pipe `\\.\pipe\openssh-ssh-agent`
    {: .prompt-info }

[^24]: https://developer.1password.com/docs/ssh/agent
[^25]: https://developer.1password.com/docs/ssh/integrations/wsl

### KeePass with KeeAgent

[KeeAgent](https://github.com/dlech/KeeAgent) is a plugin for [KeePass](https://keepass.info) that can act as an ssh-agent. Apart from WSL2, it supports all before mentioned connection methods. There are even 2 modes for MSYS and for Cygwin.[^26]

> **Supported options**
> * Windows named pipe `\\.\pipe\openssh-ssh-agent`
> * MSYS socket
> * Cygwin socket
> * PuTTY compatible WM_COPYDATA
    {: .prompt-info }

[^26]: https://keeagent.readthedocs.io/en/latest/usage/tips-and-tricks.html#using-keeagent-on-windows

## Other tools

The program [WinSSH-Pagent](https://github.com/ndbeals/winssh-pageant) claims to:
> Proxy Pageant requests to the Windows OpenSSH agent (from Microsoft), enabling applications that only support Pageant to use openssh.[^23]

It acts as a proxy, between the named pipe `\\.\pipe\openssh-ssh-agent` and the 'WM_COPYDATA' that PuTTY and WinSCP are using. It can be installed with winget:

```shell
winget install winssh-pageant
```

[^23]: https://github.com/ndbeals/winssh-pageant

## My preferred solution

I have tried many password managers over the years (KeePass1, KeePass2, EnPass, BitWarden, LastPass, 1Password) and I have to admit, that I finally chose 1Password because it has the best usability and functionality for my use case. It works on all of my devices and can not only manage my ssh keys, but also provides an ssh agent service, that is compatible with the open ssh client on all non-mobile platforms. As I mentioned above, this (sort of) works even in WSL2, since you can
call the Windows `ssh.exe` from within WSL2.

But as [I've learned](#wsl2-with-gpg-agent), I can use systemd and npiperelay to pipe between LibAssuan sockets or Windows named pipes on one side and unix domain sockets on the other side, so this should work with the 1Password ssh agent as well:

* Disable Windows Open SSH Agent Service: `Set-Service -Name ssh-agent -StartupType Disabled`
* Install 1Password and enable SSH Agent (Settings -> Developer)
* Download the patched [npiperelay](https://github.com/NZSmartie/npiperelay/releases/download/v0.1/npiperelay.exe) somewhere to the Windows filesystem (e.g. `%APPDATA%\niperelay`)
* config steps in WSL:

```bash
ln -s `wslpath "$(powershell.exe -Command '[System.Environment]::GetEnvironmentV
ariable("APPDATA")')"`/npiperelay/npiperelay.exe ~/.local/bin/npiperelay.exe`
cat <<EOF > ~/.config/systemd/user/named-pipe-ssh-agent.socket
[Unit]
Description=SSH Agent provided by Windows named pipe \\.\pipe\openssh-ssh-agent

[Socket]
ListenStream=%t/ssh/ssh-agent.sock
SocketMode=0600
DirectoryMode=0700
Accept=true

[Install]
WantedBy=sockets.target
EOF

cat <<EOF > ~/.config/systemd/user/named-pipe-ssh-agent@.service
[Unit]
Description=Proxy to Windows SSH Agent, which provides the standard named pipe (Win32-OpenSSH, 1Password, KeeAgent, etc.)
Requires=named-pipe-ssh-agent.socket

[Service]
Type=simple
ExecStart=%h/.local/bin/npiperelay.exe -ei -s '//./pipe/openssh-ssh-agent'
StandardInput=socket

[Install]
WantedBy=default.target
EOF

echo "export SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}ssh/ssh-agent.sock" >> ~/.profile
source ~/.profile
systemctl daemon-reload --user
systemctl enable --user --now named-pipe-ssh-agent.socket
systemctl status --user named-pipe-ssh-agent
ssh-add -l
```

As I mentioned above, this is not the best solution. A better approach would be to not use 1 Password and instead use [GPG4Win](#gpg4win) and a HSM, like the YubiKey[^27] for storing the key.

## References

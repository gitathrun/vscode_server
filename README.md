# Code-Server Docker Image #

## Author ##

Teng Fu

Email: teng.fu@teleware.com

## Base Image ##
This is the docker image for C++/Java development task, its baseImage is:

__FROM tftwdockerhub/vscode_server:latest__

## Additional installed packages ##

- Code-Server

- Anaconda

- JDK, JRE ver 8

- Virsual Stuido Code Extension:
	
	- Java Extension Package

	- Microsoft C++ Extension

	- Extension stored at: "/root/.vscode/extensions"


## Docker Registry Repo ##

-  tftwdockerhub/vscode_server:latest

## Usage ##

on virtual machines


```
sudo docker pull tftwdockerhub/vscode_server:latest
```

remember the target port is __8889__
```
sudo nvidia-docker run -it -p 8889:8888 -v \<project-dir-path\>:/app tftwdockerhub/vscode_server:latest
```

In local browser, remember the target port is __8889__ and the token string on CLI screen
```
http://\<vm-ipaddress-or-dns\>:8889
```
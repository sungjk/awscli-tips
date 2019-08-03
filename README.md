# awscli-tips

### Prerequisites
- Make sure you have **awscli** installed:

```
$ brew install awscli
```

Or visit https://github.com/aws/aws-cli for alternative ways.

- And you'll need **fzf**:

```
$ brew install fzf
```

Or visit https://github.com/junegunn/fzf for alternative ways.

- The scripts assumes that your SSH keys exist in `~/.ssh/[KeyName].pem`. Or you can paste path of SSH key.

- Mark the file as executable.

```
$ chmod +w YOUR_SCRIPT.sh
```

- Change the permissions of the .pem file so only the root user can read it.

```
$ chmod 400 YOUR_PEM.pem
```

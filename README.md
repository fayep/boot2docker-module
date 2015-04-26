boot2docker-module
==================

boot2docker-module is a Docker container which conveniently exports a tarball
of modules for use with boot2docker (your current version).

#### How to use

* copy kernel_config to module_config
* edit module_config to taste
* run:
    $ mkmod <tarballname>

### To do

It uses your current kernel version for pulling the kernel sources, but it
doesn't know how to manage the AUFS module branch/commit.

# Docker lightweight and minimalist image of Unbound

WARNING : this image is very experimental. Use at your own risk!

[![Version](https://images.microbadger.com/badges/version/jmdilly/unbound.svg)](https://github.com/jmdilly/docker-unbound/)
[![Docker Pulls](https://img.shields.io/docker/pulls/jmdilly/unbound.svg)](https://github.com/jmdilly/docker-unbound/)
[![Docker image size](https://images.microbadger.com/badges/image/jmdilly/unbound.svg)](https://github.com/jmdilly/docker-unbound/)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fjmdilly%2Fdocker-unbound.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fjmdilly%2Fdocker-unbound?ref=badge_shield)


## What is this ?

This image provide a minimal Docker image of Unbound without anything except Unbound binaries. 
There is no shell, no libs, nothing expect Linux skeleton directories and Unbound static binaries.

The minimalist Linux image is generated with [distroless Google's tools](https://github.com/GoogleContainerTools/distroless).

## Caveats

* Unbound-control default certificates are currently generated during Docker image building. It is strongly advised to generated your own certs on per container basis.



## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fjmdilly%2Fdocker-unbound.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fjmdilly%2Fdocker-unbound?ref=badge_large)
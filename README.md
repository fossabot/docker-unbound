# Docker most lightweight and minimal image of Unbound

WARNING : this image is very experimental. Use at your own risk!

## What is this ?

This image provide a minimal Docker image of Unbound without anything except Unbound binaries. 
There is no shell, no libs, nothing expect Linux skeleton directories and Unbound static binaries.

The minimalist Linux image is generated with [distroless Google's tools](https://github.com/GoogleContainerTools/distroless).

## Caveats

* Unbound-control default certificates are currently generated during Docker image building. It is strongly advised to generated your own certs on per container basis.


package(default_visibility = ["//visibility:public"])

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")
load("@io_bazel_rules_docker//container:container.bzl", "container_image")
load("@io_bazel_rules_docker//contrib:test.bzl", "container_test")
load("@io_bazel_rules_docker//contrib:passwd.bzl", "passwd_entry", "passwd_tar")
load("@io_bazel_rules_docker//contrib:group.bzl", "group_entry", "group_file")
load("@io_bazel_rules_go//go:def.bzl", "go_binary")

# Create /etc/passwd with the root user
passwd_entry(
    name = "root_user",
    gid = 0,
    home = "/home",
    info = "root",
    shell = "/sbin/nologin",
    uid = 0,
    username = "root",
)

passwd_entry(
    name = "unbound_user",
    gid = 101,
    home = "/var/lib/unbound",
    info = "unbound",
    shell = "/sbin/nologin",
    uid = 1001,
    username = "unbound",
)

passwd_tar(
    name = "passwd",
    entries = [
        ":root_user",
        ":unbound_user",
    ],
    passwd_file_pkg_dir = "etc",
)

# Create /etc/group with the root, tty, and staff groups
group_entry(
    name = "root_group",
    gid = 0,
    groupname = "root",
)

group_entry(
    name = "unbound_group",
    gid = 1001,
    groupname = "unbound",
)

group_file(
    name = "group",
    entries = [
        ":root_group",
        ":unbound_group",
    ],
)

pkg_tar(
    name = "group_tar",
    srcs = [":group"],
    mode = "0644",
    package_dir = "etc",
)

load("@package_bundle//file:packages.bzl", "packages")
load("//cacerts:cacerts.bzl", "cacerts")

cacerts(
    name = "cacerts",
    deb = packages["ca-certificates"],
)

# Create /tmp, too many things assume it exists.
# tmp.tar has a /tmp with the correct permissions 01777
# A tar is needed because at the moment there is no way to create a
# direcunboundy with specific permissions.

container_image(
    name = "unbound",
    debs = [
        packages["base-files"],
        packages["netbase"],
        packages["tzdata"],
    ],
    env = {
        "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        # allows openssl to find the certificates by default
        # TODO: We should run update-ca-certifaces, but that requires "openssl rehash"
        # which would probably need to be run inside the container
        "SSL_CERT_FILE": "/etc/ssl/certs/ca-certificates.crt",
    },
    tars = [
        ":passwd",
        ":group_tar",
        ":tmp.tar",
        ":nsswitch.tar",
        "@debian_stretch//file:os_release.tar",
        ":cacerts.tar",
    ],
)

# A debug image with busybox available.
container_image(
    name = "debug",
    base = ":unbound",
    directory = "/",
    entrypoint = ["/busybox/sh"],
    env = {"PATH": "$$PATH:/busybox"},
    tars = ["//experimental/busybox:busybox.tar"],
)

container_image(
    name = "check_certs_image",
    base = "//base:base",
    files = [":check_certs"],
    visibility = ["//visibility:private"],
)

container_test(
    name = "certs_test",
    configs = ["testdata/certs.yaml"],
    image = ":check_certs_image",
)

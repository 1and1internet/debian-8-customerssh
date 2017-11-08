# Customer SSH Environment

This image provides the environment in to which we place interactive sessions started by customers. The relevent volumes for the project are mounted in to well known common locations to make the container based hosting environment feel more like a familiar server environment.

Additionally this image is responsible for hosting the cron daemon, making everything available via SSH available to cron.

Despite the name this image does not expose SSH, instead it is expected that the platform handle the actual SSH connection and places the TTY in to the container.

## Usage

Please note this image is explictly intended to be run as a non-privileged user. Ensure you specify a user id (UID) other than zero when you run it. Running as root will not function.


```bash
UID=999

docker run -i -t -u ${UID}:0 1and1internet/ubuntu-16-customerssh bash
```

or

```bash
UID=999
NAME=sshcron

docker run --name=${NAME} -d -u ${UID}:0 1and1internet/ubuntu-16-customerssh /init/run_forever.sh
docker exec -i -t ${NAME} bash
```

## Building and testing

A simple Makefile is included for your convience. It assumes a linux environment with a docker socket available at `/var/run/docker.sock`

To build and test just run `make`.
You can also just `make pull`, `make build` and `make test` separately.

Please see the top of the Makefile for various variables which you may choose to customise. Variables may be passed as arguments, e.g. `make IMAGE_NAME=bob` or `make build BUILD_ARGS="--rm --no-cache"`

## Modifying the tests

The tests depend on shared testing code found in its own git repository called [drone-tests](https://github.com/1and1internet/drone-tests).

To use a different tests repository set the TESTS_REPO variable to the git URL for the alternative repository. e.g. `make TESTS_REPO=https://github.com/1and1internet/drone-tests.git`

To use a locally modified copy of the tests repository set the TESTS_LOCAL variable to the absolute path of where it is located. This variable will override the TESTS_REPO variable. e.g. `make TESTS_LOCAL=/tmp/github/1and1internet/drone-tests/`

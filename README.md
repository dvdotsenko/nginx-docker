# WHY

This project was born out of a need to add flexible env-var-based configurability to Nginx container.

Nginx folks famously deride people requesting support for env var resolution in config files
and often point to template-based config file rendering. An alternative approach mentioned elsewhere
is to use scripting (Lua) to inject env var values into config files.

Both approaches have drawbacks:

- Scripting-plugin-based approach either requires a special build of Nginx that includes that scripting plugin,
like in the case of Lua, or in case of built-in modules (nginScript) don't yet (as of August 2017) (fully?) support
ability to read env vars. These also suffer from Nginx's peculiarity / fickleness of where native variables
can be used. (`resolver` keyword value for example.) You also have to make sure to declare env vars explicitly you
want to be accessible to the scripting plugins by listing them in root config file, which is very annoying
and leads to silly errors when some env var you want to use is forgotten and not explicitly whitelisted for use.

- Template rendering means you have to have a meaningful runtime to run it on and fairly involved rendering code.
While many people would be satisfied with piping templates through something like Ansible and baking rendered
configs into the image, the desired behavior is to have templates render inside of the container at run-time
per env vars injected into the container. This means you need to bake template rendering system into the container.
With desire to minimise the size of containers people attempt to use standard env-resolving *nix tools like
`envsubst`, but get burned by generality of tools like that because they resolve not only `${\w+}`, `$(\w+)` 
env var notations, but also `$\w+` notation, which is used for Nginx native variables, thus destroying native
Nginx variables in config files.


After trying scripting-plugin-based approaches (nginScript and Lua), `envsubst` approach, we settled on realization
that template-based one is probably proper, but with extremely tight formatting contract on env string markup.

While inspecting official Nginx image, it was discovered that it contains Perl runtime, so a basic Perl-based
config file template rendering system that does not burden the size of container appeared possible.

# WHAT

This project allows (automates, eases) you to take base Nginx docker images (in a version-agnostic way) and overlay
on top of it the scripts responsible for run-time rendering of image-baked config template files into nginx configs.

Summary of additions:

- Perl script (some 40 lines of code) that given list of directories to look at, finds template files and renders them
to config files.
- `docker_entrypoint.sh` that runs the above Perl script before running the commands passed to it.
- Image's entry point is set to run `docker_entrypoint.sh` and command is set to `nginx (with assorted args)`

# HOW

## Build

### Docker version requirement

You need a recent (likely v17.05+) version of Docker, as Dockerfile is utilizing 
`ARG` command that mutates the `FROM`'s version, which became supported in late Spring
of 2017. If you don't want to upgrade your Docker package, just remove the first
`ARG` from the `Dockerfile` and fix the version on `FROM` line.

### Build command

Build is partially automated by `Makefile` where image name and version (and source image version)
is set using variables. All variables set in `Makefile` can be overridden on command line.

`make image`  Will build based on `nginx:latest` image and will name the image per vendor and naming
variables in Makefile, while mirroring that image's version to `latest`

`make image NGINX_VERSION=1.12.1` Will build based on `nginx:1.12.1` image and will name the image per vendor
and naming variables in Makefile, while mirroring that image's version to `1.12.1`

`make image NGINX_VERSION=1.11.2 VENDOR_NAME=mycompany IMAGE_NAME=uber-nginx` Will build based on 
`nginx:1.11.2` image and will name the image `mycompany/uber-nginx`, while mirroring that image's version to `1.11.2`

Publishing to registry or prefixing images with URL of the registry is outside of scope for the build.

See `Makefile` for details on further configurability.

## Use

*At run-time* all files found in resulting image's `/etc/nginx/` and `/etc/nginx/conf.d` folders and
match the file naming convention of `*.nginx.conf.template` will be processed through template-rendering
script and turned into `*.nginx.conf` (same name minus the `.template` suffix) files right next to the
original file.

(Note on file naming convention choice: My IDE has Nginx config file specific highlighter support, 
which by default tracked `*.nginx` extension, while a chunk of native Nginx config files end just 
in `*.conf` Luckily that was easy to extend to include `*.nginx.conf` and `*.nginx.conf.template` 
The last one is long, but explicit and logical jump from `*.nginx.conf`)

The template renderer will be looking for occurances of `${SOME_VAR}` where `SOME_VAR` is the name
of some environment variable and replacing this markup with the value of the environment variable.
Note that curlies are required as native Nginx config files utilize curly-less dollar-prefixed variables
and we don't want to replace those with env vars by accident.

See contents of `conf.d/example.nginx.conf.template` file for example markup. That file is 
(by default) baked into the resulting image so you can compare source and result in that
folder after you run (`make run` followed by `make shell`) the image.

What this means to you is that you can take image that is built by this project and use it as
base for you custom image where you add config file templates specific to your application to
`/etc/nginx/` and `/etc/nginx/conf.d/` folders and as long as these files have above-discussed 
name signature and above-mentioned env var markup, they will be rendered into desired config files.

See `run` task (`-e` arg) in `Makefile` for an example of injecting environment variables into 
containers at run-time.

# License

MIT. See `LICENSE` file in the root folder of this repo.

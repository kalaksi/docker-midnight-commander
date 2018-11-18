
### Repositories
- [Docker Hub repository](https://registry.hub.docker.com/u/kalaksi/midnight-commander/)
- [GitHub repository](https://github.com/kalaksi/docker-midnight-commander)

### What is this container for?
This container runs SSH server and is configured to run Midnight Commander directly after login.  
So essentially this container is a remote accessible file manager.  

### Why use this container?
**Simply put, this container has been written with simplicity and security in mind.**

Surprisingly, _many_ community containers run unnecessarily with root privileges by default and don't provide help for dropping unneeded CAPabilities either.
On top of that, overly complex shell scripts, monolithic designs and unofficial base images make it harder to verify the source among other issues.

To remedy the situation, these images have been written with security and simplicity in mind. See [Design Goals](#design-goals) further down.

### Running this container
See the example ```docker-compose.yml``` in the source repository.  
The username for connecting the container is ```mc```.

#### Supported tags
See the ```Tags``` tab on Docker Hub for specifics. Basically you have:
- The default ```latest``` tag that always has the latest changes.
- Minor versioned tags (follow Semantic Versioning), e.g. ```1.1``` which would follow branch ```1.1.x``` on GitHub.

#### Configuration
See ```Dockerfile``` and ```docker-compose.yml``` (<https://github.com/kalaksi/docker-midnight-commander>) for usable environment variables. Variables that are left empty will use default values.  
If you need even more customization, modify the created ```sshd_config```-file located in the ```midnight-commander```-volume. It's possible to use the configuration file to pass arguments to Midnight Commander.  
You can also bind-mount configuration files for Midnight Commander under ```/home/mc/.config/mc```.  

### Development
#### Design Goals
- Never run as root unless necessary.
- No static default passwords. That would make the container insecure by default.
- Use only official base images.
- Provide an example ```docker-compose.yml``` that also shows what CAPabilities can be dropped.
- Offer versioned tags for stability.
- Try to keep everything in the Dockerfile (if reasonable, considering line count and readability).
- Don't restrict configuration possibilities: provide a way to use native config files for the containerized application.
- Handle signals properly.

#### Contributing
See the repository on <https://github.com/kalaksi/docker-midnight-commander>.
All kinds of contributions are welcome!

### License
View [license information](https://github.com/kalaksi/docker-midnight-commander/blob/master/LICENSE) for the software contained in this image.  
As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).  
  
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

# Recovery script for my DevOps virtual machine

This script is made to automate the installation of docker and docker-compose on my blank ubuntu virtual machine for my DevOps university course.
After installing docker it spins up a detatched container with gitlabs.

## Running the script
Assuming both scripts are in the same folder allow them execute rights, and run (here in verbose mode):
```bash
chmod +x functionsh.sh recover_vm.sh
sudo ./recover_vm.sh -v
```

### Todo
The script contains a mix of $(whoami) and $USER, and a lot of paths that may be made into separate variables in the future.
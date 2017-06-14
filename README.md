# rCMTool
rudimentary configuration management tool

This is a very rudimentary configuration management tool. This tool can be used to configure servers for the production service of a simple PHP application. This tool is modeled after industry tools such as Puppet, Chef, Fabric and Ansible.

This is inspired from the this github blog(Rick-Houser/Server_Config) ,i wanted to re-write this differently and use perl and shell for more manageble and configurable.


# How to Configure:
To install a package, add the package name to the "install.lst" inside the "packages" directory. Each package name should be on it's own line.
For removing an installed package, follow you will do the same as you did to install a package. This time you will add the package names to the "uninstall.lst" file inside the "packages" directory.

you will need to add key value pairs into the "config.properties" file. Key value pairs must be separated by "=" 

Php application content can be included in “files” folder with index.php file

To install any dependency scripts before executing steps described above update the “dependency.sh” script in “dependencies” folder .

Then invoke the cmTool.pl file from “bin” folder to apply the configuration changes written above.

# Usage
Transfer tarfile to the destination server using the following syntax or use one of the scp tools to transfer the file .
	scp –r  rCMTool.tar user@server_name:/temp/
  
  Once the tar file is transferred and Untar the file for configuration and execution.
	tar –xf <temp>/rCMTool.tar
Make the scripts executable
	Chmod 755  <temp>/rCMTool/bin/

# Install dependency
	Update the dependency script “dependency.sh” in “depdendecies” folder or use the bootstrap.sh script in “bin” folder for manually executing.
  
# Run the script rCMTooL:
	cd <temp>/rCMTool/bin
	Run  ./cmtool.pl 

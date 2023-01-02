# docker-blender
Dockerfile for building blender.

References:
* [Building Blender](https://wiki.blender.org/wiki/Building_Blender)
* [Building Blender as a Python Module](https://wiki.blender.org/wiki/Building_Blender/Other/BlenderAsPyModule)


## Windows

### Build Image
* By default, the image is for building Blender 3.4.0 (with Blender 3.4 release branch).
* See [Diagnosing install failures](https://learn.microsoft.com/en-us/visualstudio/install/advanced-build-tools-container?view=vs-2019#diagnosing-install-failures)
if error occurred while installing Visual Studio Build Tools.
* Took more than 1 hour (me 1h44m) to build this image due to the size of the Blender libraries (16GB+).
* Final image size is 22.55GB.
```shell
docker build --memory 2GB -t blender-windows:3.4 -f "blender-windows.Dockerfile" .
```

### Run Container
* The container should be ready to build Blender.
* Default shell is CMD.
* At some point, the compiler consumes a lot of memory. (25.1GB in my build, is this normal?)
* Also, do give as many CPU as possible to speed things up.
* You may get `fatal error C1060: compiler is out of heap space` if container memory is not enough.
```shell
docker run --memory 30GB --cpus 24 --name blender-build -it blender-windows:3.4
```

### Test Container
To check memory size, run this powershell command
```powershell
systeminfo | select-string 'Total Physical Memory'
```
To check CPU process count, run this powershell command
```powershell
Get-WmiObject -class Win32_processor | Format-Table Name,NumberOfCores,NumberOfLogicalProcessors
```
And yes, the default shell is CMD, so you might want to call `powershell` to run them and then `exit` back to CMD.

### Text Editor
Thanks to Git, we can use `nano` when needed.

### Build Blender
For example, building Blender as Python module
```shell
make.bat 2019b bpy
```
Note that `2019b` means Visual Studio **2019** **B**uild Tools. We have to provide that or the script won't run.

### Harvest
After build complete, stop the container and copy files out.
```shell
docker cp blender-build:{path-to-build-dir} {dst}
```
For example
```shell
docker cp blender-build:C:/blender-build/build_windows_Bpy_x64_vc16_Release/bin/Release/bpy bpy
```

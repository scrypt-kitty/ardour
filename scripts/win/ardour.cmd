@echo off
rem Relocatable launcher for the native Windows (MSYS2/UCRT64) Ardour bundle.
setlocal
set "R=%~dp0"
set "ARDOUR_DATA_PATH=%R%share\ardour9"
set "ARDOUR_CONFIG_PATH=%R%etc\ardour9"
set "ARDOUR_DLL_PATH=%R%lib\ardour9"
set "GTK_PATH=%R%etc\ardour9;%R%lib\ardour9"
set "GDK_PIXBUF_MODULEDIR=%R%lib\gdk-pixbuf-2.0\2.10.0\loaders"
set "GDK_PIXBUF_MODULE_FILE=%R%lib\gdk-pixbuf-2.0\2.10.0\loaders.cache"
set "PATH=%R%lib\ardour9;%PATH%"
"%R%lib\ardour9\ardour-9.10.23.exe" %*

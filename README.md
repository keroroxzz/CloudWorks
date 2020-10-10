GTA SA CloudWorks Alpha (3.6.5)
=================================

by Brian Tu (keroroxzz)

Contact: https://github.com/keroroxzz
Or: https://fumincha.wordpress.com/cloudworks/

2020/09/01

[![Video](https://img.youtube.com/vi/AjRBydjolfM/0.jpg)](https://www.youtube.com/watch?v=AjRBydjolfM)

---------------------------------

This is the alpha version of the CloudWorks.
The atmosphere and weather still need to be improved.

Requirement
---------------------------------

GTX 1660s or better is needed to run this stuff at 1080p.

License
---------------------------------
Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
Remember to include these information if you'd like to re-distribute stuff with this shader.

INSTALL
---------------------------------

1. install enb for GTA SA from http://enbdev.com/mod_gtasa_v0430.htm.
2. unpack d3d9.dll, enblocal.ini, enbseries.ini, and enbseries folder in the WrapperVersion.
3. put the files of CloudWorks (png, fx, and ini) inside enbseries folder.
4. open the game and wait for compiling.
5. you get a sky with clouds!

note: you need to tweak the UseOriginalPostProcessing and UseOriginalColorCorrection to get a better look.

NOTICE
---------------------------------

Method 1 (need coding)
If you just cover up the original enblighting.fx file, the effect, such as shadow and lighting inside the file, will disappear, too.
So you have to mix the two shaders by yourself.

Method 2 (no need for coding)
Make the shader works under enbeffectprepass by renaming the files and the tag inside the ini.
But the particle fusion will fail if using this method.

local kernel = dofile("/boot/kernel.lua")

kernel.init()
kernel.start()
shell.run("launch")
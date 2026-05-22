settings.load(".settings")
shell.setPath("/bin:/bin/system:/bin/dev:/usr/bin:/rom/programs")
-- Setup aliases
shell.setAlias("ls", "list")
shell.setAlias("dir", "list")
shell.setAlias("cp", "copy")
shell.setAlias("mv", "move")
shell.setAlias("rm", "delete")
shell.setAlias("clr", "clear")
shell.setAlias("rs", "redstone")
shell.setAlias("sh", "shell")
if term.isColor() then
    shell.setAlias("background", "bg")
    shell.setAlias("foreground", "fg")
end


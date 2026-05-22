-- KOS ADDON LOADER (ROM-safe)

print("[KOS] addon boot")

local ok, kos = pcall(dofile, "/kos/kos.lua")
if ok and kos and kos.init then
    kos.init()
end

if shell then
    local current = shell.path() or ""
    shell.setPath(current .. ":/bin")
end

if shell then
    shell.setAlias("ll", "list")
    shell.setAlias("cls", "clear")
end

print("[KOS] ready")
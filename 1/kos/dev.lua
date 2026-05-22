local dev = {}

dev.map = {
    sda1 = "disk",
    nvme0n1p1 = "disk"
}

function dev.resolve(name)
    return dev.map[name]
end

return dev
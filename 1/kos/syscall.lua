kos.syscall = kos.syscall or {}

function kos.syscall.reboot()
    os.reboot()
end

function kos.syscall.shutdown()
    os.shutdown()
end

return kos.syscall
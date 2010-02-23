
GetFileAttributes: func (s: String) -> Int { 42 }

main: func {
    path := "/etc/hosts"
    0xFFFFFFFF != GetFileAttributes(path) ? "Hi" println() : "Hoy" println()
}

source $"($nu.default-config-dir)/k8s.nu"

alias code = codium

def --env mkcd [
    dirname: string # Directory to create and enter
] {
    mkdir $dirname
    cd $dirname
}
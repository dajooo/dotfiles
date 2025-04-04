source $"($nu.default-config-dir)/k8s.nu"

alias code = codium

def --env mkcd [dirname] { 
    mkdir $dirname
    cd $dirname
}
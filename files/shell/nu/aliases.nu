source $"($nu.default-config-dir)/k8s.nu"

alias code = codium

def mkcd [dirname] { mkdir $dirname; cd $dirname }
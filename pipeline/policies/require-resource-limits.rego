package kubernetes.admission

# Every container must declare memory and CPU limits.
# Prevents a single misbehaving pod from starving the node (relevant to the
# Cloudflare-style CPU exhaustion case study).

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Memory limit required: %v", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("CPU limit required: %v", [container.name])
}
